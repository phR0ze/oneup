use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, State}, response::IntoResponse};
use crate::{state, model, routes::Json, errors::Error};

/// Get all users
/// 
/// - GET handler for `/users`
pub async fn get_all(State(state): State<Arc<state::State>>)
  -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::fetch_all(state.db()).await?))
}

/// Get user by id
/// 
/// - GET handler for `/users/{id}`
pub async fn get(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::fetch_by_id(state.db(), id).await?))
}

/// Create a new user
/// 
/// - POST handler for `/users`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(user): Json<model::CreateUser>) -> Result<impl IntoResponse, Error>
{
  let id = model::user::insert(state.db(), &user.name).await?;
  let user = model::user::fetch_by_id(state.db(), id).await?;

  Ok((StatusCode::CREATED, Json(serde_json::json!(user))))
}

/// Update user
/// 
/// - PUT handler for `/users/{user}`
pub async fn update(State(state): State<Arc<state::State>>,
  Json(user): Json<model::UpdateUser>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::update(state.db(), user.id, &user.name).await?))
}

/// Delete user
/// 
/// - DELETE handler for `/users/{id}`
pub async fn delete(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::user::delete(state.db(), id).await?))
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
  async fn test_delete_user() {
    let state = state::test().await;
    let user1 = "user1";
    let id = model::user::insert(state.db(), user1).await.unwrap();

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
  async fn test_update_user() {
    let state = state::test().await;
    let user1 = "user1";
    let user2 = "user2";

    // Create user
    let id = model::user::insert(state.db(), user1).await.unwrap();
    let user = model::user::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(user.name, user1);

    // Now update user
    let req = Request::builder().method(Method::PUT)
      .uri(format!("/users/{}", id))
      .header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
          model::UpdateUser { id: id, name: format!("{user2}") })
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
    let id2 = model::user::insert(state.db(), user2).await.unwrap();
    let id1 = model::user::insert(state.db(), user1).await.unwrap();

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
    assert_eq!(users[0].created_at, users[0].updated_at);
    assert_eq!(users[1].name, user2);
    assert_eq!(users[1].id, id2);
    assert!(users[1].created_at <= chrono::Local::now());
    assert!(users[1].updated_at <= chrono::Local::now());
    assert_eq!(users[1].created_at, users[1].updated_at);
  }

  #[tokio::test]
  async fn test_get_user_by_id_success() {
    let state = state::test().await;
    let user1 = "user1";
    let id = model::user::insert(state.db(), user1).await.unwrap();

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
  async fn test_create_user_success() {
    let user1 = "user1";
    let state = state::test().await;
    let res = create_user_req(state, user1).await;

    // Validate the response
    assert_eq!(res.status(), StatusCode::CREATED);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let user: model::User = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(user.id, 1);
    assert_eq!(user.name, user1);
    assert!(user.created_at <= chrono::Local::now());
    assert!(user.updated_at <= chrono::Local::now());
    assert_eq!(user.created_at, user.updated_at);
  }

  #[tokio::test]
  async fn test_create_user_failure_duplicate() {
    let user1 = "test1";
    let state = state::test().await;

    // Create the user for the first time
    model::user::insert(state.db(), user1).await.unwrap();

    // Now attempt to create the same user again
    let res = create_user_req(state, user1).await;
    assert_eq!(res.status(), StatusCode::CONFLICT);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "User 'test1' already exists");
  }

  #[tokio::test]
  async fn test_create_user_failure_no_name_given() {
    let state = state::test().await;

    // Attempt to create a user with no name
    let req = Request::builder().method(Method::POST)
      .uri("/users").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateUser { name: "".to_string() }
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
  async fn test_create_user_failure_no_body() {
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
  async fn test_create_user_failure_invalid_content_type() {
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
  async fn create_user_req(state: Arc::<state::State>, name: &str) -> Response<Body> {
    let req = Request::builder().method(Method::POST)
      .uri("/users").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateUser { name: format!("{name}") }))
      .unwrap())).unwrap();

    routes::init(state).oneshot(req).await.unwrap()
  }
}