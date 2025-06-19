use sqlx::SqlitePool;
use axum::http::StatusCode;
use crate::{ errors, model };

/// Insert a new Action into the database
/// 
/// - error on empty desc
/// - error on duplicate desc
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***desc*** - description of the action to create
/// - ***value*** - optional value of the action to create
/// - ***category_id*** - optional category id to associate with the action
/// 
/// #### Returns
/// - ***id*** - id of the action
pub async fn insert(db: &SqlitePool, desc: &str, value: Option<i64>,
    category_id: Option<i64>) -> errors::Result<i64>
{
    validate_desc(&desc)?;

    // Validate and set defaults
    let value = value.unwrap_or(0);
    let category_id = category_id.unwrap_or(1);

    // Create new Action in database
    let result = sqlx::query(r#"INSERT INTO action (desc, value, category_id) VALUES (?, ?, ?)"#)
        .bind(desc).bind(value).bind(category_id).execute(db).await;
    match result {
        Ok(query) => Ok(query.last_insert_rowid()),
        Err(e) => {

            // Error on duplicates
            if errors::Error::is_sqlx_unique_violation(&e) {
                let msg = format!("Action '{desc}' already exists");
                log::warn!("{msg}");
                return Err(errors::Error::from_sqlx(e, &msg));
            }

            // Error on entity not found
            if errors::Error::is_sqlx_foreign_key_constraint_failed(&e) {
                let msg = format!("Invalid category_id '{category_id}'");
                log::warn!("{msg}");
                return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
            }

            // Error on other SQL errors
            let msg = format!("Error inserting action '{desc}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}

/// Get an action by id from the database
/// 
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***id*** - id of the action to fetch
/// 
/// #### Returns
/// - ***action*** - action entry
pub async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::Action>
{
    let result = sqlx::query_as::<_, model::Action>(r#"SELECT * FROM action WHERE id = ?"#)
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
/// - orders the actions by desc
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// 
/// #### Returns
/// - ***actions*** - actions entries
pub async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<model::Action>>
{
    let result = sqlx::query_as::<_, model::Action>(r#"SELECT * FROM action ORDER BY desc"#).fetch_all(db).await;
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
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***id*** id of the action to update
/// - ***desc*** description of the action to update
/// - ***value*** value of the action to update
/// - ***category_id*** optional category id to associate with the action
pub async fn update_by_id(db: &SqlitePool, id: i64, desc: Option<&str>, value: Option<i64>,
    category_id: Option<i64>) -> errors::Result<()>
{
    let action = fetch_by_id(db, id).await?;

    // Validate and set defaults
    let desc = desc.unwrap_or(&action.desc);
    let value = value.unwrap_or(action.value);
    let category_id = category_id.unwrap_or(action.category_id);
    validate_desc(&desc)?;

    // Update action in database
    let result = sqlx::query(r#"UPDATE action SET desc = ?, value = ?, category_id = ? WHERE id = ?"#)
        .bind(&desc).bind(value).bind(category_id).bind(&id).execute(db).await;
    if let Err(e) = result {
        let msg = format!("Error updating action with id '{id}'");
        log::error!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
    }
    Ok(())
}

/// Delete a Action in the database
/// 
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***id*** id of the action to delete
pub async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()>
{
    // Don't allow deletion of the Unspecified action
    if id == 1 {
        let msg = format!("Cannot delete 'Unspecified' action");
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

// Helper for desc not given error
fn validate_desc(desc: &str) -> errors::Result<()>
{
    if desc.is_empty() {
        let msg = "Action desc value is required";
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
    async fn test_delete_success()
    {
        let state = state::test().await;
        let action1 = "action1";
        let id = insert(state.db(), action1, None, None).await.unwrap();

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
        assert_eq!(err.msg, format!("Cannot delete 'Unspecified' action"));

        let action = fetch_by_id(state.db(), 1).await.unwrap();
        assert_eq!(action.id, 1);
        assert_eq!(action.desc, "Unspecified");
    }

    #[tokio::test]
    async fn test_update_success()
    {
        let state = state::test().await;
        let action1 = "action1";
        let action2 = "action2";
        let category1 = "category1";
        let id = insert(state.db(), action1, Some(2), None).await.unwrap();
        let category_id = db::category::insert(state.db(), category1).await.unwrap();

        update_by_id(state.db(), id, Some(action2), Some(3), Some(category_id)).await.unwrap();

        let action = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(action.id, 2);
        assert_eq!(action.desc, action2);
        assert_eq!(action.value, 3);
        assert_eq!(action.category_id, category_id);
    }

    #[tokio::test]
    async fn test_update_failure_no_desc()
    {
        let state = state::test().await;
        let action1 = "action1";
        let id = insert(state.db(), action1, None, None).await.unwrap();

        let err = update_by_id(state.db(), id, Some(""), None, None).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, format!("Action desc value is required"));
    }

    #[tokio::test]
    async fn test_update_failure_not_found()
    {
        let state = state::test().await;

        let err = update_by_id(state.db(), -1, None, None, None).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Action with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_insert_success()
    {
        let state = state::test().await;
        let action1 = "action1";

        // Insert a new Action
        let id = insert(state.db(), action1, Some(2), None).await.unwrap();
        assert_eq!(id, 2);

        let action = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(action.id, 2);
        assert_eq!(action.desc, action1);
        assert_eq!(action.value, 2);
        assert_eq!(action.category_id, 1);
        assert!(action.created_at <= chrono::Local::now());
        assert!(action.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_fetch_all_success()
    {
        let state = state::test().await;
        let action1 = "action1";
        let action2 = "action2";

        insert(state.db(), action2, Some(2), None).await.unwrap();
        std::thread::sleep(std::time::Duration::from_millis(2));
        insert(state.db(), action1, None, None).await.unwrap();
        let actions = fetch_all(state.db()).await.unwrap();
        assert_eq!(actions.len(), 3);

        assert_eq!(actions[0].id, 1);
        assert_eq!(actions[0].desc, "Unspecified");
        assert_eq!(actions[0].value, 0);
        assert_eq!(actions[0].category_id, 1);

        assert_eq!(actions[1].id, 3);
        assert_eq!(actions[1].desc, action1);
        assert_eq!(actions[1].value, 0);
        assert_eq!(actions[1].category_id, 1);
        assert!(actions[1].created_at <= chrono::Local::now());
        assert!(actions[1].updated_at <= chrono::Local::now());

        assert_eq!(actions[2].id, 2);
        assert_eq!(actions[2].desc, action2);
        assert_eq!(actions[2].value, 2);
        assert_eq!(actions[2].category_id, 1);
        assert!(actions[2].created_at <= chrono::Local::now());
        assert!(actions[2].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_fetch_by_id_failure_not_found()
    {
        let state = state::test().await;

        let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Action with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_insert_failure_duplicate()
    {
        let state = state::test().await;
        let action1 = "action1";

        insert(state.db(), action1, None, None).await.unwrap();
        let err = insert(state.db(), action1, None, None).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::CONFLICT);
        assert_eq!(err.msg, format!("Action '{action1}' already exists"));
    }

    #[tokio::test]
    async fn test_insert_failure_empty_desc()
    {
        let state = state::test().await;

        let err = insert(state.db(), "", None, None).await.unwrap_err();
        let err = err.as_http().unwrap();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, "Action desc value is required");
    }

    #[tokio::test]
    async fn test_insert_failure_invalid_category_id()
    {
        let state = state::test().await;
        let action1 = "action1";

        let err = insert(state.db(), action1, None, Some(-1)).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(err.msg, format!("Invalid category_id '-1'"));
    }
}
