use serde::{ Deserialize, Serialize};
use sqlx::SqlitePool;
use axum::http::StatusCode;

use crate::errors;

// DTOs
// *************************************************************************************************

/// Used during posts to create a new Action
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreateAction {
    pub(crate) name: String,
}

/// Used during updates to change a Action
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UpdateAction {
    pub(crate) id: i64,
    pub(crate) name: String,
}

/// Full Action object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Action {
    pub(crate) id: i64,
    pub(crate) name: String,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}

// Business Logic
// *************************************************************************************************

/// Insert a new Action into the database
/// 
/// - error on empty name
/// - error on duplicate name
/// - error on other SQL errors
pub(crate) async fn insert(db: &SqlitePool, name: &str) -> errors::Result<i64> {
  validate_name_given(&name)?;

  // Create new Action in database
  let result = sqlx::query(r#"INSERT INTO action (name) VALUES (?)"#)
    .bind(name).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {
      if errors::Error::is_sqlx_unique_violation(&e) {
        let msg = format!("Action '{name}' already exists");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      }
      let msg = format!("Error inserting action '{name}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get a Action by ID from the database
/// 
/// - error on not found
/// - error on other SQL errors
pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<Action> {
  let result = sqlx::query_as::<_, Action>(r#"SELECT * FROM action WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(action) => Ok(action),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("Action with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching action with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all actions from the database
/// 
/// - orders the actions by name
/// - error on other SQL errors
pub(crate) async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<Action>> {
  let result = sqlx::query_as::<_, Action>(r#"SELECT * FROM action ORDER BY name"#).fetch_all(db).await;
  match result {
    Ok(action) => Ok(action),
    Err(e) => {
      let msg = format!("Error fetching actions");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Update a Action in the database
/// 
/// - only the name field can be updated
/// - error on not found
/// - error on other SQL errors
pub(crate) async fn update_by_id(db: &SqlitePool, id: i64, name: &str) -> errors::Result<()> {
  let action = fetch_by_id(db, id).await?;

  // Update action name if changed
  if action.name != name {
    validate_name_given(&name)?;

    // Update action in database
    let result = sqlx::query(r#"UPDATE action SET name = ? WHERE id = ?"#)
      .bind(&name).bind(&id).execute(db).await;
    if let Err(e) = result {
      let msg = format!("Error updating action with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
  Ok(())
}

/// Delete a Action in the database
/// 
/// - error on other SQL errors
pub(crate) async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()> {

  // Don't allow deletion of the default action
  if id == 1 {
    let msg = format!("Cannot delete 'Default' action");
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
  }

  let result = sqlx::query(r#"DELETE from action WHERE id = ?"#).bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting action with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

// Helper for name not given error
fn validate_name_given(name: &str) -> errors::Result<()> {
  if name.is_empty() {
    let msg = "Action name value is required";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::state;

  #[tokio::test]
  async fn test_delete_success() {
    let state = state::test().await;
    let action1 = "action1";
    let id = insert(state.db(), action1).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_delete_failure_on_default() {
    let state = state::test().await;

    let err = delete_by_id(state.db(), 1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Cannot delete 'Default' action"));

    let action = fetch_by_id(state.db(), 1).await.unwrap();
    assert_eq!(action.id, 1);
    assert_eq!(action.name, "Default");
  }

  #[tokio::test]
  async fn test_update_success() {
    let state = state::test().await;
    let action1 = "action1";
    let id = insert(state.db(), action1).await.unwrap();

    update_by_id(state.db(), id, "foobar").await.unwrap();

    let action = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(action.id, 2);
    assert_eq!(action.name, "foobar");
  }

  #[tokio::test]
  async fn test_update_failure_no_name() {
    let state = state::test().await;
    let action1 = "action1";
    let id = insert(state.db(), action1).await.unwrap();

    let err = update_by_id(state.db(), id, "").await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Action name value is required"));
  }

  #[tokio::test]
  async fn test_update_failure_not_found() {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, "foobar").await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Action with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success() {
    let state = state::test().await;
    let action1 = "action1";

    // Insert a new Action
    let id = insert(state.db(), action1).await.unwrap();
    assert_eq!(id, 2);

    let action = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(action.id, 2);
    assert_eq!(action.name, action1);
    assert!(action.created_at <= chrono::Local::now());
    assert!(action.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_all_success() {
    let state = state::test().await;
    let action1 = "action1";
    let action2 = "action2";

    insert(state.db(), action2).await.unwrap();
    insert(state.db(), action1).await.unwrap();
    let actions = fetch_all(state.db()).await.unwrap();
    assert_eq!(actions.len(), 3);

    assert_eq!(actions[0].id, 1);
    assert_eq!(actions[0].name, "Default");

    assert_eq!(actions[1].id, 3);
    assert_eq!(actions[1].name, action1);
    assert!(actions[1].created_at <= chrono::Local::now());
    assert!(actions[1].updated_at <= chrono::Local::now());

    assert_eq!(actions[2].id, 2);
    assert_eq!(actions[2].name, action2);
    assert!(actions[2].created_at <= chrono::Local::now());
    assert!(actions[2].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Action with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_duplicate() {
    let state = state::test().await;
    let action1 = "action1";

    insert(state.db(), action1).await.unwrap();
    let err = insert(state.db(), action1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::CONFLICT);
    assert_eq!(err.msg, format!("Action '{action1}' already exists"));
  }

  #[tokio::test]
  async fn test_insert_failure_empty_name() {
    let state = state::test().await;

    let err = insert(state.db(), "").await.unwrap_err();
    let err = err.as_http().unwrap();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, "Action name value is required");
  }
}