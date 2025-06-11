use std::sync::Arc;
use axum::{extract::State, http::StatusCode, response::IntoResponse};
use crate::{db, state, model, errors::Error, routes::Json, security::auth};

/// Login a user and generate a token to be used in subsequent requests
pub async fn login(State(state): State<Arc<state::State>>,
    Json(dto): Json<model::LoginRequest>) -> Result<impl IntoResponse, Error>
{
    // Get the user password from the database
    let password = db::password::fetch_active(state.db(), dto.user_id).await?;

    // Validate user credentials
    let credential = auth::Credential { salt: password.salt, hash: password.hash };
    auth::verify_password(&credential, &dto.password)?;

    // Generate JWT token
    let user = db::user::fetch_by_id(state.db(), dto.user_id).await?;
    let key = db::apikey::fetch_latest(state.db()).await?;
    let token = auth::encode_jwt_token(&key.value, &user)?;

    Ok((StatusCode::OK, Json(serde_json::json!(
      model::LoginResponse { token }
    ))))
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
  use crate::{routes, state};

  #[tokio::test]
  async fn test_login_success() {
    let state = state::test().await;
    let name = "user1";
    let email = "user1@foo.com";
    let password = "password123";
    
    // Create user and insert password
    let user_id = db::user::insert(state.db(), &name, &email).await.unwrap();
    let creds = auth::hash_password(&password).unwrap();
    db::password::insert(state.db(), user_id, &creds.salt, &creds.hash).await.unwrap();

    // Now attempt to login
    let req = Request::builder().method(Method::POST)
      .uri("/login").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::LoginRequest { user_id, password: password.to_string() }))
      .unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    let body = BodyExt::collect(res.into_body()).await.unwrap().to_bytes();
    let login: model::LoginResponse = serde_json::from_slice(&body).unwrap();
    assert!(!login.token.is_empty());
  }

  #[tokio::test]
  async fn test_login_invalid_password() {
    let state = state::test().await;
    let name = "user2";
    let email = "user2@foo.com";
    let password = "password123";
    let wrong_password = "wrongpassword";

    // Create user and insert password
    let user_id = db::user::insert(state.db(), &name, &email).await.unwrap();
    let creds = auth::hash_password(&password).unwrap();
    db::password::insert(state.db(), user_id, &creds.salt, &creds.hash).await.unwrap();

    // Attempt to login with incorrect password
    let req = Request::builder().method(Method::POST)
      .uri("/login").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::LoginRequest { user_id, password: wrong_password.to_string() }))
      .unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::UNAUTHORIZED);
  }

  #[tokio::test]
  async fn test_login_no_password_set() {
    let state = state::test().await;
    let name = "user3";
    let email = "user3@foo.com";

    // Create user without setting a password
    let user_id = db::user::insert(state.db(), &name, &email).await.unwrap();

    // Attempt to login without a password set
    let req = Request::builder().method(Method::POST)
      .uri("/login").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::LoginRequest { user_id, password: "somepassword".to_string() }))
      .unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::NOT_FOUND);
  }
}