use sqlx::SqlitePool;
use axum::http::StatusCode;
use crate::{ errors, model };

/// Insert a new user into the database
/// 
/// - error on empty name
/// - error on empty email
/// - error on duplicate email
/// - error on other SQL errors
/// - ***name*** user name
/// - ***email*** user email
pub(crate) async fn insert(db: &SqlitePool, name: &str, email: &str) -> errors::Result<i64> {
  validate_name(&name)?;
  validate_email(&email)?;

  // Create new user in database
  let result = sqlx::query(r#"INSERT INTO user (name, email) VALUES (?, ?)"#)
    .bind(name).bind(email).execute(db).await;
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
/// Assign the given roles to and he given user
/// 
/// - error on SQL errors
/// - ***user_id*** id of the user
/// - ***role_ids*** list of role ids to assign to the user
pub(crate) async fn assign_roles(db: &SqlitePool, user_id: i64, role_ids: Vec<i64>) -> errors::Result<()> {
  let user = super::user::fetch_by_id(db, user_id).await?.name;

  for role_id in role_ids {
    let role = super::role::fetch_by_id(db, role_id).await?.name;

    let result = sqlx::query(r#"INSERT INTO user_role (user_id, role_id) VALUES (?, ?)"#)
      .bind(user_id).bind(role_id).execute(db).await;
    if let Err(e) = result {
      let msg = format!("Error assigning role '{role}' to user '{user}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }

  Ok(())
}

/// Get all roles for the given user
/// 
/// - error on SQL errors
/// - ***user_id*** - id of the user to fetch roles for
pub(crate) async fn roles(db: &SqlitePool, user_id: i64) -> errors::Result<Vec<model::UserRole>> {
  let result = sqlx::query_as::<_, model::UserRole>(r#"SELECT role.id AS id, role.name AS name
    FROM role INNER JOIN user_role ON role.id = user_role.role_id WHERE user_role.user_id = ?"#)
    .bind(user_id).fetch_all(db).await;
  match result {
    Ok(user_roles) => Ok(user_roles),
    Err(e) => {
      let msg = format!("Error fetching roles for user with id '{user_id}'");
      log::error!("{msg}");
      Err(errors::Error::from_sqlx(e, &msg))
    }
  }
}

/// Check if there are any users existing
/// 
/// - error on other SQL errors
pub(crate) async fn any(db: &SqlitePool) -> errors::Result<bool> {
  let result = sqlx::query_as::<_, model::User>(r#"SELECT * FROM user LIMIT 1"#)
    .fetch_all(db).await;
  match result {
    Ok(users) => Ok(users.len() > 0),
    Err(e) => {
      let msg = format!("Error fetching users");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get a user by ID from the database
/// 
/// - error on not found
/// - error on other SQL errors
/// - ***id*** user id
pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::User> {
  let result = sqlx::query_as::<_, model::User>(r#"SELECT * FROM user WHERE id = ?"#)
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

/// Get a user by email from the database
/// 
/// - error on not found
/// - error on other SQL errors
/// - ***email*** user email
pub(crate) async fn fetch_by_email(db: &SqlitePool, email: &str) -> errors::Result<model::User> {
  let result = sqlx::query_as::<_, model::User>(r#"SELECT * FROM user WHERE email = ?"#)
    .bind(email).fetch_one(db).await;
  match result {
    Ok(user) => Ok(user),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("User with email '{email}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      }
      let msg = format!("Error fetching user with email '{email}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all users from the database
/// 
/// - orders the users by name
/// - error on other SQL errors
pub(crate) async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<model::User>> {
  let result = sqlx::query_as::<_, model::User>(r#"SELECT * FROM user ORDER BY name"#)
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
/// 
/// - error on not found
/// - error on other SQL errors
/// - ***id*** user id
/// - ***name*** optional user name to update
/// - ***email*** optional user email to update
pub(crate) async fn update_by_id(db: &SqlitePool, id: i64, name: Option<&str>,
  email: Option<&str>) -> errors::Result<()>
{
  let user = fetch_by_id(db, id).await?;

  // Validate and set defaults
  let name = name.unwrap_or(&user.name);
  let email = email.unwrap_or(&user.email);
  validate_name(&name)?;
  validate_email(&email)?;

  // Update user in database
  let result = sqlx::query(r#"UPDATE user SET name = ?, email = ? WHERE id = ?"#)
    .bind(&name).bind(email).bind(&id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error updating user with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

/// Delete a user in the database
/// 
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

// Helper for name validation
fn validate_name(name: &str) -> errors::Result<()> {
  if name.is_empty() {
    let msg = "User name value is required";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }
  Ok(())
}

// Helper for email validation
fn validate_email(email: &str) -> errors::Result<()> {

  // Can't be empty
  if email.is_empty() {
    let msg = "User email value is required";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }

  // Perform basic email validation
  if !email.contains('@') || !email.contains('.') || email.starts_with('@') ||
    email.ends_with('@') || email.starts_with('.') || email.ends_with('.')
  {
    let msg = "User email is invalid";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::{db, state};

  #[tokio::test]
  async fn test_delete_recursive() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = insert(state.db(), user1, email1).await.unwrap();
    let reward1 = 10;
    let reward_id = db::reward::insert(state.db(), reward1, user_id).await.unwrap();

    delete_by_id(state.db(), user_id).await.unwrap();

    // Check that user was deleted
    let err = fetch_by_id(state.db(), user_id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);

    // Check that reward was deleted
    let err = db::reward::fetch_by_id(state.db(), reward_id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_delete_success() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let id = insert(state.db(), user1, email1).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_success() {
    let state = state::test().await;
    let user1 = "user1";
    let user2 = "user2";
    let email1 = "user1@foo.com";
    let email2 = "user2@foo.com";

    let id = insert(state.db(), user1, email1).await.unwrap();

    update_by_id(state.db(), id, Some(&user2), Some(&email2)).await.unwrap();

    let user = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(user.id, id);
    assert_eq!(user.name, user2);
  }

  #[tokio::test]
  async fn test_update_failure_no_name() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let id = insert(state.db(), user1, email1).await.unwrap();

    let err = update_by_id(state.db(), id, Some(""), None).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("User name value is required"));
  }

  #[tokio::test]
  async fn test_update_failure_invalid_email() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let id = insert(state.db(), user1, email1).await.unwrap();

    let err = update_by_id(state.db(), id, None, Some("foo")).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("User email is invalid"));
  }

  #[tokio::test]
  async fn test_update_failure_not_found() {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, None, None).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";

    // Insert a new user
    let id = insert(state.db(), user1, email1).await.unwrap();
    let user = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(user.id, id);
    assert_eq!(user.name, user1);
    assert!(user.created_at <= chrono::Local::now());
    assert!(user.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_any() {
    let state = state::test().await;

    // Check before
    assert_eq!(any(state.db()).await.unwrap(), false);

    // Check after creating one
    let user1 = "user1";
    let email1 = "user1@foo.com";
    insert(state.db(), user1, email1).await.unwrap();
    assert_eq!(any(state.db()).await.unwrap(), true);
  }

  #[tokio::test]
  async fn test_fetch_all_success() {
    let state = state::test().await;
    let user1 = "user1";
    let user2 = "user2";
    let email1 = "user1@foo.com";
    let email2 = "user2@foo.com";

    let id2 = insert(state.db(), user2, email2).await.unwrap();
    let id1 = insert(state.db(), user1, email1).await.unwrap();
    let users = fetch_all(state.db()).await.unwrap();
    assert_eq!(users.len(), 2);

    assert_eq!(users[0].id, id1);
    assert_eq!(users[0].name, user1);
    assert_eq!(users[0].email, email1);
    assert!(users[0].created_at <= chrono::Local::now());
    assert!(users[0].updated_at <= chrono::Local::now());

    assert_eq!(users[1].id, id2);
    assert_eq!(users[1].name, user2);
    assert_eq!(users[1].email, email2);
    assert!(users[1].created_at <= chrono::Local::now());
    assert!(users[1].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_assign_success() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = insert(state.db(), user1, email1).await.unwrap();

    // Check that the user has no roles initially
    let initial_roles = roles(state.db(), user_id).await.unwrap();
    assert!(initial_roles.is_empty());

    // Assign multiple roles to the user
    // Create roles before assigning them
    let role_editor_id = db::role::insert(state.db(), "editor").await.unwrap();
    assign_roles(state.db(), user_id, vec![1, role_editor_id]).await.unwrap();

    // Verify the user now has the assigned roles
    let updated_roles = roles(state.db(), user_id).await.unwrap();
    assert!(updated_roles.iter().any(|role| role.name == "admin"));
    assert!(updated_roles.iter().any(|role| role.name == "editor"));
  }

  #[tokio::test]
  async fn test_assign_failure_user_not_found() {
    let state = state::test().await;

    let err = assign_roles(state.db(), 1, vec![1, 2]).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '1' was not found"));
  }

  #[tokio::test]
  async fn test_assign_failure_role_not_found() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let id = insert(state.db(), user1, email1).await.unwrap();

    let err = assign_roles(state.db(), id, vec![2, 3]).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Role with id '2' was not found"));
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("User with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_duplicate_email() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";

    insert(state.db(), user1, email1).await.unwrap();
    let err = insert(state.db(), user1, email1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::CONFLICT);
    assert_eq!(err.msg, format!("User '{user1}' already exists"));
  }

  #[tokio::test]
  async fn test_insert_failure_empty_name() {
    let state = state::test().await;

    let err = insert(state.db(), "", "").await.unwrap_err();
    let err = err.as_http().unwrap();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, "User name value is required");
  }

  #[tokio::test]
  async fn test_insert_failure_empty_email() {
    let state = state::test().await;
    let user1 = "user1";

    let err = insert(state.db(), user1, "").await.unwrap_err();
    let err = err.as_http().unwrap();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, "User email value is required");
  }

}