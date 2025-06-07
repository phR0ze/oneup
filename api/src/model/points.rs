use axum::http::StatusCode;
use serde::{ Deserialize, Serialize};
use sqlx::SqlitePool;
use crate::errors;
use super::Filter;

// DTOs
// *************************************************************************************************

/// Used during posts to create a new points entry
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreatePoints {
    pub(crate) value: i64,
    pub(crate) user_id: i64,
    pub(crate) category_id: i64,
}

/// Used during updates to change a points entry
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UpdatePoints {
    pub(crate) id: i64,
    pub(crate) value: i64,
    pub(crate) category_id: i64,
}

/// Full points object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Points {
    pub(crate) id: i64,
    pub(crate) value: i64,
    pub(crate) user_id: i64,
    pub(crate) category_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}

// Business Logic
// *************************************************************************************************

/// Insert a new points entry into the database
/// - error on user not found
/// - error on category not found
/// - error on other SQL errors
/// - ***value*** points value
/// - ***user_id*** owner of the points
/// - ***category_id*** category of the points
pub(crate) async fn insert(db: &SqlitePool, value: i64, user_id: i64, category_id: i64)
  -> errors::Result<i64>
{
  super::user::fetch_by_id(db, user_id).await?;
  super::category::fetch_by_id(db, category_id).await?;

  let result = sqlx::query(r#"INSERT INTO point (value, user_id, category_id) VALUES (?, ?, ?)"#)
    .bind(value).bind(user_id).bind(category_id).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {
      let msg = format!("Error inserting points '{value}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get a points entry by ID from the database
/// - error on not found
/// - error on other SQL errors
pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<Points> {
  let result = sqlx::query_as::<_, Points>(r#"SELECT * FROM point WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(points) => Ok(points),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("Points with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching points with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all points for the given user and or category
/// - error on user not found if provided
/// - error on category not found if provided
/// - error on other SQL errors
/// - ***filter*** filter to apply
pub(crate) async fn fetch_by_filter(db: &SqlitePool, filter: Filter) -> errors::Result<Vec<Points>> {

  // Error out if no filter values are provided
  if filter.user_id.is_none() && filter.category_id.is_none() {
    let msg = format!("Invalid filter provided for points.");
    log::error!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
  }

  // Construct where clause and ensure the user and category exist if provided 
  let mut where_clause = "WHERE ".to_string();
  if let Some(user_id) = filter.user_id {
    super::user::fetch_by_id(db, user_id).await?;
    where_clause.push_str(&format!("user_id = ?"));
  }
  if let Some(category_id) = filter.category_id {
    super::category::fetch_by_id(db, category_id).await?;
    if filter.user_id.is_some() {
      where_clause.push_str(" AND ");
    }
    where_clause.push_str(&format!("category_id = ?"));
  }

  // Build up the query
  let query_str = format!("SELECT * FROM point {where_clause}");
  let mut query = sqlx::query_as::<_, Points>(&query_str);
  if let Some(user_id) = filter.user_id {
    query = query.bind(user_id);
  }
  if let Some(category_id) = filter.category_id {
    query = query.bind(category_id);
  }

  // Execute the query and check for errors
  let result = query.fetch_all(db).await;
  match result {
    Ok(points) => Ok(points),
    Err(e) => {
      let msg = format!("Error fetching points");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all points
/// - error on other SQL errors
/// - ***user_id*** owner of the points
pub(crate) async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<Points>> {
  let result = sqlx::query_as::<_, Points>(r#"SELECT * FROM point"#)
    .fetch_all(db).await;
  match result {
    Ok(points) => Ok(points),
    Err(e) => {
      let msg = format!("Error fetching points");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Update a points in the database
/// 
/// - only the value field can be updated
/// - error on not found
/// - error on other SQL errors
pub(crate) async fn update_by_id(db: &SqlitePool, id: i64, value: i64) -> errors::Result<()> {
  let points = fetch_by_id(db, id).await?;

  // Update points value if changed
  if points.value != value {
    let result = sqlx::query(r#"UPDATE point SET value = ? WHERE id = ?"#)
      .bind(&value).bind(&id).execute(db).await;
    if let Err(e) = result {
      let msg = format!("Error updating points with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
  Ok(())
}

/// Delete a points in the database
/// 
/// - error on other SQL errors
pub(crate) async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()> {
  let result = sqlx::query(r#"DELETE from point WHERE id = ?"#).bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting points with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::{model, state};
  use axum::http::StatusCode;

  #[tokio::test]
  async fn test_delete_success() {
    let state = state::test().await;
    let points1 = 10;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let category1 = "category1";
    let category_id = model::category::insert(state.db(), category1).await.unwrap();
    let id = insert(state.db(), points1, user_id, category_id).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_success() {
    let state = state::test().await;
    let points1 = 10;
    let points2 = 20;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let category1 = "category1";
    let category_id = model::category::insert(state.db(), category1).await.unwrap();
    let id = insert(state.db(), points1, user_id, category_id).await.unwrap();

    update_by_id(state.db(), id, points2).await.unwrap();

    let points = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(points.id, 1);
    assert_eq!(points.value, points2);
    assert_eq!(points.user_id, user_id);
  }

  #[tokio::test]
  async fn test_update_failure_not_found() {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, 10).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Points with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_fetch_by_filter_by_user_success() {
    let state = state::test().await;
    let points1 = 10;
    let points2 = 20;
    let user1 = "user1";
    let user_id_1 = model::user::insert(state.db(), user1).await.unwrap();
    let user2 = "user2";
    let user_id_2 = model::user::insert(state.db(), user2).await.unwrap();
    let category1 = "category1";
    let category_id = model::category::insert(state.db(), category1).await.unwrap();

    insert(state.db(), points1, user_id_1, category_id).await.unwrap();
    insert(state.db(), points2, user_id_2, category_id).await.unwrap();
    let points = fetch_by_filter(state.db(), Filter::by_user(user_id_1)).await.unwrap();
    assert_eq!(points.len(), 1);
    assert_eq!(points[0].value, points1);
    assert_eq!(points[0].id, 1);
    assert_eq!(points[0].user_id, user_id_1);
    assert_eq!(points[0].category_id, category_id);
    assert!(points[0].created_at <= chrono::Local::now());
    assert!(points[0].updated_at <= chrono::Local::now());
    assert_eq!(points[0].created_at, points[0].updated_at);
  }

  #[tokio::test]
  async fn test_fetch_by_filter_by_category_success() {
    let state = state::test().await;
    let points1 = 10;
    let points2 = 20;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let category1 = "category1";
    let category_id_1 = model::category::insert(state.db(), category1).await.unwrap();
    let category2 = "category2";
    let category_id_2 = model::category::insert(state.db(), category2).await.unwrap();

    insert(state.db(), points1, user_id, category_id_1).await.unwrap();
    insert(state.db(), points2, user_id, category_id_2).await.unwrap();
    let points = fetch_by_filter(state.db(), Filter::by_category(category_id_1)).await.unwrap();
    assert_eq!(points.len(), 1);
    assert_eq!(points[0].value, points1);
    assert_eq!(points[0].id, 1);
    assert_eq!(points[0].user_id, user_id);
    assert_eq!(points[0].category_id, category_id_1);
    assert!(points[0].created_at <= chrono::Local::now());
    assert!(points[0].updated_at <= chrono::Local::now());
    assert_eq!(points[0].created_at, points[0].updated_at);
  }

  #[tokio::test]
  async fn test_fetch_by_filter_by_user_and_category_success() {
    let state = state::test().await;
    let points1 = 10;
    let points2 = 20;
    let user1 = "user1";
    let user_id_1 = model::user::insert(state.db(), user1).await.unwrap();
    let user2 = "user2";
    let user_id_2 = model::user::insert(state.db(), user2).await.unwrap();
    let category1 = "category1";
    let category_id = model::category::insert(state.db(), category1).await.unwrap();
    let category2 = "category2";
    let category_id_2 = model::category::insert(state.db(), category2).await.unwrap();

    insert(state.db(), points1, user_id_1, category_id).await.unwrap();
    insert(state.db(), points2, user_id_2, category_id).await.unwrap();
    let points = fetch_by_filter(state.db(), Filter::by_user_and_category(user_id_1, category_id_2)).await.unwrap();
    assert_eq!(points.len(), 0);
  }

  #[tokio::test]
  async fn test_fetch_by_user_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_filter(state.db(), Filter::by_user(-1)).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_fetch_by_category_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_filter(state.db(), Filter::by_category(-1)).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Category with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Points with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_category_not_found() {
    let state = state::test().await;
    let points1 = 10;
    let category_id = 2; // 1 always exists i.e. Default

    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();

    let err = insert(state.db(), points1, user_id, category_id).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Category with id '2' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_user_not_found() {
    let state = state::test().await;
    let points1 = 10;
    let user_id = 1;

    let category1 = "category1";
    let category_id = model::category::insert(state.db(), category1).await.unwrap();

    let err = insert(state.db(), points1, user_id, category_id).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success() {
    let state = state::test().await;
    let points1 = 10;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let category1 = "category1";
    let category_id = model::category::insert(state.db(), category1).await.unwrap();

    // Insert a new points
    let id = insert(state.db(), points1, user_id, category_id).await.unwrap();
    assert_eq!(id, 1);
    let points = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(points.id, 1);
    assert_eq!(points.value, points1);
    assert_eq!(points.user_id, user_id);
    assert_eq!(points.category_id, category_id);
    assert!(points.created_at <= chrono::Local::now());
    assert!(points.updated_at <= chrono::Local::now());
    assert_eq!(points.created_at, points.updated_at);
  }
}