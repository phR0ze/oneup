use sqlx::SqlitePool;
use crate::{ errors, model };

/// Insert a new points entry into the database
/// 
/// - error on user not found
/// - error on action not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***value*** - points value
/// - ***user_id*** - owner of the points
/// - ***action_id*** - action of the points
/// 
/// #### Returns
/// - ***id*** - id of the points
pub async fn insert(db: &SqlitePool, value: i64, user_id: i64, action_id: i64)
    -> errors::Result<i64>
{
    super::user::fetch_by_id(db, user_id).await?;
    super::action::fetch_by_id(db, action_id).await?;

    let result = sqlx::query(r#"INSERT INTO point (value, user_id, action_id) VALUES (?, ?, ?)"#)
        .bind(value).bind(user_id).bind(action_id).execute(db).await;
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
/// 
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***id*** - id of the points
/// 
/// #### Returns
/// - ***points*** - points entry
pub async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::Points>
{
    let result = sqlx::query_as::<_, model::Points>(r#"SELECT * FROM point WHERE id = ?"#)
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

/// Sum all points for the given user and or action
/// 
/// - Start defines the oldest date to include in the sum
/// - End defines the newest date to include in the sum
/// 
/// - error on user not found if user_id is provided
/// - error on action not found if action_id is provided
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***filter*** supports filter params:
///   - ***user_id=***, ***action_id=***, ***start_date=***, ***end_date=***
pub async fn sum_by_filter(db: &SqlitePool, filter: model::Filter) -> errors::Result<i64>
{
    let where_clause = filter.to_points_where_clause(db).await?;
    let query_str = format!("SELECT SUM(value) as total FROM point {where_clause}");
    let mut query = sqlx::query_as::<_, (Option<i64>,)>(&query_str);
    
    if let Some(user_id) = filter.user_id {
        query = query.bind(user_id);
    }
    if let Some(action_id) = filter.action_id {
        query = query.bind(action_id);
    }
    if let Some((start, end)) = filter.date_range() {
        query = query.bind(start).bind(end);
    }

    let result = query.fetch_one(db).await;
    match result {
        Ok((total,)) => Ok(total.unwrap_or(0)),
        Err(e) => {
            let msg = format!("Error summing points");
            log::error!("{msg}");
            return Err(errors::Error::from_sqlx(e, &msg));
        }
    }
}


/// Get all points for the given user and or action
/// 
/// - Start defines the oldest date to include in the sum
/// - End defines the newest date to include in the sum
/// 
/// - error on user not found if user_id is provided
/// - error on action not found if action_id is provided
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***filter*** supports filter params:
///   - ***user_id=***, ***action_id=***, ***start_date=***, ***end_date=***
pub async fn fetch_by_filter(db: &SqlitePool, filter: model::Filter)
    -> errors::Result<Vec<model::Points>>
{
    let where_clause = filter.to_points_where_clause(db).await?;
    let query_str = format!("SELECT * FROM point {where_clause} ORDER BY created_at");
    let mut query = sqlx::query_as::<_, model::Points>(&query_str);
    
    if let Some(user_id) = filter.user_id {
        query = query.bind(user_id);
    }
    if let Some(action_id) = filter.action_id {
        query = query.bind(action_id);
    }
    if let Some((start, end)) = filter.date_range() {
        query = query.bind(start).bind(end);
    }

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
pub async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<model::Points>>
{
    let result = sqlx::query_as::<_, model::Points>(r#"SELECT * FROM point"#)
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
pub async fn update_by_id(db: &SqlitePool, id: i64, value: i64) -> errors::Result<()>
{
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
pub async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()>
{
    let result = sqlx::query(r#"DELETE from point WHERE id = ?"#).bind(id).execute(db).await;
    if let Err(e) = result {
        let msg = format!("Error deleting points with id '{id}'");
        log::error!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
    }
    Ok(())
}

#[cfg(test)]
mod tests
{
    use super::*;
    use crate::{db, model, state};
    use axum::http::StatusCode;

    #[tokio::test]
    async fn test_delete_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();
        let id = insert(state.db(), points1, user_id, action_id).await.unwrap();

        delete_by_id(state.db(), id).await.unwrap();

        let err = fetch_by_id(state.db(), id).await.unwrap_err();
        assert_eq!(err.kind, errors::ErrorKind::NotFound);
    }

    #[tokio::test]
    async fn test_update_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();
        let id = insert(state.db(), points1, user_id, action_id).await.unwrap();

        update_by_id(state.db(), id, points2).await.unwrap();

        let points = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(points.id, 1);
        assert_eq!(points.value, points2);
        assert_eq!(points.user_id, user_id);
    }

    #[tokio::test]
    async fn test_update_failure_not_found()
    {
        let state = state::test().await;

        let err = update_by_id(state.db(), -1, 10).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Points with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_sum_by_filter_by_date_range_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let points3 = 30;
        let user = "user1";
        let email = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user, email).await.unwrap();
        let action = "action1";
        let action_id = db::action::insert(state.db(), action, None, None).await.unwrap();

        // Insert points with delays to ensure different timestamps
        insert(state.db(), points1, user_id, action_id).await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        
        let start = chrono::Local::now();
        insert(state.db(), points2, user_id, action_id).await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        insert(state.db(), points3, user_id, action_id).await.unwrap();
        let end = chrono::Local::now();

        // Query with date range that should only include points2 and points3
        let sum = sum_by_filter(state.db(), model::Filter::default()
            .with_date_range(start, end)).await.unwrap();
        assert_eq!(sum, points2 + points3);
    }

    #[tokio::test]
    async fn test_sum_by_filter_by_user_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let user_id_1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        let user_id_2 = db::user::insert(state.db(), user2, email2).await.unwrap();
        let action = "action1";
        let action_id = db::action::insert(state.db(), action, None, None).await.unwrap();

        insert(state.db(), points1, user_id_1, action_id).await.unwrap();
        insert(state.db(), points2, user_id_2, action_id).await.unwrap();

        let sum = sum_by_filter(state.db(), model::Filter::default()
            .with_user_id(user_id_1)).await.unwrap();
        assert_eq!(sum, points1);
    }

    #[tokio::test]
    async fn test_sum_by_filter_by_action_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let user = "user1";
        let email = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user, email).await.unwrap();
        let action1 = "action1";
        let action2 = "action2";
        let action_id_1 = db::action::insert(state.db(), action1, None, None).await.unwrap();
        let action_id_2 = db::action::insert(state.db(), action2, None, None).await.unwrap();

        insert(state.db(), points1, user_id, action_id_1).await.unwrap();
        insert(state.db(), points2, user_id, action_id_2).await.unwrap();

        let sum = sum_by_filter(state.db(), model::Filter::default()
            .with_action_id(action_id_1)).await.unwrap();
        assert_eq!(sum, points1);
    }

    #[tokio::test]
    async fn test_sum_by_filter_no_results()
    {
        let state = state::test().await;
        let points = 10;
        let user = "user1";
        let email = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user, email).await.unwrap();
        let action = "action1";
        let action_id = db::action::insert(state.db(), action, None, None).await.unwrap();
        
        insert(state.db(), points, user_id, action_id).await.unwrap();

        // Query with future date range
        let future = chrono::Local::now() + chrono::Duration::hours(24);
        let sum = sum_by_filter(state.db(), model::Filter::default()
            .with_date_range(future, future)).await.unwrap();
        assert_eq!(sum, 0);
    }

    #[tokio::test]
    async fn test_sum_by_filter_invalid_filter()
    {
        let state = state::test().await;
        let err = sum_by_filter(state.db(), model::Filter::default()).await.unwrap_err();
        assert_eq!(err.to_http().status, StatusCode::UNPROCESSABLE_ENTITY);
    }

    #[tokio::test]
    async fn test_fetch_by_filter_by_date_range_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let points3 = 30;
        let user = "user1";
        let email = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user, email).await.unwrap();
        let action = "action1";
        let action_id = db::action::insert(state.db(), action, None, None).await.unwrap();

        // Insert points with delays to ensure different timestamps
        insert(state.db(), points1, user_id, action_id).await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        
        let start = chrono::Local::now();
        insert(state.db(), points2, user_id, action_id).await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        insert(state.db(), points3, user_id, action_id).await.unwrap();
        let end = chrono::Local::now();

        // Query with date range that should only include points2 and points3
        let points = fetch_by_filter(state.db(), model::Filter::default()
            .with_date_range(start, end)).await.unwrap();
        assert_eq!(points.len(), 2);

        assert_eq!(points[0].id, 2);
        assert_eq!(points[0].value, points2);
        assert!(points[0].created_at >= start);
        assert!(points[0].created_at <= end);

        assert_eq!(points[1].id, 3);
        assert_eq!(points[1].value, points3); 
        assert!(points[1].created_at >= start);
        assert!(points[1].created_at <= end);
    }

    #[tokio::test]
    async fn test_fetch_by_filter_by_date_range_no_results()
    {
        let state = state::test().await;
        let points = 10;
        let user = "user1";
        let email = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user, email).await.unwrap();
        let action = "action1";
        let action_id = db::action::insert(state.db(), action, None, None).await.unwrap();
        
        insert(state.db(), points, user_id, action_id).await.unwrap();

        // Query with future date range
        let future = chrono::Local::now() + chrono::Duration::hours(24);
        let points = fetch_by_filter(state.db(), model::Filter::default()
            .with_date_range(future, future)).await.unwrap();
        assert_eq!(points.len(), 0);
    }

    #[tokio::test]
    async fn test_fetch_by_filter_by_user_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id_1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        let user2 = "user2";
        let email2 = "user2@foo.com";
        let user_id_2 = db::user::insert(state.db(), user2, email2).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();

        insert(state.db(), points1, user_id_1, action_id).await.unwrap();
        insert(state.db(), points2, user_id_2, action_id).await.unwrap();
        let points = fetch_by_filter(state.db(), model::Filter::default()
            .with_user_id(user_id_1)).await.unwrap();
        assert_eq!(points.len(), 1);

        assert_eq!(points[0].id, 1);
        assert_eq!(points[0].value, points1);
        assert_eq!(points[0].user_id, user_id_1);
        assert_eq!(points[0].action_id, action_id);
        assert!(points[0].created_at <= chrono::Local::now());
        assert!(points[0].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_fetch_by_filter_by_action_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id_1 = db::action::insert(state.db(), action1, None, None).await.unwrap();
        let action2 = "action2";
        let action_id_2 = db::action::insert(state.db(), action2, None, None).await.unwrap();

        insert(state.db(), points1, user_id, action_id_1).await.unwrap();
        insert(state.db(), points2, user_id, action_id_2).await.unwrap();
        let points = fetch_by_filter(state.db(), model::Filter::default()
            .with_action_id(action_id_1)).await.unwrap();
        assert_eq!(points.len(), 1);

        assert_eq!(points[0].id, 1);
        assert_eq!(points[0].value, points1);
        assert_eq!(points[0].user_id, user_id);
        assert_eq!(points[0].action_id, action_id_1);
        assert!(points[0].created_at <= chrono::Local::now());
        assert!(points[0].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_fetch_by_filter_by_user_and_action_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id_1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        let user2 = "user2";
        let email2 = "user2@foo.com";
        let user_id_2 = db::user::insert(state.db(), user2, email2).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();
        let action2 = "action2";
        let action_id_2 = db::action::insert(state.db(), action2, None, None).await.unwrap();

        insert(state.db(), points1, user_id_1, action_id).await.unwrap();
        insert(state.db(), points2, user_id_2, action_id).await.unwrap();
        let points = fetch_by_filter(state.db(), model::Filter::default()
            .with_user_id(user_id_1)
            .with_action_id(action_id_2)).await.unwrap();
        assert_eq!(points.len(), 0);
    }

    #[tokio::test]
    async fn test_fetch_by_user_id_failure_not_found()
    {
        let state = state::test().await;

        let err = fetch_by_filter(state.db(), model::Filter::default()
            .with_user_id(-1)).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("User with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_fetch_by_action_id_failure_not_found()
    {
        let state = state::test().await;

        let err = fetch_by_filter(state.db(), model::Filter::default()
            .with_action_id(-1)).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Action with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_fetch_by_id_failure_not_found()
    {
        let state = state::test().await;

        let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Points with id '-1' was not found"));
    }

    #[tokio::test]
    async fn test_insert_failure_action_not_found()
    {
        let state = state::test().await;
        let points1 = 10;
        let action_id = 2; // 1 always exists i.e. Unspecified

        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();

        let err = insert(state.db(), points1, user_id, action_id).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("Action with id '2' was not found"));
    }

    #[tokio::test]
    async fn test_insert_failure_user_not_found()
    {
        let state = state::test().await;
        let points1 = 10;
        let user_id = 10;

        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();

        let err = insert(state.db(), points1, user_id, action_id).await.unwrap_err().to_http();
        assert_eq!(err.status, StatusCode::NOT_FOUND);
        assert_eq!(err.msg, format!("User with id '{user_id}' was not found"));
    }

    #[tokio::test]
    async fn test_insert_success()
    {
        let state = state::test().await;
        let points1 = 10;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();

        // Insert a new points
        let id = insert(state.db(), points1, user_id, action_id).await.unwrap();
        assert_eq!(id, 1);
        let points = fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(points.id, 1);
        assert_eq!(points.value, points1);
        assert_eq!(points.user_id, user_id);
        assert_eq!(points.action_id, action_id);
        assert!(points.created_at <= chrono::Local::now());
        assert!(points.updated_at <= chrono::Local::now());
    }
}