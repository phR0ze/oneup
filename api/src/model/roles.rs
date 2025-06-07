use serde::{ Deserialize, Serialize};
use sqlx::SqlitePool;
use crate::errors;

// DTOs
// *************************************************************************************************

/// Used during posts to create a new role
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreateRole {
    pub(crate) name: i64,
    pub(crate) user_id: i64,
}

/// Used during updates to change a role
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UpdateRole {
    pub(crate) id: i64,
    pub(crate) name: i64,
}

/// Full role object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Role {
    pub(crate) id: i64,
    pub(crate) name: String,
    pub(crate) user_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}

// Business Logic
// *************************************************************************************************

/// Insert a new role into the database
/// - error on user not found
/// - error on other SQL errors
pub(crate) async fn insert(db: &SqlitePool, name: &str, user_id: i64) -> errors::Result<i64> {
  super::user::fetch_by_id(db, user_id).await?;

  let result = sqlx::query(r#"INSERT INTO role (name, user_id) VALUES (?, ?)"#)
    .bind(name).bind(user_id).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {
      let msg = format!("Error inserting role '{name}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get a role by ID from the database
/// - error on role not found
/// - error on other SQL errors
pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<Role> {
  let result = sqlx::query_as::<_, Role>(r#"SELECT * FROM role WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(role) => Ok(role),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("Role with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching role with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all roles from the database for the given user
/// - error on user not found
/// - error on other SQL errors
/// - ***user_id*** owner of the points
pub(crate) async fn fetch_by_user_id(db: &SqlitePool, user_id: i64) -> errors::Result<Vec<Role>> {
  super::user::fetch_by_id(db, user_id).await?;

  let result = sqlx::query_as::<_, Role>(r#"SELECT * FROM role WHERE user_id = ?"#)
    .bind(user_id).fetch_all(db).await;
  match result {
    Ok(roles) => Ok(roles),
    Err(e) => {
      let msg = format!("Error fetching roles");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all roles from the database
/// - error on user not found
/// - error on other SQL errors
/// - ***user_id*** owner of the points
pub(crate) async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<Role>> {
  let result = sqlx::query_as::<_, Role>(r#"SELECT * FROM role"#)
    .fetch_all(db).await;
  match result {
    Ok(roles) => Ok(roles),
    Err(e) => {
      let msg = format!("Error fetching roles");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Update a role in the database
/// - only the name field can be updated
/// - error on not found
/// - error on other SQL errors
pub(crate) async fn update_by_id(db: &SqlitePool, id: i64, name: &str) -> errors::Result<()> {
  let role = fetch_by_id(db, id).await?;

  // Update role name if changed
  if role.name != name {
    let result = sqlx::query(r#"UPDATE role SET name = ? WHERE id = ?"#)
      .bind(&name).bind(&id).execute(db).await;
    if let Err(e) = result {
      let msg = format!("Error updating role with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
  Ok(())
}

/// Delete a role in the database
/// - error on other SQL errors
pub(crate) async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()> {
  let result = sqlx::query(r#"DELETE from role WHERE id = ?"#).bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting role with id '{id}'");
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
    let role1 = "role1";
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let id = insert(state.db(), role1, user_id).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_success() {
    let state = state::test().await;
    let role1 = "role1";
    let role2 = "role2";
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let id = insert(state.db(), role1, user_id).await.unwrap();

    update_by_id(state.db(), id, role2).await.unwrap();

    let role = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(role.id, 1);
    assert_eq!(role.name, role2);
    assert_eq!(role.user_id, user_id);
  }

  #[tokio::test]
  async fn test_update_failure_not_found() {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, "role1").await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Role with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success() {
    let state = state::test().await;
    let role1 = "role1";
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();

    // Insert a new role
    let id = insert(state.db(), role1, user_id).await.unwrap();
    assert_eq!(id, 1);
    let role = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(role.id, 1);
    assert_eq!(role.name, role1);
    assert_eq!(role.user_id, user_id);
    assert!(role.created_at <= chrono::Local::now());
    assert!(role.updated_at <= chrono::Local::now());
    assert_eq!(role.created_at, role.updated_at);
  }

  #[tokio::test]
  async fn test_insert_failure_user_not_found() {
    let state = state::test().await;
    let role1 = "role1";
    let user_id = 1;

    let err = insert(state.db(), role1, user_id).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '1' was not found"));
  }

  #[tokio::test]
  async fn test_fetch_all_success() {
    let state = state::test().await;
    let role1 = "role1";
    let role2 = "role2";
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();

    insert(state.db(), role1, user_id).await.unwrap();
    insert(state.db(), role2, user_id).await.unwrap();
    let roles = fetch_by_user_id(state.db(), user_id).await.unwrap();
    assert_eq!(roles.len(), 2);
    assert_eq!(roles[0].name, role1);
    assert_eq!(roles[0].id, 1);
    assert_eq!(roles[0].user_id, user_id);
    assert!(roles[0].created_at <= chrono::Local::now());
    assert!(roles[0].updated_at <= chrono::Local::now());
    assert_eq!(roles[0].created_at, roles[0].updated_at);
    assert_eq!(roles[1].name, role2);
    assert_eq!(roles[1].id, 2);
    assert_eq!(roles[1].user_id, user_id);
    assert!(roles[1].created_at <= chrono::Local::now());
    assert!(roles[1].updated_at <= chrono::Local::now());
    assert_eq!(roles[1].created_at, roles[1].updated_at);
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
    assert_eq!(err.msg, format!("Role with id '-1' was not found"));
  }
}