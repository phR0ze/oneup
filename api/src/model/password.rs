use axum::http::StatusCode;
use serde::{ Deserialize, Serialize};
use sqlx::SqlitePool;
use crate::errors;

// DTOs
// *************************************************************************************************

/// Used during posts to create a new password
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreatePassword {
    pub(crate) user_id: i64,
    pub(crate) password: String,
}

/// Passwords can be created and deleted but never updated

/// Full password object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Password {
    pub(crate) id: i64,
    pub(crate) salt: String,
    pub(crate) hash: String,
    pub(crate) user_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
}

/// Insert a new password into the database for the given user
/// - only retains the last 4 passwords for the user, anything older is deleted
/// - error on user_id not existing
/// - error on other SQL errors
/// - ***user_id*** owner of the password
/// - ***salt*** password salt
/// - ***hash*** password hash
/// - ***credential*** password salt and hash
pub(crate) async fn insert(db: &SqlitePool, user_id: i64, salt: &str, hash: &str)
  -> errors::Result<i64>
{
  // Fail if salt or hash is empty
  if salt.is_empty() || hash.is_empty() {
    let msg = format!("Password Salt or Hash can not be empty");
    log::error!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
  }

  // Ensure the user exists
  super::user::fetch_by_id(db, user_id).await?;

  // Trim back existing passwords to 3 in preparation for new one
  let passwords = fetch_by_user_id(db, user_id).await?; 
  if passwords.len() > 3 {
    // Deleting the oldest one based on descending order
    let id = passwords.last().unwrap().id;
    delete_by_id(db, id).await?;
  }

  // Insert the new password
  let result = sqlx::query(r#"INSERT INTO password (salt, hash, user_id) VALUES (?, ?, ?)"#)
    .bind(salt).bind(hash).bind(user_id).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {
      let msg = format!("Error inserting password for user_id '{}'", user_id);
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get a password by ID from the database
/// - error on not found
/// - error on other SQL errors
/// - ***id*** password id
pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<Password> {
  let result = sqlx::query_as::<_, Password>(r#"SELECT * FROM password WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(password) => Ok(password),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("Password with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching password with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all passwords from the database for the given user
/// - Orders the passwords by date in descending order
/// - error on other SQL errors
/// - ***user_id*** owner of the passwords
pub(crate) async fn fetch_by_user_id(db: &SqlitePool, user_id: i64) -> errors::Result<Vec<Password>> {

  // Ensure the user exists
  super::user::fetch_by_id(db, user_id).await?;

  let result = sqlx::query_as::<_, Password>(
    r#"SELECT * FROM password where user_id = ? ORDER BY created_at DESC"#)
    .bind(user_id).fetch_all(db).await;
  match result {
    Ok(passwords) => Ok(passwords),
    Err(e) => {
      let msg = format!("Error fetching passwords");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

// Not supporting updates to passwords

// Delete a specific password from the database
// - not exposed to the API, only used internally
// - error on other SQL errors
pub(crate) async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()> {
  let result = sqlx::query(r#"DELETE from password WHERE id = ?"#).bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting password with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests {
  use core::time;
  use super::*;
  use crate::{model, state};
  use axum::http::StatusCode;

  #[tokio::test]
  async fn test_delete_success() {
    let state = state::test().await;
    let salt1 = "salt1";
    let hash1 = "hash1";
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = model::user::insert(state.db(), user1, email1).await.unwrap();
    let id = insert(state.db(), user_id, salt1, hash1).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_fetch_by_user_id() {
    let state = state::test().await;
    let salt1 = "salt1";
    let hash1 = "hash1";
    let salt2 = "salt2";
    let hash2 = "hash2";
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = model::user::insert(state.db(), user1, email1).await.unwrap();

    insert(state.db(), user_id, salt1, hash1).await.unwrap();
    insert(state.db(), user_id, salt2, hash2).await.unwrap();
    let passwords = fetch_by_user_id(state.db(), user_id).await.unwrap();
    assert_eq!(passwords.len(), 2);
    assert_eq!(passwords[1].id, 1);
    assert_eq!(passwords[1].salt, salt1);
    assert_eq!(passwords[1].hash, hash1);
    assert_eq!(passwords[1].user_id, user_id);
    assert!(passwords[1].created_at <= chrono::Local::now());
    assert_eq!(passwords[0].id, 2);
    assert_eq!(passwords[0].salt, salt2);
    assert_eq!(passwords[0].hash, hash2);
    assert_eq!(passwords[0].user_id, user_id);
    assert!(passwords[0].created_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_by_user_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_user_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Password with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_and_trim_success() {
    let state = state::test().await;
    let (salt1, hash1) = ("salt1", "hash1");
    let (salt2, hash2) = ("salt2", "hash2");
    let (salt3, hash3) = ("salt3", "hash3");
    let (salt4, hash4) = ("salt4", "hash4");
    let (salt5, hash5) = ("salt5", "hash5");
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = model::user::insert(state.db(), user1, email1).await.unwrap();

    // Insert four then check that fifth deletes first
    insert(state.db(), user_id, salt1, hash1).await.unwrap();
    std::thread::sleep(time::Duration::from_millis(2));
    insert(state.db(), user_id, salt2, hash2).await.unwrap();
    std::thread::sleep(time::Duration::from_millis(2));
    insert(state.db(), user_id, salt3, hash3).await.unwrap();
    std::thread::sleep(time::Duration::from_millis(2));
    insert(state.db(), user_id, salt4, hash4).await.unwrap();
    std::thread::sleep(time::Duration::from_millis(2));
    insert(state.db(), user_id, salt5, hash5).await.unwrap();

    let passwords = fetch_by_user_id(state.db(), user_id).await.unwrap();
    assert_eq!(passwords.len(), 4);
    assert_eq!(passwords[0].salt, salt5);
    assert_eq!(passwords[1].salt, salt4);
    assert_eq!(passwords[2].salt, salt3);
    assert_eq!(passwords[3].salt, salt2);
  }

  #[tokio::test]
  async fn test_insert_success() {
    let state = state::test().await;
    let salt1 = "salt1";
    let hash1 = "hash1";
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = model::user::insert(state.db(), user1, email1).await.unwrap();

    // Insert a new password
    let id = insert(state.db(), user_id, salt1, hash1).await.unwrap();
    assert_eq!(id, 1);
    let password = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(password.id, 1);
    assert_eq!(password.salt, salt1);
    assert_eq!(password.hash, hash1);
    assert_eq!(password.user_id, user_id);
    assert!(password.created_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_insert_failure_user_not_found() {
    let state = state::test().await;
    let salt1 = "salt1";
    let hash1 = "hash1";
    let user_id = -1;

    let err = insert(state.db(), user_id, salt1, hash1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_hash_empty() {
    let state = state::test().await;
    let salt1 = "salt1";
    let hash1 = "";
    let user_id = -1;

    let err = insert(state.db(), user_id, salt1, hash1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Password Salt or Hash can not be empty"));
  }

  #[tokio::test]
  async fn test_insert_failure_salt_empty() {
    let state = state::test().await;
    let salt1 = "";
    let hash1 = "hash1";
    let user_id = -1;

    let err = insert(state.db(), user_id, salt1, hash1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Password Salt or Hash can not be empty"));
  }
}