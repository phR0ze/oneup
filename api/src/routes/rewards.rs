use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, Query, State}, response::IntoResponse};
use crate::{state, model, routes::Json, errors::Error};

/// Create a new reward
/// 
/// - POST handler for `/rewards`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(reward): Json<model::CreateReward>) -> Result<impl IntoResponse, Error>
{
  let id = model::reward::insert(state.db(), reward.value, reward.user_id).await?;
  let reward = model::reward::fetch_by_id(state.db(), id).await?;

  Ok((StatusCode::CREATED, Json(serde_json::json!(reward))))
}

/// Get all rewards or filter by user id
/// 
/// - GET handler for `/rewards`
/// - GET handler for `/rewards?user_id={id}`
pub async fn get(State(state): State<Arc<state::State>>,
  Query(filter): Query<model::Filter>) -> Result<impl IntoResponse, Error>
{
  // Filter by user_id
  if let Some(user_id) = filter.user_id {
    return Ok(Json(model::reward::fetch_by_user_id(state.db(), user_id).await?));
  }

  // Fetch all rewards if no user_id is provided
  Ok(Json(model::reward::fetch_all(state.db()).await?))
}

/// Get specific reward by id
/// 
/// - GET handler for `/rewards/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::reward::fetch_by_id(state.db(), id).await?))
}

/// Update specific reward by id
/// 
/// - PUT handler for `/rewards/{id}`
pub async fn update_by_id(State(state): State<Arc<state::State>>,
  Json(reward): Json<model::UpdateReward>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::reward::update_by_id(state.db(), reward.id, reward.value).await?))
}

/// Delete specific reward by id
/// 
/// - DELETE handler for `/rewards/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::reward::delete_by_id(state.db(), id).await?))
}

#[cfg(test)]
mod tests {
  use super::*;
  use axum::{
    body::Body,
    http::{ Request, Method, StatusCode}
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;
  use crate::{errors, routes, state};

  #[tokio::test]
  async fn test_delete_by_id() {
    let state = state::test().await;
    let reward1 = 10;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let id = model::reward::insert(state.db(), reward1, user_id).await.unwrap();

    let req = Request::builder().method(Method::DELETE)
      .uri(format!("/rewards/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the reward was deleted in the DB
    let err = model::reward::fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_by_id() {
    let state = state::test().await;
    let reward1 = 10;
    let reward2 = 20;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();

    // Create reward
    let id = model::reward::insert(state.db(), reward1, user_id).await.unwrap();
    let reward = model::reward::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(reward.value, reward1);

    // Now update reward
    let req = Request::builder().method(Method::PUT)
      .uri(format!("/rewards/{}", id))
      .header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
          model::UpdateReward { id: id, value: reward2 })
      ).unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the reward was updated in the DB
    let reward = model::reward::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(reward.value, reward2);
  }

  #[tokio::test]
  async fn test_get_all() {
    let state = state::test().await;
    let reward1 = 10;
    let reward2 = 20;
    let reward3 = 20;
    let user1 = "user1";
    let user2 = "user2";
    let user_id_1 = model::user::insert(state.db(), user1).await.unwrap();
    let user_id_2 = model::user::insert(state.db(), user2).await.unwrap();
    model::reward::insert(state.db(), reward1, user_id_1).await.unwrap();
    model::reward::insert(state.db(), reward2, user_id_1).await.unwrap();
    model::reward::insert(state.db(), reward3, user_id_2).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri("/rewards").header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let rewards: Vec<model::Reward> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(rewards.len(), 3);
    assert_eq!(rewards[0].value, reward1);

    assert_eq!(rewards[0].id, 1);
    assert_eq!(rewards[0].user_id, user_id_1);
    assert!(rewards[0].created_at <= chrono::Local::now());
    assert!(rewards[0].updated_at <= chrono::Local::now());
    assert_eq!(rewards[1].value, reward2);

    assert_eq!(rewards[1].id, 2);
    assert_eq!(rewards[1].user_id, user_id_1);
    assert!(rewards[1].created_at <= chrono::Local::now());
    assert!(rewards[1].updated_at <= chrono::Local::now());

    assert_eq!(rewards[2].id, 3);
    assert_eq!(rewards[2].user_id, user_id_2);
    assert!(rewards[2].created_at <= chrono::Local::now());
    assert!(rewards[2].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_get_by_user_id() {
    let state = state::test().await;
    let reward1 = 10;
    let reward2 = 20;
    let reward3 = 20;
    let user1 = "user1";
    let user2 = "user2";
    let user_id_1 = model::user::insert(state.db(), user1).await.unwrap();
    let user_id_2 = model::user::insert(state.db(), user2).await.unwrap();
    model::reward::insert(state.db(), reward1, user_id_1).await.unwrap();
    model::reward::insert(state.db(), reward2, user_id_1).await.unwrap();
    model::reward::insert(state.db(), reward3, user_id_2).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/rewards?user_id={user_id_1}"))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let rewards: Vec<model::Reward> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(rewards.len(), 2);
    assert_eq!(rewards[0].value, reward1);

    assert_eq!(rewards[0].id, 1);
    assert_eq!(rewards[0].user_id, user_id_1);
    assert!(rewards[0].created_at <= chrono::Local::now());
    assert!(rewards[0].updated_at <= chrono::Local::now());
    assert_eq!(rewards[1].value, reward2);

    assert_eq!(rewards[1].id, 2);
    assert_eq!(rewards[1].user_id, user_id_1);
    assert!(rewards[1].created_at <= chrono::Local::now());
    assert!(rewards[1].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_get_by_id_success() {
    let state = state::test().await;
    let reward1 = 10;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();
    let id = model::reward::insert(state.db(), reward1, user_id).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/rewards/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let reward: model::Reward = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(reward.value, reward1);
    assert_eq!(reward.id, 1);
    assert_eq!(reward.user_id, user_id);
    assert!(reward.created_at <= chrono::Local::now());
    assert!(reward.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_success() {
    let state = state::test().await;
    let reward1 = 10;
    let user1 = "user1";
    let user_id = model::user::insert(state.db(), user1).await.unwrap();

    let req = Request::builder().method(Method::POST)
      .uri("/rewards").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateReward { value: reward1, user_id: user_id }))
      .unwrap())).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::CREATED);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let reward: model::Reward = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(reward.id, 1);
    assert_eq!(reward.value, reward1);
    assert_eq!(reward.user_id, user_id);
    assert!(reward.created_at <= chrono::Local::now());
    assert!(reward.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_failure_no_body() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/rewards") .header("content-type", "application/json")
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
      .uri("/rewards").body(Body::empty()).unwrap();

    let res = routes::init(state.clone()).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    //let error = std::str::from_utf8(&bytes).unwrap();
    assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  }
}