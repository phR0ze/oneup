use std::sync::Arc;
use axum::{
    extract::{Path, Query, State}, http::StatusCode, response::IntoResponse, Extension
};
use crate::{db, state, model, routes::Json, errors::Error};

/// Create a new user
/// 
/// - POST handler for `/users`
pub async fn create(State(state): State<Arc<state::State>>,
    Extension(_): Extension<model::JwtClaims>, Json(user): Json<model::CreateUser>) ->
    Result<impl IntoResponse, Error>
{
    let id = db::user::insert(state.db(), &user.username, &user.email).await?;
    let user = db::user::fetch_by_id(state.db(), id).await?;

    Ok((StatusCode::CREATED, Json(serde_json::json!(user))))
}

/// Get all users via ***/users***
///
/// - Users are returned sorted alphabetically by username by default
/// 
/// #### Parameters
/// - ***filter*** - supports ***role_name*** and ***role_id***
///   - e.g. `/users?role_name=name&role_id=id`
///
/// #### Returns
/// - ***users*** - the matching user entries
pub async fn get(State(state): State<Arc<state::State>>,
    Query(filter): Query<model::Filter>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::user::fetch_all(state.db(), filter).await?))
}

/// Get roles for specific user by id
/// 
/// - GET handler for `/users/{id}/roles`
pub async fn get_roles(State(state): State<Arc<state::State>>,
    Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::user::roles(state.db(), id).await?))
}


/// Get specific user by id
/// 
/// - GET handler for `/users/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
    Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::user::fetch_by_id(state.db(), id).await?))
}

/// Update specific user by id
/// 
/// - PUT handler for `/users/{id}`
pub async fn update_by_id(State(state): State<Arc<state::State>>,
    Path(id): Path<i64>, Json(user): Json<model::UpdateUser>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::user::update_by_id(state.db(), id, user.username.as_deref(),
        user.email.as_deref()).await?))
}

/// Delete specific user by id
/// 
/// - DELETE handler for `/users/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
    Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
    Ok(Json(db::user::delete_by_id(state.db(), id).await?))
}

#[cfg(test)]
mod tests
{
    use super::{*, super::tests::login_as_admin};
    use axum::{
        body::Body,
        http::{header, Method, Request, Response, StatusCode}
    };
    use http_body_util::BodyExt;
    use tower::ServiceExt;
    use crate::{errors, routes, state};

    #[tokio::test]
    async fn test_create_fails_without_login() 
    {
        let state = state::test().await;

        let req = Request::builder().method(Method::POST)
            .uri("/api/users")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::CreateUser { username: "user1".to_string(), email: "user1@foo.com".to_string() }
            )).unwrap())).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::FORBIDDEN);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "Access denied: user not logged in");
    }

    #[tokio::test]
    async fn test_update_fails_without_login() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";

        // Create user
        let id = db::user::insert(state.db(), user1, email1).await.unwrap();

        let req = Request::builder().method(Method::PUT)
            .uri(format!("/api/users/{}", id))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::UpdateUser {
                    username: Some("user2".to_string()), email: Some("user2@foo.com".to_string())
                })
            ).unwrap())).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::FORBIDDEN);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "Access denied: user not logged in");
    }

    #[tokio::test]
    async fn test_delete_fails_without_login() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";

        // Create user
        let id = db::user::insert(state.db(), user1, email1).await.unwrap();

        let req = Request::builder().method(Method::DELETE)
            .uri(format!("/api/users/{}", id))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::FORBIDDEN);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "Access denied: user not logged in");
    }

    #[tokio::test]
    async fn test_delete_by_id() 
    {
        let state = state::test().await;
        let user1 = "user1"; 
        let email1 = "user1@foo.com";
        let id = db::user::insert(state.db(), user1, email1).await.unwrap();

        let (_, access_token) = login_as_admin(state.clone()).await;
        let req = Request::builder().method(Method::DELETE)
            .uri(format!("/api/users/{}", id))
            .header(header::CONTENT_TYPE, "application/json")
            .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
            .body(Body::empty()).unwrap();
        let res = routes::init(state.clone()).oneshot(req).await.unwrap();
        assert_eq!(res.status(), StatusCode::OK);

        // Now check that the user was deleted in the DB
        let err = db::user::fetch_by_id(state.db(), id).await.unwrap_err();
        assert_eq!(err.kind, errors::ErrorKind::NotFound);
    }

    #[tokio::test]
    async fn test_update_by_id() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";

        // Create user
        let id = db::user::insert(state.db(), user1, email1).await.unwrap();
        let user = db::user::fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(user.username, user1);

        // Now update user
        let (_, access_token) = login_as_admin(state.clone()).await;
        let req = Request::builder().method(Method::PUT)
            .uri(format!("/api/users/{}", id))
            .header(header::CONTENT_TYPE, "application/json")
            .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::UpdateUser {
                    username: Some(user2.to_string()), email: Some(email2.to_string())
                })
            ).unwrap())).unwrap();
        let res = routes::init(state.clone()).oneshot(req).await.unwrap();
        assert_eq!(res.status(), StatusCode::OK);

        // Now check that the user was updated in the DB
        let user = db::user::fetch_by_id(state.db(), id).await.unwrap();
        assert_eq!(user.username, user2);
    }
    #[tokio::test]
    async fn test_get_roles_success() {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let id = db::user::insert(state.db(), user1, email1).await.unwrap();

        // Assign some roles to the user
        let role_id = db::role::insert(state.db(), "user").await.unwrap();
        let role_ids = vec![1, role_id]; // Admin and User roles
        db::user::assign_roles(state.db(), id, role_ids).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri(format!("/api/users/{}/roles", id))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let roles: Vec<model::Role> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(roles.len(), 2);

        assert_eq!(roles[0].id, 1);
        assert_eq!(roles[0].name, "admin");
        assert_eq!(roles[1].id, 2); 
        assert_eq!(roles[1].name, "user");
    }

    #[tokio::test]
    async fn test_get_roles_empty() {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let id = db::user::insert(state.db(), user1, email1).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri(format!("/api/users/{}/roles", id))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let roles: Vec<model::Role> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(roles.len(), 0);
    }

    #[tokio::test]
    async fn test_get_roles_not_found() {
        let state = state::test().await;
        let non_existent_id = 999;

        let req = Request::builder().method(Method::GET)
            .uri(format!("/api/users/{}/roles", non_existent_id))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::NOT_FOUND);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let error: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert!(error.message.contains("not found"));
    }

    #[tokio::test]
    async fn test_get_users_filter_role_id() {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2"; 
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let id1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        db::user::insert(state.db(), user2, email2).await.unwrap();
        db::user::assign_roles(state.db(), id1, vec![1]).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri("/api/users?role_id=1")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let users: Vec<model::User> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(users.len(), 2); // admin and user1
        assert!(users.iter().any(|u| u.username == "admin"));
        assert!(users.iter().any(|u| u.username == user1));
    }

    #[tokio::test]
    async fn test_get_users_filter_role_name() {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let id1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        db::user::insert(state.db(), user2, email2).await.unwrap();
        let role_id = db::role::insert(state.db(), "user").await.unwrap();
        db::user::assign_roles(state.db(), id1, vec![role_id]).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri("/api/users?role_name=user")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let users: Vec<model::User> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(users.len(), 1);
        assert_eq!(users[0].id, id1);
        assert_eq!(users[0].username, user1);
    }

    #[tokio::test]
    async fn test_get_users_filter_role_id_ne() {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let id1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        let id2 = db::user::insert(state.db(), user2, email2).await.unwrap();

        let role_id = db::role::insert(state.db(), "user").await.unwrap();
        db::user::assign_roles(state.db(), id1, vec![role_id]).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri("/api/users?role_id_ne=1")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let users: Vec<model::User> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(users.len(), 2);

        assert_eq!(users[0].id, id1);
        assert_eq!(users[0].username, user1);

        assert_eq!(users[1].id, id2);
        assert_eq!(users[1].username, user2);
    }

    #[tokio::test]
    async fn test_get_users_filter_role_name_ne() {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let id1 = db::user::insert(state.db(), user1, email1).await.unwrap();
        let id2 = db::user::insert(state.db(), user2, email2).await.unwrap();

        let role_id = db::role::insert(state.db(), "user").await.unwrap();
        db::user::assign_roles(state.db(), id2, vec![role_id]).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri("/api/users?role_name_ne=user")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let users: Vec<model::User> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(users.len(), 2);

        assert_eq!(users[0].id, 1);
        assert_eq!(users[0].username, "admin");

        assert_eq!(users[1].id, id1);
        assert_eq!(users[1].username, user1);
    }

    #[tokio::test]
    async fn test_get_users_success() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let user2 = "user2";
        let email1 = "user1@foo.com";
        let email2 = "user2@foo.com";
        let id2 = db::user::insert(state.db(), user2, email2).await.unwrap();
        let id1 = db::user::insert(state.db(), user1, email1).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri("/api/users")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let users: Vec<model::User> = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(users.len(), 3);

        assert_eq!(users[0].username, "admin");
        assert_eq!(users[0].id, 1);
        assert!(users[0].created_at <= chrono::Local::now());
        assert!(users[0].updated_at <= chrono::Local::now());

        assert_eq!(users[1].username, user1);
        assert_eq!(users[1].id, id1);
        assert!(users[1].created_at <= chrono::Local::now());
        assert!(users[1].updated_at <= chrono::Local::now());

        assert_eq!(users[2].username, user2);
        assert_eq!(users[2].id, id2);
        assert!(users[2].created_at <= chrono::Local::now());
        assert!(users[2].updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_get_by_id_success() 
    {
        let state = state::test().await;
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let id = db::user::insert(state.db(), user1, email1).await.unwrap();

        let req = Request::builder().method(Method::GET)
            .uri(format!("/api/users/{}", id))
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::empty()).unwrap();
        let res = routes::init(state).oneshot(req).await.unwrap();

        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let user: model::User = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(user.username, user1);
        assert_eq!(user.id, id);
        assert!(user.created_at <= chrono::Local::now());
        assert!(user.updated_at <= chrono::Local::now());
    }

    #[tokio::test]
    async fn test_create_success() 
    {
        let user1 = "user1";
        let email1 = "user1@foo.com";
        let state = state::test().await;

        let res = create_user_req(state.clone(), user1, email1).await;

        // Validate the response
        assert_eq!(res.status(), StatusCode::CREATED);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let user: model::User = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(user.id, 2);
        assert_eq!(user.username, user1);
        assert!(user.created_at <= chrono::Local::now());
        assert!(user.updated_at <= chrono::Local::now());

        // Check that the new user doesn't have the admin role because this is the second user
        let roles = db::user::roles(state.db(), user.id).await.unwrap();
        assert!(!roles.iter().any(|role| role.name == "admin"));
    }

    #[tokio::test]
    async fn test_create_failure_duplicate() 
    {
        let user1 = "test1";
        let email1 = "user1@foo.com";
        let state = state::test().await;

        // Create the user for the first time
        db::user::insert(state.db(), user1, email1).await.unwrap();

        // Now attempt to create the same user again
        let res = create_user_req(state, user1, email1).await;
        
        assert_eq!(res.status(), StatusCode::CONFLICT);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "User 'test1' already exists");
    }

    #[tokio::test]
    async fn test_create_failure_no_name_given() 
    {
        let state = state::test().await;

        // Attempt to create a user with no name
        let (_, access_token) = login_as_admin(state.clone()).await;
        let req = Request::builder().method(Method::POST)
            .uri("/api/users")
            .header(header::CONTENT_TYPE, "application/json")
            .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::CreateUser { username: "".to_string(), email: "".to_string() }
            )).unwrap())).unwrap();

        // Spin up the server and send the request
        let res = routes::init(state).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "Username must contain only alpha numeric, underscore or dash characters and be at least 5 characters long");
    }

    #[tokio::test]
    async fn test_create_failure_no_body() 
    {
        let state = state::test().await;

        let (_, access_token) = login_as_admin(state.clone()).await;
        let req = Request::builder().method(Method::POST)
            .uri("/api/users")
            .header(header::CONTENT_TYPE, "application/json")
            .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
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

        let (_, access_token) = login_as_admin(state.clone()).await;
        let req = Request::builder().method(Method::POST)
            .uri("/api/users")
            .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
            .body(Body::empty()).unwrap();

        let res = routes::init(state.clone()).oneshot(req).await.unwrap();

        // Validate the response
        assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
    }

    // Helper function to create a user request
    async fn create_user_req(state: Arc::<state::State>, name: &str, email: &str) -> Response<Body>
    {
        let (_, access_token) = login_as_admin(state.clone()).await;
        let req = Request::builder().method(Method::POST)
            .uri("/api/users")
            .header(header::CONTENT_TYPE, "application/json")
            .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::CreateUser { username: name.to_string(), email: email.to_string() }))
            .unwrap())).unwrap();

        routes::init(state).oneshot(req).await.unwrap()
    }
}