use sqlx::SqlitePool;
use crate::{ errors, model };

/// Insert a new reward into the database
/// 
/// - error on user not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***value*** - value of the reward
/// - ***user_id*** - id of the user
/// 
/// #### Returns
/// - ***id*** - id of the reward
pub async fn insert(db: &SqlitePool, value: i64, user_id: i64) -> errors::Result<i64>
{
    super::user::fetch_by_id(db, user_id).await?;

    let result = sqlx::query(r#"INSERT INTO reward (value, user_id) VALUES (?, ?)"#)
        .bind(value).bind(user_id).execute(db).await;
    match result {
        Ok(query) => Ok(query.last_insert_rowid()),
        Err(e) => {
            let msg = format!("Error inserting reward '{value}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}

/// Get a reward by ID from the database
/// 
/// - error on reward not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***id*** - id of the reward
/// 
/// #### Returns
/// - ***reward*** - the reward entry
pub async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::Reward>
{
    let result = sqlx::query_as::<_, model::Reward>(r#"SELECT * FROM reward WHERE id = ?"#)
        .bind(id).fetch_one(db).await;
    match result {
        Ok(reward) => Ok(reward),
        Err(e) => {
            if errors::Error::is_sqlx_not_found(&e) {
                let msg = format!("Reward with id '{id}' was not found");
                log::warn!("{msg}");
                return Err(errors::Error::from_sqlx(e, &msg));
            } 
            let msg = format!("Error fetching reward with id '{id}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}

/// Get all rewards from the database for the given user
/// 
/// - error on user not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***user_id*** - id of the user
/// 
/// #### Returns
/// - ***rewards*** - the rewards entries
pub async fn fetch_by_user_id(db: &SqlitePool, user_id: i64) -> errors::Result<Vec<model::Reward>>
{
    super::user::fetch_by_id(db, user_id).await?;

    let result = sqlx::query_as::<_, model::Reward>(r#"SELECT * FROM reward WHERE user_id = ?"#)
        .bind(user_id).fetch_all(db).await;
    match result {
        Ok(rewards) => Ok(rewards),
        Err(e) => {
            let msg = format!("Error fetching rewards");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}

/// Get all rewards from the database
/// 
/// - error on user not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// 
/// #### Returns
/// - ***rewards*** - the rewards entries
pub async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<model::Reward>>
{
    let result = sqlx::query_as::<_, model::Reward>(r#"SELECT * FROM reward"#)
        .fetch_all(db).await;
    match result {
        Ok(rewards) => Ok(rewards),
        Err(e) => {
            let msg = format!("Error fetching rewards");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}

/// Update a reward in the database
/// 
/// - only the value field can be updated
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***id*** - id of the reward
/// - ***value*** - value of the reward
pub async fn update_by_id(db: &SqlitePool, id: i64, value: i64) -> errors::Result<()>
{
    let reward = fetch_by_id(db, id).await?;

    // Update reward value if changed
    if reward.value != value {
        let result = sqlx::query(r#"UPDATE reward SET value = ? WHERE id = ?"#)
            .bind(&value).bind(&id).execute(db).await;
        if let Err(e) = result {
            let msg = format!("Error updating reward with id '{id}'");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
    Ok(())
}

/// Delete a reward in the database
/// 
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***id*** - id of the reward
pub async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()>
{
    let result = sqlx::query(r#"DELETE from reward WHERE id = ?"#).bind(id).execute(db).await;
    if let Err(e) = result {
        let msg = format!("Error deleting reward with id '{id}'");
        log::error!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
    }
    Ok(())
}

#[cfg(test)]
mod tests
{
    use super::*;
    use crate::{db, state};
    use axum::http::StatusCode;

    #[tokio::test]
    async fn test_delete_success()
    {
        let state = state::test().await;
        let reward1 = 10;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let id = insert(state.db(), reward1, user_id).await.unwrap();

        delete_by_id(state.db(), id).await.unwrap();

        let err = fetch_by_id(state.db(), id).await.unwrap_err();
        assert_eq!(err.kind, errors::ErrorKind::NotFound);
    }

    #[tokio::test]
    async fn test_update_success()
    {
        let state = state::test().await;
        let reward1 = 10;
        let reward2 = 20;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let id = insert(state.db(), reward1, user_id).await.unwrap();

        update_by_id(state.db(), id, reward2).await.unwrap();

        let reward = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(reward.id, 1);
        assert_eq!(reward.value, reward2);
        assert_eq!(reward.user_id, user_id);
    }

    #[tokio::test]
    async fn test_update_failure_not_found()
    {
        let state = state::test().await;

        let err = update_by_id(state.db(), -1, 10).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Reward with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_insert_success()
    {
        let state = state::test().await;
        let reward1 = 10;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();

        // Insert a new reward
        let id = insert(state.db(), reward1, user_id).await.unwrap();
        assert_eq!(id, 1);

        let reward = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(reward.id, 1);
        assert_eq!(reward.value, reward1);
        assert_eq!(reward.user_id, user_id);
        assert!(reward.created_at <= chrono::Local::now());
        assert!(reward.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_insert_failure_user_not_found()
    {
        let state = state::test().await;
        let reward1 = 10;
        let user_id = 10;

        let err = insert(state.db(), reward1, user_id).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("User with id '{user_id}' was not found"));
    }

    #[tokio::test]
    async fn test_fetch_all_success()
    {
        let state = state::test().await;
        let reward1 = 10;
        let reward2 = 20;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();

        insert(state.db(), reward1, user_id).await.unwrap();
        insert(state.db(), reward2, user_id).await.unwrap();
        let rewards = fetch_by_user_id(state.db(), user_id).await.unwrap();
        assert_eq!(rewards.len(), 2);

        assert_eq!(rewards[0].id, 1);
        assert_eq!(rewards[0].value, reward1);
        assert_eq!(rewards[0].user_id, user_id);
        assert!(rewards[0].created_at <= chrono::Local::now());
        assert!(rewards[0].updated_at <= chrono::Local::now());

        assert_eq!(rewards[1].id, 2);
        assert_eq!(rewards[1].value, reward2);
        assert_eq!(rewards[1].user_id, user_id);
        assert!(rewards[1].created_at <= chrono::Local::now());
        assert!(rewards[1].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_fetch_by_user_id_failure_not_found()
    {
        let state = state::test().await;

        let err = fetch_by_user_id(state.db(), -1).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("User with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_fetch_by_id_failure_not_found()
    {
        let state = state::test().await;

        let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Reward with id '-1' was not found"));
    }
}