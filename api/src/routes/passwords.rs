use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, Query, State}, response::IntoResponse};
use crate::{db, errors::Error, model, routes::Json, state, security::auth};

/// Create a new password
/// 
/// - POST handler for `/passwords`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(dto): Json<model::CreatePassword>) -> Result<impl IntoResponse, Error>
{
  auth::check_password_policy(&dto.password)?;

  // Create and store the new password for the user
  let creds = auth::hash_password(&dto.password)?;
  let id = db::password::insert(state.db(), dto.user_id, &creds.salt, &creds.hash).await?;

  // Retrieve and respond with the stored password
  let password = db::password::fetch_by_id(state.db(), id).await?;
  Ok((StatusCode::CREATED, Json(serde_json::json!(password))))
}

/// Get passwords filtered by user id
/// 
/// - GET handler for `/passwords`
/// - GET handler for `/passwords?user_id={id}`
pub async fn get(State(state): State<Arc<state::State>>,
  Query(filter): Query<model::Filter>) -> Result<impl IntoResponse, Error>
{
  // Filter by user_id
  if let Some(user_id) = filter.user_id {
    return Ok(Json(db::password::fetch_by_user_id(state.db(), user_id).await?));
  }

  // Not supporting a get for all passwords
  Err(Error::http(StatusCode::UNPROCESSABLE_ENTITY, "User id must be given as a filter"))
}

/// Get specific password by id
/// 
/// - GET handler for `/passwords/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::password::fetch_by_id(state.db(), id).await?))
}

/// Delete specific password by id
/// 
/// - DELETE handler for `/passwords/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::password::delete_by_id(state.db(), id).await?))
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
    let salt1 = "salt1";
    let hash1 = "hash1";
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
    let id = db::password::insert(state.db(), user_id, salt1, hash1).await.unwrap();

    let req = Request::builder().method(Method::DELETE)
      .uri(format!("/passwords/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the password was deleted in the DB
    let err = db::password::fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_get_by_user_id() {
    let state = state::test().await;
    let (salt1, hash1) = ("salt1", "hash1");
    let (salt2, hash2) = ("salt2", "hash2");
    let (salt3, hash3) = ("salt3", "hash3");
    let user1 = "user1";
    let user2 = "user2";
    let email1 = "user1@foo.com";
    let email2 = "user2@foo.com";
    let user_id_1 = db::user::insert(state.db(), user1, email1).await.unwrap();
    let user_id_2 = db::user::insert(state.db(), user2, email2).await.unwrap();
    db::password::insert(state.db(), user_id_1, salt1, hash1).await.unwrap();
    db::password::insert(state.db(), user_id_1, salt2, hash2).await.unwrap();
    db::password::insert(state.db(), user_id_2, salt3, hash3).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/passwords?user_id={user_id_1}"))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let passwords: Vec<model::Password> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(passwords.len(), 2);
    assert_eq!(passwords[1].id, 1);
    assert_eq!(passwords[1].user_id, user_id_1);
    assert_eq!(passwords[1].salt, salt1);
    assert_eq!(passwords[1].hash, hash1);
    assert!(passwords[1].created_at <= chrono::Local::now());

    assert_eq!(passwords[0].id, 2);
    assert_eq!(passwords[0].user_id, user_id_1);
    assert_eq!(passwords[0].salt, salt2);
    assert_eq!(passwords[0].hash, hash2);
    assert!(passwords[0].created_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_get_by_id_success() {
    let state = state::test().await;
    let salt1 = "salt1";
    let hash1 = "hash1";
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();
    let id = db::password::insert(state.db(), user_id, salt1, hash1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/passwords/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let password: model::Password = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(password.id, 1);
    assert_eq!(password.user_id, user_id);
    assert_eq!(password.salt, salt1);
    assert_eq!(password.hash, hash1);
    assert!(password.created_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_success() {
    let state = state::test().await;
    let password1 = "password1";
    let user1 = "user1";
    let email1 = "user1@foo.com";
    let user_id = db::user::insert(state.db(), user1, email1).await.unwrap();

    let req = Request::builder().method(Method::POST)
      .uri("/passwords").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreatePassword { user_id: user_id, password: password1.to_string() }))
      .unwrap())).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::CREATED);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let password: model::Password = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(password.id, 1);
    assert_eq!(password.user_id, user_id);
    assert!(password.created_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_failure_no_body() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/passwords") .header("content-type", "application/json")
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
      .uri("/passwords").body(Body::empty()).unwrap();

    let res = routes::init(state.clone()).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  }
}