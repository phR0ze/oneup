use sqlx::SqlitePool;
use axum::http::StatusCode;
use crate::{ errors, model };

/// Insert a new Category into the database
/// 
/// - error on empty name
/// - error on duplicate name
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***name*** - name of the category to insert
/// 
/// #### Returns
/// - ***id*** - id of the category
pub async fn insert(db: &SqlitePool, name: &str) -> errors::Result<i64>
{
  validate_name_given(&name)?;

  // Create new Category in database
  let result = sqlx::query(r#"INSERT INTO category (name) VALUES (?)"#)
    .bind(name).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {
      if errors::Error::is_sqlx_unique_violation(&e) {
        let msg = format!("Category '{name}' already exists");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      }
      let msg = format!("Error inserting category '{name}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get a Category by ID from the database
/// 
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***id*** - id of the category to fetch
/// 
/// #### Returns
/// - ***category*** - the category entry
pub async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::Category>
{
  let result = sqlx::query_as::<_, model::Category>(r#"SELECT * FROM category WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(category) => Ok(category),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("Category with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching category with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all categories from the database
/// 
/// - orders the categories by name ignoring case
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// 
/// #### Returns
/// - ***categories*** - the categories entries
pub async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<model::Category>>
{
  let result = sqlx::query_as::<_, model::Category>(r#"SELECT * FROM category ORDER BY LOWER(name)"#).fetch_all(db).await;
  match result {
    Ok(category) => Ok(category),
    Err(e) => {
      let msg = format!("Error fetching categories");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Update a Category in the database
/// 
/// - only the name field can be updated
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***id*** - id of the category to update
/// - ***name*** - name of the category to update
pub async fn update_by_id(db: &SqlitePool, id: i64, name: &str) -> errors::Result<()>
{
  let category = fetch_by_id(db, id).await?;

  // Update category name if changed
  if category.name != name {
    validate_name_given(&name)?;

    // Update category in database
    let result = sqlx::query(r#"UPDATE category SET name = ? WHERE id = ?"#)
      .bind(&name).bind(&id).execute(db).await;
    if let Err(e) = result {
      let msg = format!("Error updating category with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
  Ok(())
}

/// Delete a Category in the database
/// 
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***id*** - id of the category to delete
pub async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()>
{
  // Don't allow deletion of the Unspecified category
  if id == 1 {
    let msg = format!("Cannot delete 'Unspecified' category");
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
  }

  let result = sqlx::query(r#"DELETE from category WHERE id = ?"#).bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting category with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

// Helper for name not given error
fn validate_name_given(name: &str) -> errors::Result<()>
{
  if name.is_empty() {
    let msg = "Category name value is required";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests
{
  use super::*;
  use crate::state;

  #[tokio::test]
  async fn test_delete_success()
  {
    let state = state::test().await;
    let category1 = "category1";
    let id = insert(state.db(), category1).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_delete_failure_on_default()
  {
    let state = state::test().await;

    let err = delete_by_id(state.db(), 1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Cannot delete 'Unspecified' category"));

    let category = fetch_by_id(state.db(), 1).await.unwrap();
    assert_eq!(category.id, 1);
    assert_eq!(category.name, "Unspecified");
  }

  #[tokio::test]
  async fn test_update_success()
  {
    let state = state::test().await;
    let category1 = "category1";
    let id = insert(state.db(), category1).await.unwrap();

    update_by_id(state.db(), id, "foobar").await.unwrap();

    let category = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(category.id, 2);
    assert_eq!(category.name, "foobar");
  }

  #[tokio::test]
  async fn test_update_failure_no_name()
  {
    let state = state::test().await;
    let category1 = "category1";
    let id = insert(state.db(), category1).await.unwrap();

    let err = update_by_id(state.db(), id, "").await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Category name value is required"));
  }

  #[tokio::test]
  async fn test_update_failure_not_found()
  {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, "foobar").await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Category with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success()
  {
    let state = state::test().await;
    let category1 = "category1";

    // Insert a new Category
    let id = insert(state.db(), category1).await.unwrap();
    assert_eq!(id, 2);

    let category = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(category.id, 2);
    assert_eq!(category.name, category1);
    assert!(category.created_at <= chrono::Local::now());
    assert!(category.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_all_success()
  {
    let state = state::test().await;
    let category1 = "category1";
    let category2 = "category2";

    insert(state.db(), category2).await.unwrap();
    insert(state.db(), category1).await.unwrap();
    let categories = fetch_all(state.db()).await.unwrap();
    assert_eq!(categories.len(), 3);

    assert_eq!(categories[0].id, 3);
    assert_eq!(categories[0].name, category1);
    assert!(categories[0].created_at <= chrono::Local::now());
    assert!(categories[0].updated_at <= chrono::Local::now());

    assert_eq!(categories[1].id, 2);
    assert_eq!(categories[1].name, category2);
    assert!(categories[1].created_at <= chrono::Local::now());
    assert!(categories[1].updated_at <= chrono::Local::now());

    assert_eq!(categories[2].id, 1);
    assert_eq!(categories[2].name, "Unspecified");
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found()
  {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Category with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_duplicate()
  {
    let state = state::test().await;
    let category1 = "category1";

    insert(state.db(), category1).await.unwrap();
    let err = insert(state.db(), category1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::CONFLICT);
    assert_eq!(err.msg, format!("Category '{category1}' already exists"));
  }

  #[tokio::test]
  async fn test_insert_failure_empty_name()
  {
    let state = state::test().await;

    let err = insert(state.db(), "").await.unwrap_err();
    let err = err.as_http().unwrap();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, "Category name value is required");
  }
}