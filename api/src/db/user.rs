use sqlx::SqlitePool;
use regex;
use axum::http::StatusCode;
use crate::{ errors, model };

/// Insert a new user into the database
/// 
/// - error on spaces or symbols in username
/// - error on duplicate username
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***username*** - user name
/// - ***email*** - user email
/// 
/// #### Returns
/// - ***id*** - the id of the user
pub async fn insert(db: &SqlitePool, username: &str, email: &str) -> errors::Result<i64> 
{
    validate_username(&username)?;
    validate_email(&email)?;

    // Create new user in database
    let result = sqlx::query(r#"INSERT INTO user (username, email) VALUES (?, ?)"#)
        .bind(username).bind(email).execute(db).await;
    match result {
        Ok(query) => Ok(query.last_insert_rowid()),
        Err(e) => {
            if errors::Error::is_sqlx_unique_violation(&e) {
                let msg = format!("User '{username}' already exists");
                log::warn!("{msg}");
                return Err(errors::Error::from_sqlx(e, &msg));
            }
            let msg = format!("Error inserting user '{username}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}
/// Assign the given roles to and he given user
/// 
/// - error on SQL errors
/// 
/// #### Parameters
/// - ***user_id*** id of the user
/// - ***role_ids*** list of role ids to assign to the user
pub async fn assign_roles(db: &SqlitePool, user_id: i64, role_ids: Vec<i64>) -> errors::Result<()> 
{
    let user = super::user::fetch_by_id(db, user_id).await?.username;

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
/// - error on user not found
/// - error on SQL errors
/// 
/// #### Parameters
/// - ***user_id*** - id of the user to fetch roles for
/// 
/// #### Returns
/// - ***roles*** - the roles entries
pub async fn roles(db: &SqlitePool, user_id: i64) -> errors::Result<Vec<model::Role>> 
{
    // Ensure the user exists
    let user = super::user::fetch_by_id(db, user_id).await?.username;

    // Now get the roles for the user
    let result = sqlx::query_as::<_, model::Role>(r#"SELECT role.* 
        FROM role INNER JOIN user_role ON role.id = user_role.role_id WHERE user_role.user_id = ?"#)
        .bind(user_id).fetch_all(db).await;
    match result {
        Ok(user_roles) => Ok(user_roles),
        Err(e) => {
            let msg = format!("Error fetching roles for user '{user}'");
            log::error!("{msg}");
            Err(errors::Error::from_sqlx(e, &msg))
        }
    }
}

/// Check if there are any users existing
/// 
/// - error on other SQL errors
/// 
/// #### Returns
/// - ***bool*** - true if there are any users, false otherwise
pub async fn any(db: &SqlitePool) -> errors::Result<bool> 
{
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
/// 
/// #### Parameters
/// - ***id*** user id
/// 
/// #### Returns
/// - ***user*** - the user entry
pub async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::User> 
{
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

/// Get a user by username or email from the database
/// 
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***handle*** username or email
/// 
/// #### Returns
/// - ***user*** - the user entry
pub async fn fetch_by_handle(db: &SqlitePool, handle: &str) -> errors::Result<model::User> 
{
    let field = if handle.contains('@') { "email" } else { "username" };

    let result = sqlx::query_as::<_, model::User>(&format!("SELECT * FROM user WHERE {field} = ?"))
        .bind(handle).fetch_one(db).await;
    match result {
        Ok(user) => Ok(user),
        Err(e) => {
            if errors::Error::is_sqlx_not_found(&e) {
                let msg = format!("User with {field} '{handle}' was not found");
                log::warn!("{msg}");
                return Err(errors::Error::from_sqlx(e, &msg));
            }
            let msg = format!("Error fetching user with {field} '{handle}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}

/// Get users filtered by filter
///
/// - error on SQL errors
/// - error on invalid filter
///
/// #### Parameters
/// - ***filter*** - filter object
///
/// #### Returns
/// - ***users*** - the matching user entries
pub async fn fetch_all(db: &SqlitePool, filter: model::Filter) ->
    errors::Result<Vec<model::User>>
{
    let result = match filter.role_name {
        None => {
            // Get all users when no role specified
            sqlx::query_as::<_, model::User>(r#"SELECT * FROM user ORDER BY username"#)
                .fetch_all(db).await;
        }
        Some(role_name) => {
            if !invert {
                // Get users with the specified role
                sqlx::query_as::<_, model::User>(r#"SELECT DISTINCT user.* FROM user
                    INNER JOIN user_role ON user.id = user_role.user_id
                    INNER JOIN role ON role.id = user_role.role_id
                    WHERE role.name = ? ORDER BY user.username"#)
                    .bind(role_name).fetch_all(db).await
            } else {
                // Get users without the specified role
                sqlx::query_as::<_, model::User>(r#"SELECT user.* FROM user WHERE user.id NOT IN (
                    SELECT user_id FROM user_role INNER JOIN role ON role.id = user_role.role_id
                        WHERE role.name = ?) ORDER BY user.username"#)
                    .bind(role_name).fetch_all(db).await
            }
        }
    };

    match result {
        Ok(users) => Ok(users),
        Err(e) => {
            let msg = match role {
                None => "Error fetching all users".to_string(),
                Some(role_name) => format!("Error fetching users {} role '{}'",
                    if invert { "without" } else { "with" }, role_name)
            };
            log::error!("{msg}");
            Err(errors::Error::from_sqlx(e, &msg))
        }
    }
}

/// Update a user in the database
/// 
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***id*** user id
/// - ***username*** optional user name to update
/// - ***email*** optional user email to update
pub async fn update_by_id(db: &SqlitePool, id: i64, username: Option<&str>,
    email: Option<&str>) -> errors::Result<()>
{
    let user = fetch_by_id(db, id).await?;

    // Validate and set defaults
    let username = username.unwrap_or(&user.username);
    let email = email.unwrap_or(&user.email);
    validate_username(&username)?;
    validate_email(&email)?;

    // Update user in database
    let result = sqlx::query(r#"UPDATE user SET username = ?, email = ? WHERE id = ?"#)
        .bind(&username).bind(email).bind(&id).execute(db).await;
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
/// 
/// #### Parameters
/// - ***id*** user id
pub async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()> 
{
    let result = sqlx::query(r#"DELETE from user WHERE id = ?"#)
        .bind(id).execute(db).await;
    if let Err(e) = result {
        let msg = format!("Error deleting user with id '{id}'");
        log::error!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
    }
    Ok(())
}

// Ensure the username is following the constraints we need it to
fn validate_username(username: &str) -> errors::Result<()> 
{
    let re = regex::Regex::new(r"^[a-zA-Z0-9_-]{5,}$").unwrap();
    if !re.is_match(username) {
        let msg = "Username must contain only alpha numeric, underscore or dash characters and be at least 5 characters long";
        log::warn!("{msg}");
        return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
    }
    Ok(())
}

// Helper for email validation
fn validate_email(email: &str) -> errors::Result<()> 
{
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
mod tests 
{
    use super::*;
    use crate::{db, state};

    #[tokio::test]
    async fn test_fetch_by_role_with_role() {
        let state = state::test().await;
        
        // Create test users
        let user1 = "user1";
        let user2 = "user2"; 
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let id1 = insert(state.db(), user1, email1).await.unwrap();
        let id2 = insert(state.db(), user2, email2).await.unwrap();

        // Create and assign roles
        let role_id = db::role::insert(state.db(), "user").await.unwrap();
        assign_roles(state.db(), id1, vec![role_id]).await.unwrap();

        // Test fetching users with role
        let users = fetch_by_role(state.db(), "user", false).await.unwrap();
        assert_eq!(users.len(), 1);
        assert_eq!(users[0].username, user1);
        assert_eq!(users[0].id, id1);

        // Test fetching users without role 
        let users = fetch_by_role(state.db(), "user", true).await.unwrap();
        assert_eq!(users.len(), 2); // admin + user2
        assert_eq!(users[0].username, "admin");
        assert_eq!(users[1].username, user2);
    }

    #[tokio::test]
    async fn test_fetch_by_role_no_matches() {
        let state = state::test().await;
        
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let _id = insert(state.db(), user1, email1).await.unwrap();

        // Test non-existent role
        let users = fetch_by_role(state.db(), "nonexistent", false).await.unwrap();
        assert_eq!(users.len(), 0);

        // Test inverted non-existent role
        let users = fetch_by_role(state.db(), "nonexistent", true).await.unwrap();
        assert_eq!(users.len(), 2); // admin + user1
    }

    #[tokio::test]
    async fn test_delete_recursive() 
    {
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
    async fn test_delete_success() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let id = insert(state.db(), user1, email1).await.unwrap();

        delete_by_id(state.db(), id).await.unwrap();

        let err = fetch_by_id(state.db(), id).await.unwrap_err();
        assert_eq!(err.kind, errors::ErrorKind::NotFound);
    }

    #[tokio::test]
    async fn test_update_success() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";

        let id = insert(state.db(), user1, email1).await.unwrap();

        update_by_id(state.db(), id, Some(&user2), Some(&email2)).await.unwrap();

        let user = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(user.id, id);
        assert_eq!(user.username, user2);
    }

    #[tokio::test]
    async fn test_update_failure_no_username() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let id = insert(state.db(), user1, email1).await.unwrap();

        let err = update_by_id(state.db(), id, Some(""), None).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, "Username must contain only alpha numeric, underscore or dash characters and be at least 5 characters long");
    }

    #[tokio::test]
    async fn test_update_failure_invalid_email() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let id = insert(state.db(), user1, email1).await.unwrap();

        let err = update_by_id(state.db(), id, None, Some("foo")).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, format!("User email is invalid"));
    }

    #[tokio::test]
    async fn test_update_failure_not_found() 
    {
        let state = state::test().await;

        let err = update_by_id(state.db(), -1, None, None).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("User with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_insert_success() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";

        // Insert a new user
        let id = insert(state.db(), user1, email1).await.unwrap();
        let user = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(user.id, id);
        assert_eq!(user.username, user1);
        assert!(user.created_at <= chrono::Local::now());
        assert!(user.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_any() 
    {
        let state = state::test().await;

        // will always be the admin user
        assert_eq!(any(state.db()).await.unwrap(), true);
    }

    #[tokio::test]
    async fn test_fetch_all_success() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";

        let id2 = insert(state.db(), user2, email2).await.unwrap();
        let id1 = insert(state.db(), user1, email1).await.unwrap();
        let users = fetch_all(state.db()).await.unwrap();
        assert_eq!(users.len(), 3);

        assert_eq!(users[0].id, 1);
        assert_eq!(users[0].username, "admin");
        assert_eq!(users[0].email, "admin@oneup.local");
 
        assert_eq!(users[1].id, id1);
        assert_eq!(users[1].username, user1);
        assert_eq!(users[1].email, email1);
        assert!(users[1].created_at <= chrono::Local::now());
        assert!(users[1].updated_at <= chrono::Local::now());

        assert_eq!(users[2].id, id2);
        assert_eq!(users[2].username, user2);
        assert_eq!(users[2].email, email2);
        assert!(users[2].created_at <= chrono::Local::now());
        assert!(users[2].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_roles_admin() 
    {
        let state = state::test().await;
        
        // Get roles for admin user (id=1)
        let admin_roles = roles(state.db(), 1).await.unwrap();
        
        // Admin should only have the admin role
        assert_eq!(admin_roles.len(), 1);
        
        // Validate all fields of the admin role
        let admin_role = &admin_roles[0];
        assert_eq!(admin_role.id, 1);
        assert_eq!(admin_role.name, "admin");
        assert!(admin_role.created_at <= chrono::Local::now());
        assert!(admin_role.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_assign_success() 
    {
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
    async fn test_assign_failure_user_not_found() 
    {
        let state = state::test().await;

        let err = assign_roles(state.db(), 10, vec![1, 2]).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("User with id '10' was not found"));
    }

    #[tokio::test]
    async fn test_assign_failure_role_not_found() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let id = insert(state.db(), user1, email1).await.unwrap();

        let err = assign_roles(state.db(), id, vec![2, 3]).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Role with id '2' was not found"));
    }

    #[tokio::test]
    async fn test_fetch_by_id_failure_not_found() 
    {
        let state = state::test().await;

        let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("User with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_insert_failure_duplicate_email() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";

        insert(state.db(), user1, email1).await.unwrap();
        let err = insert(state.db(), user1, email1).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::CONFLICT);
        assert_eq!(err.msg, format!("User '{user1}' already exists"));
    }

    #[tokio::test]
    async fn test_insert_success_valid_usernames() 
    {
        let state = state::test().await;

        // Test various valid username patterns and lengths
        let test_cases = vec![
            ("user1", "user1@foo.com"),     // Exactly 5 chars
            ("user_1", "user_1@foo.com"),    // 6 chars with underscore
            ("user-12", "user-12@foo.com"),   // 7 chars with dash
            ("USER123", "user123@foo.com"),   // 7 chars uppercase
            ("12345678", "12345678@foo.com"),  // 8 chars all numbers
            ("user_name", "user_name@foo.com"), // 9 chars
            ("very_long_user_name", "very_long@foo.com") // Much longer
        ];

        for (name, email) in test_cases {
            let result = insert(state.db(), name, email).await;
            assert!(result.is_ok(), "Username '{}' should be valid", name);
        }
    }

    #[tokio::test]
    async fn test_insert_failure_name_too_short() 
    {
        let state = state::test().await;
        let user1 = "usr";
        let email1 = "user1@foo.com";

        let err = insert(state.db(), user1, email1).await.unwrap_err();
        let err = err.as_http().unwrap();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, "Username must contain only alpha numeric, underscore or dash characters and be at least 5 characters long");
    }

    #[tokio::test]
    async fn test_insert_failure_empty_name() 
    {
        let state = state::test().await;

        let err = insert(state.db(), "", "").await.unwrap_err();
        let err = err.as_http().unwrap();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, "Username must contain only alpha numeric, underscore or dash characters and be at least 5 characters long");
    }

    #[tokio::test]
    async fn test_insert_failure_empty_email() 
    {
        let state = state::test().await;
        let user1 = "user1";

        let err = insert(state.db(), user1, "").await.unwrap_err();
        let err = err.as_http().unwrap();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, "User email value is required");
    }
}