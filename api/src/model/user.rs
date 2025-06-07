use serde::{ Deserialize, Serialize};
use sqlx::SqlitePool;
use axum::http::StatusCode;

use crate::errors;

// DTOs
// *************************************************************************************************

/// Used during posts to create a new user
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreateUser {
    pub(crate) name: String,
}

/// Used during updates to change a user
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UpdateUser {
    pub(crate) id: i64,
    pub(crate) name: String,
}

/// Full user object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct User {
    pub(crate) id: i64,
    pub(crate) name: String,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}

// Business Logic
// *************************************************************************************************

/// Insert a new user into the database
/// - error on empty name
/// - error on duplicate name
/// - error on other SQL errors
/// - ***name*** user name
pub(crate) async fn insert(db: &SqlitePool, name: &str) -> errors::Result<i64> {
  validate_name_given(&name)?;

  // Create new user in database
  let result = sqlx::query(r#"INSERT INTO user (name) VALUES (?)"#)
    .bind(name).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {
      if errors::Error::is_sqlx_unique_violation(&e) {
        let msg = format!("User '{name}' already exists");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      }
      let msg = format!("Error inserting user '{name}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get a user by ID from the database
/// - error on not found
/// - error on other SQL errors
/// - ***id*** user id
pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<User> {
  let result = sqlx::query_as::<_, User>(r#"SELECT * FROM user WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(user) => Ok(user),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("User with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching user with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all users from the database
/// - orders the users by name
/// - error on other SQL errors
pub(crate) async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<User>> {
  let result = sqlx::query_as::<_, User>(r#"SELECT * FROM user ORDER BY name"#)
    .fetch_all(db).await;
  match result {
    Ok(users) => Ok(users),
    Err(e) => {
      let msg = format!("Error fetching users");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Update a user in the database
/// - only the name field can be updated
/// - error on not found
/// - error on other SQL errors
/// - ***id*** user id
/// - ***name*** user name
pub(crate) async fn update_by_id(db: &SqlitePool, id: i64, name: &str) -> errors::Result<()> {
  let user = fetch_by_id(db, id).await?;

  // Update user name if changed
  if user.name != name {
    validate_name_given(&name)?;

    // Update user in database
    let result = sqlx::query(r#"UPDATE user SET name = ? WHERE id = ?"#)
      .bind(&name).bind(&id).execute(db).await;
    if let Err(e) = result {
      let msg = format!("Error updating user with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
  Ok(())
}

/// Delete a user in the database
/// - error on other SQL errors
/// - ***id*** user id
pub(crate) async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()> {
  let result = sqlx::query(r#"DELETE from user WHERE id = ?"#)
    .bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting user with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

// Helper for name not given error
fn validate_name_given(name: &str) -> errors::Result<()> {
  if name.is_empty() {
    let msg = "User name value is required";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::{model, state};

  #[tokio::test]
  async fn test_delete_recursive() {
    let state = state::test().await;
    let user1 = "user1";
    let user_id = insert(state.db(), user1).await.unwrap();
    let reward1 = 10;
    let reward_id = model::reward::insert(state.db(), reward1, user_id).await.unwrap();

    delete_by_id(state.db(), user_id).await.unwrap();

    // Check that user was deleted
    let err = fetch_by_id(state.db(), user_id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);

    // Check that reward was deleted
    let err = model::reward::fetch_by_id(state.db(), reward_id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_delete_success() {
    let state = state::test().await;
    let user1 = "user1";
    let id = insert(state.db(), user1).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_success() {
    let state = state::test().await;
    let user1 = "user1";
    let user2 = "user2";

    let id = insert(state.db(), user1).await.unwrap();

    update_by_id(state.db(), id, &user2).await.unwrap();

    let user = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(user.id, id);
    assert_eq!(user.name, user2);
  }

  #[tokio::test]
  async fn test_update_failure_no_name() {
    let state = state::test().await;
    let user1 = "user1";
    let id = insert(state.db(), user1).await.unwrap();

    let err = update_by_id(state.db(), id, "").await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("User name value is required"));
  }

  #[tokio::test]
  async fn test_update_failure_not_found() {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, "foobar").await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success() {
    let state = state::test().await;
    let user1 = "user1";

    // Insert a new user
    let id = insert(state.db(), user1).await.unwrap();
    let user = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(user.id, id);
    assert_eq!(user.name, user1);
    assert!(user.created_at <= chrono::Local::now());
    assert!(user.updated_at <= chrono::Local::now());
    assert_eq!(user.created_at, user.updated_at);
  }

  #[tokio::test]
  async fn test_fetch_all_success() {
    let state = state::test().await;
    let user1 = "user1";
    let user2 = "user2";

    let id2 = insert(state.db(), user2).await.unwrap();
    let id1 = insert(state.db(), user1).await.unwrap();
    let users = fetch_all(state.db()).await.unwrap();
    assert_eq!(users.len(), 2);
    assert_eq!(users[0].name, user1);
    assert_eq!(users[0].id, id1);
    assert!(users[0].created_at <= chrono::Local::now());
    assert!(users[0].updated_at <= chrono::Local::now());
    assert_eq!(users[0].created_at, users[0].updated_at);
    assert_eq!(users[1].name, user2);
    assert_eq!(users[1].id, id2);
    assert!(users[1].created_at <= chrono::Local::now());
    assert!(users[1].updated_at <= chrono::Local::now());
    assert_eq!(users[1].created_at, users[1].updated_at);
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_duplicate() {
    let state = state::test().await;
    let user1 = "user1";

    insert(state.db(), user1).await.unwrap();
    let err = insert(state.db(), user1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::CONFLICT);
    assert_eq!(err.msg, format!("User '{user1}' already exists"));
  }

  #[tokio::test]
  async fn test_insert_failure_empty_name() {
    let state = state::test().await;

    let err = insert(state.db(), "").await.unwrap_err();
    let err = err.as_http().unwrap();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, "User name value is required");
  }
}