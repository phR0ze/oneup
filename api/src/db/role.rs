use sqlx::SqlitePool;
use axum::http::StatusCode;
use crate::{ errors, model };

/// Insert a new role into the database
/// 
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - the database connection pool
/// - ***name*** - the name of the role to insert
/// 
/// #### Returns
/// - ***id*** - the id of the role
pub async fn insert(db: &SqlitePool, name: &str) -> errors::Result<i64>
{
    validate_name_given(&name)?;

    // Create new role in the database
    let result = sqlx::query(r#"INSERT INTO role (name) VALUES (?)"#)
        .bind(name).execute(db).await;
    match result {
        Ok(query) => Ok(query.last_insert_rowid()),
        Err(e) => {
            if errors::Error::is_sqlx_unique_violation(&e) {
                let msg = format!("Role '{name}' already exists");
                log::warn!("{msg}");
                return Err(errors::Error::from_sqlx(e, &msg));
            }
            let msg = format!("Error inserting role '{name}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}

/// Get a role by name from the database
/// 
/// - error on role not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - the database connection pool
/// - ***name*** - the name of the role to fetch
/// 
/// #### Returns
/// - ***role*** - the role entry
pub async fn fetch_by_name(db: &SqlitePool, name: &str) -> errors::Result<model::Role>
{
    let result = sqlx::query_as::<_, model::Role>(r#"SELECT * FROM role WHERE name = ?"#)
        .bind(name).fetch_one(db).await;
    match result {
        Ok(role) => Ok(role),
        Err(e) => {
            if errors::Error::is_sqlx_not_found(&e) {
                let msg = format!("Role with name '{name}' was not found");
                log::warn!("{msg}");
                return Err(errors::Error::from_sqlx(e, &msg));
            } 
            let msg = format!("Error fetching role with name '{name}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}


/// Get a role by ID from the database
/// 
/// - error on role not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - the database connection pool
/// - ***id*** - the ID of the role to fetch
/// 
/// #### Returns
/// - ***role*** - the role entry
pub async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::Role>
{
    let result = sqlx::query_as::<_, model::Role>(r#"SELECT * FROM role WHERE id = ?"#)
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

/// Get all roles from the database
/// 
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - the database connection pool
/// 
/// #### Returns
/// - ***roles*** - the roles entries
pub async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<model::Role>>
{
    let result = sqlx::query_as::<_, model::Role>(r#"SELECT * FROM role"#).fetch_all(db).await;
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
/// 
/// - only the name field can be updated
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - the database connection pool
/// - ***id*** - the ID of the role to update
/// - ***name*** - the new name for the role
pub async fn update_by_id(db: &SqlitePool, id: i64, name: &str) -> errors::Result<()>
{
    let role = fetch_by_id(db, id).await?;

    // Update role name if changed
    if role.name != name {
        validate_name_given(&name)?;

        // Update role in database
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
/// 
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - the database connection pool
/// - ***id*** - the ID of the role to delete
pub async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()>
{
    // Don't allow deletion of the admin role
    if id == 1 {
        let msg = format!("Cannot delete 'admin' role");
        log::warn!("{msg}");
        return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
    }

    let result = sqlx::query(r#"DELETE from role WHERE id = ?"#).bind(id).execute(db).await;
    if let Err(e) = result {
        let msg = format!("Error deleting role with id '{id}'");
        log::error!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
    }
    Ok(())
}

// Helper for name not given error
fn validate_name_given(name: &str) -> errors::Result<()>
{
    if name.is_empty() {
        let msg = "Role name value is required";
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
    use axum::http::StatusCode;

    #[tokio::test]
    async fn test_delete_success()
    {
        let state = state::test().await;
        let role1 = "role1";
        let id = insert(state.db(), role1).await.unwrap();

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
        assert_eq!(err.msg, format!("Cannot delete 'admin' role"));

        let role = fetch_by_id(state.db(), 1).await.unwrap();
        assert_eq!(role.id, 1);
        assert_eq!(role.name, "admin");
    }

    #[tokio::test]
    async fn test_update_success()
    {
        let state = state::test().await;
        let role1 = "role1";
        let role2 = "role2";
        let id = insert(state.db(), role1).await.unwrap();

        update_by_id(state.db(), id, role2).await.unwrap();

        let role = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(role.id, 2);
        assert_eq!(role.name, role2);
    }

    #[tokio::test]
    async fn test_update_failure_no_name()
    {
        let state = state::test().await;
        let role1 = "role1";
        let id = insert(state.db(), role1).await.unwrap();

        let err = update_by_id(state.db(), id, "").await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, format!("Role name value is required"));
    }

    #[tokio::test]
    async fn test_update_failure_not_found()
    {
        let state = state::test().await;

        let err = update_by_id(state.db(), -1, "role1").await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Role with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_insert_success()
    {
        let state = state::test().await;
        let role1 = "role1";

        // Insert a new role
        let id = insert(state.db(), role1).await.unwrap();
        assert_eq!(id, 2);

        let role = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(role.id, 2);
        assert_eq!(role.name, role1);
        assert!(role.created_at <= chrono::Local::now());
        assert!(role.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_fetch_all_success()
    {
        let state = state::test().await;
        let role1 = "role1";
        let role2 = "role2";

        insert(state.db(), role1).await.unwrap();
        insert(state.db(), role2).await.unwrap();

        let roles = fetch_all(state.db()).await.unwrap();
        assert_eq!(roles.len(), 3);

        assert_eq!(roles[0].id, 1);
        assert_eq!(roles[0].name, "admin");

        assert_eq!(roles[1].id, 2);
        assert_eq!(roles[1].name, role1);
        assert!(roles[1].created_at <= chrono::Local::now());
        assert!(roles[1].updated_at <= chrono::Local::now());

        assert_eq!(roles[2].id, 3);
        assert_eq!(roles[2].name, role2);
        assert!(roles[2].created_at <= chrono::Local::now());
        assert!(roles[2].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_fetch_by_id()
    {
        let state = state::test().await;
        let role1 = "role1";
        let id = insert(state.db(), role1).await.unwrap();

        let role = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(role.id, id);
        assert_eq!(role.name, role1);
    }

    #[tokio::test]
    async fn test_fetch_by_name()
    {
        let state = state::test().await;
        let role1 = "role1";
        let id = insert(state.db(), role1).await.unwrap();

        let role = fetch_by_name(state.db(), role1).await.unwrap();
        assert_eq!(role.id, id);
        assert_eq!(role.name, role1);
    }

    #[tokio::test]
    async fn test_fetch_by_id_failure_not_found()
    {
        let state = state::test().await;

        let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Role with id '-1' was not found"));
    }
}