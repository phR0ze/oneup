use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, State}, response::IntoResponse};
use crate::{state, model, routes::Json, errors::Error};

/// Create a new user
/// 
/// - The first user created will automatically be assigned the admin role
/// - POST handler for `/users`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(user): Json<model::CreateUser>) -> Result<impl IntoResponse, Error>
{
  // Check if we should assign the admin role to this user
  let admin = !model::user::any(state.db()).await?;

  // Create the user
  let id = model::user::insert(state.db(), &user.name, &user.email).await?;
  let user = model::user::fetch_by_id(state.db(), id).await?;

  // Now add the admin role if needed
  if admin {
    let admin_role_id = 1; // is auto populated and can't be be deleted
    model::user::assign_role(state.db(), user.id, admin_role_id).await?;
  }

  Ok((StatusCode::CREATED, Json(serde_json::json!(user))))
}

/// Get all users
/// 
/// - GET handler for `/users`
pub async fn get_all(State(state): State<Arc<state::State>>)
  -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::fetch_all(state.db()).await?))
}

/// Get specific user by id
/// 
/// - GET handler for `/users/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::fetch_by_id(state.db(), id).await?))
}

/// Update specific user by id
/// 
/// - PUT handler for `/users/{id}`
pub async fn update_by_id(State(state): State<Arc<state::State>>,
  Json(user): Json<model::UpdateUser>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::update_by_id(state.db(), user.id, user.name.as_deref(),
    user.email.as_deref()).await?))
}

/// Delete specific user by id
/// 
/// - DELETE handler for `/users/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::delete_by_id(state.db(), id).await?))
}

#[cfg(test)]
mod tests {
  use super::*;
  use axum::{
    body::Body,
    http::{ Response, Request, Method, StatusCode}
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;
  use crate::{errors, routes, state};

  #[tokio::test]
  async fn test_delete_by_id() {
    let state = state::test().await;
    let user1 = "user1"; 
    let email1 = "user1@foo.com";
    let id = model::user::insert(state.db(), user1, email1).await.unwrap();

    let req = Request::builder().method(Method::DELETE)
      .uri(format!("/users/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the user was deleted in the DB
    let err = model::user::fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_by_id() {
    let state = state::test().await;
    let user1 = "user1";
    let user2 = "user2";
    let email1 = "user1@foo.com";
    let email2 = "user2@foo.com";

    // Create user
    let id = model::user::insert(state.db(), user1, email1).await.unwrap();
    let user = model::user::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(user.name, user1);

    // Now update user
    let req = Request::builder().method(Method::PUT)
      .uri(format!("/users/{}", id))
      .header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
          model::UpdateUser {
            id: id, name: Some(user2.to_string()), email: Some(email2.to_string())
          })
      ).unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the user was updated in the DB
    let user = model::user::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(user.name, user2);
  }

  #[tokio::test]
  async fn test_get_all_users_success() {
    let state = state::test().await;
    let user1 = "user1";
    let user2 = "user2";
    let email1 = "user1@foo.com";
    let email2 = "user2@foo.com";
    let id2 = model::user::insert(state.db(), user2, email2).await.unwrap();
    let id1 = model::user::insert(state.db(), user1, email1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri("/users").header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let users: Vec<model::User> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(users.len(), 2);
    assert_eq!(users[0].name, user1);
    assert_eq!(users[0].id, id1);
    assert!(users[0].created_at <= chrono::Local::now());
    assert!(users[0].updated_at <= chrono::Local::now());
    assert_eq!(users[1].name, user2);
    assert_eq!(users[1].id, id2);
    assert!(users[1].created_at <= chrono::Local::now());
    assert!(users[1].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_get_by_id_success() {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let id = model::user::insert(state.db(), user1, email1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/users/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let user: model::User = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(user.name, user1);
    assert_eq!(user.id, 1);
    assert!(user.created_at <= chrono::Local::now());
    assert!(user.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_success() {
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let state = state::test().await;
    let res = create_user_req(state.clone(), user1, email1).await;

    // Validate the response
    assert_eq!(res.status(), StatusCode::CREATED);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let user: model::User = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(user.id, 1);
    assert_eq!(user.name, user1);
    assert!(user.created_at <= chrono::Local::now());
    assert!(user.updated_at <= chrono::Local::now());

    // Check that the new user is an admin
    assert_eq!(model::user::is_admin(state.db(), user.id).await.unwrap(), true);
  }

  #[tokio::test]
  async fn test_create_failure_duplicate() {
    let user1 = "test1";
    let email1 = "user1@foo.com";
    let state = state::test().await;

    // Create the user for the first time
    model::user::insert(state.db(), user1, email1).await.unwrap();

    // Now attempt to create the same user again
    let res = create_user_req(state, user1, email1).await;
    
    assert_eq!(res.status(), StatusCode::CONFLICT);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "User 'test1' already exists");
  }

  #[tokio::test]
  async fn test_create_failure_no_name_given() {
    let state = state::test().await;

    // Attempt to create a user with no name
    let req = Request::builder().method(Method::POST)
      .uri("/users").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateUser { name: "".to_string(), email: "".to_string() }
      )).unwrap())).unwrap();

    // Spin up the server and send the request
    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "User name value is required");
  }

  #[tokio::test]
  async fn test_create_failure_no_body() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/users") .header("content-type", "application/json")
      .body(Body::empty()).unwrap();

    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::BAD_REQUEST);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Failed to parse the request body as JSON: EOF while parsing a value at line 1 column 0");
  }

  #[tokio::test]
  async fn test_create_failure_invalid_content_type() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/users").body(Body::empty()).unwrap();

    let res = routes::init(state.clone()).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    //let error = std::str::from_utf8(&bytes).unwrap();
    assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  }

  // Helper function to create a user request
  async fn create_user_req(state: Arc::<state::State>, name: &str, email: &str) -> Response<Body> {
    let req = Request::builder().method(Method::POST)
      .uri("/users").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateUser { name: name.to_string(), email: email.to_string() }))
      .unwrap())).unwrap();

    routes::init(state).oneshot(req).await.unwrap()
  }
}