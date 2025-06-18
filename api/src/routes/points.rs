use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, Query, State}, response::IntoResponse};
use crate::{db, state, model, routes::Json, errors::Error};

/// Create a new points
/// 
/// - POST handler for `/points`
pub async fn create(State(state): State<Arc<state::State>>,
    Json(points): Json<model::CreatePoints>) -> Result<impl IntoResponse, Error>
{
    let id = db::point::insert(state.db(), points.value, points.user_id, points.action_id).await?;
    let points = db::point::fetch_by_id(state.db(), id).await?;

    Ok((StatusCode::CREATED, Json(serde_json::json!(points))))
}

/// Get all points or filter by user id
/// 
/// - Supports ISO 8601 date time range
/// - GET handler for `/points`
/// - GET handler for `/points?user_id={id},action_id={cid},start_date={start_date},end_date={end_date}`
pub async fn get(State(state): State<Arc<state::State>>,
    Query(filter): Query<model::Filter>) -> Result<impl IntoResponse, Error>
{
    // Filter based on the given filter params
    if filter.any() {
        return Ok(Json(db::point::fetch_by_filter(state.db(), filter).await?));
    }

    // Fetch all points if no filter is provided
    Ok(Json(db::point::fetch_all(state.db()).await?))
}

/// Get specific points by id
/// 
/// - GET handler for `/points/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
    Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::point::fetch_by_id(state.db(), id).await?))
}

/// Update specific points by id
/// 
/// - PUT handler for `/points/{id}`
pub async fn update_by_id(State(state): State<Arc<state::State>>,
    Path(id): Path<i64>, Json(points): Json<model::UpdatePoints>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::point::update_by_id(state.db(), id, points.value).await?))
}

/// Delete specific points by id
/// 
/// - DELETE handler for `/points/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
    Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::point::delete_by_id(state.db(), id).await?))
}

#[cfg(test)]
mod tests
{
    use super::*;
    use axum::{
        body::Body,
        http::{header, Request, Method, StatusCode}
    };
    use http_body_util::BodyExt;
    use tower::ServiceExt;
    use crate::{errors, routes, state};

    #[tokio::test]
    async fn test_delete_by_id() 
    {
        let state = state::test().await;
        let points1 = 10;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();
        let id = db::point::insert(state.db(), points1, user_id, action_id).await.unwrap();

        let req = Request::builder().method(Method::DELETE)
            .uri(format!("/points/{id}"))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state.clone()).oneshot(req).await.unwrap();
        assert_eq!(res.status(), StatusCode::OK);

        // Now check that the points was deleted in the DB
        let err = db::point::fetch_by_id(state.db(), id).await.unwrap_err();
        assert_eq!(err.kind, errors::ErrorKind::NotFound);
    }

    #[tokio::test]
    async fn test_update_by_id() 
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();

        // Create points
        let id = db::point::insert(state.db(), points1, user_id, action_id).await.unwrap();
        let points = db::point::fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(points.value, points1);

        // Now update points
        let req = Request::builder().method(Method::PUT)
            .uri(format!("/points/{id}"))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::UpdatePoints { value: points2, action_id: action_id })
            ).unwrap())).unwrap();
        let res = routes::init(state.clone()).oneshot(req).await.unwrap();
        assert_eq!(res.status(), StatusCode::OK);

        // Now check that the points was updated in the DB
        let points = db::point::fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(points.value, points2);
    }

    #[tokio::test]
    async fn test_get_all() 
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let points3 = 20;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let user_id_1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        let user_id_2 = db::user::insert(state.db(), user2, email2).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();
        db::point::insert(state.db(), points1, user_id_1, action_id).await.unwrap();
        db::point::insert(state.db(), points2, user_id_1, action_id).await.unwrap();
        db::point::insert(state.db(), points3, user_id_2, action_id).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri("/points")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let points: Vec<model::Points> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(points.len(), 3);

        assert_eq!(points[0].id, 1);
        assert_eq!(points[0].value, points1);
        assert_eq!(points[0].user_id, user_id_1);
        assert_eq!(points[0].action_id, action_id);
        assert!(points[0].created_at <= chrono::Local::now());
        assert!(points[0].updated_at <= chrono::Local::now());

        assert_eq!(points[1].id, 2);
        assert_eq!(points[1].value, points2);
        assert_eq!(points[1].user_id, user_id_1);
        assert_eq!(points[1].action_id, action_id);
        assert!(points[1].created_at <= chrono::Local::now());
        assert!(points[1].updated_at <= chrono::Local::now());

        assert_eq!(points[2].id, 3);
        assert_eq!(points[1].value, points3);
        assert_eq!(points[2].user_id, user_id_2);
        assert_eq!(points[2].action_id, action_id);
        assert!(points[2].created_at <= chrono::Local::now());
        assert!(points[2].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_get_by_date_range_success() {
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
        db::point::insert(state.db(), points1, user_id, action_id).await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        
        let start = chrono::Local::now();
        db::point::insert(state.db(), points2, user_id, action_id).await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        db::point::insert(state.db(), points3, user_id, action_id).await.unwrap();
        let end = chrono::Local::now();

        // Query with date range that should only include points2 and points3
        let req = Request::builder().method(Method::GET)
            .uri(format!("/points?start_date={}&end_date={}", 
                start.to_rfc3339(),
                end.to_rfc3339()))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state.clone()).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let points: Vec<model::Points> = serde_json::from_slice(&bytes).unwrap();
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
    async fn test_get_by_date_range_no_results() {
        let state = state::test().await;
        let points = 10;
        let user = "user1";
        let email = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user, email).await.unwrap();
        let action = "action1";
        let action_id = db::action::insert(state.db(), action, None, None).await.unwrap();
        
        db::point::insert(state.db(), points, user_id, action_id).await.unwrap();

        // Query with future date range
        let future = chrono::Local::now() + chrono::Duration::hours(24);
        let uri = format!("/points?start_date={}&end_date={}", 
            future.to_rfc3339(),
            future.to_rfc3339());
        log::debug!("Test URL: {}", uri);
        
        let req = Request::builder().method(Method::GET)
            .uri(uri)
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let points: Vec<model::Points> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(points.len(), 0);
    }

    #[tokio::test]
    async fn test_get_by_user_not_exists_failure() 
    {
        let state = state::test().await;

        let req = Request::builder().method(Method::GET)
            .uri(format!("/points?user_id=-1"))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::NOT_FOUND);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "User with id '-1' was not found");
    }

    #[tokio::test]
    async fn test_get_by_user_success() 
    {
        let state = state::test().await;
        let points1 = 10;
        let points2 = 20;
        let points3 = 20;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let user_id_1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        let user_id_2 = db::user::insert(state.db(), user2, email2).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();
        db::point::insert(state.db(), points1, user_id_1, action_id).await.unwrap();
        db::point::insert(state.db(), points2, user_id_1, action_id).await.unwrap();
        db::point::insert(state.db(), points3, user_id_2, action_id).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri(format!("/points?user_id={user_id_1}"))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let points: Vec<model::Points> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(points.len(), 2);

        assert_eq!(points[0].id, 1);
        assert_eq!(points[0].value, points1);
        assert_eq!(points[0].user_id, user_id_1);
        assert_eq!(points[0].action_id, action_id);
        assert!(points[0].created_at <= chrono::Local::now());
        assert!(points[0].updated_at <= chrono::Local::now());

        assert_eq!(points[1].id, 2);
        assert_eq!(points[1].value, points2);
        assert_eq!(points[1].user_id, user_id_1);
        assert_eq!(points[1].action_id, action_id);
        assert!(points[1].created_at <= chrono::Local::now());
        assert!(points[1].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_get_by_id_success() 
    {
        let state = state::test().await;
        let points1 = 10;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();
        let id = db::point::insert(state.db(), points1, user_id, action_id).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri(format!("/points/{}", id))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let points: model::Points = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(points.id, 1);
        assert_eq!(points.value, points1);
        assert_eq!(points.user_id, user_id);
        assert_eq!(points.action_id, action_id);
        assert!(points.created_at <= chrono::Local::now());
        assert!(points.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_create_success() 
    {
        let state = state::test().await;
        let points1 = 10;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let action1 = "action1";
        let action_id = db::action::insert(state.db(), action1, None, None).await.unwrap();

        let req = Request::builder().method(Method::POST)
            .uri("/points")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::CreatePoints { value: points1, user_id: user_id, action_id: action_id }))
            .unwrap())).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::CREATED);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let points: model::Points = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(points.id, 1);
        assert_eq!(points.value, points1);
        assert_eq!(points.user_id, user_id);
        assert_eq!(points.action_id, action_id);
        assert!(points.created_at <= chrono::Local::now());
        assert!(points.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_create_failure_no_body() 
    {
        let state = state::test().await;

        let req = Request::builder().method(Method::POST)
            .uri("/points")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();

        let res = routes::init(state).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::BAD_REQUEST);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "Failed to parse the request body as JSON: EOF while parsing a value at line 1 column 0");
    }

    #[tokio::test]
    async fn test_create_failure_invalid_content_type() 
    {
        let state = state::test().await;

        let req = Request::builder().method(Method::POST)
            .uri("/points").body(Body::empty()).unwrap();

        let res = routes::init(state.clone()).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
    }
}