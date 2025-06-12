use std::sync::Arc;
use axum::{
  extract::{Request, State}, middleware::Next,
  http::{self, StatusCode}, response::IntoResponse,
};

use crate::{db, state, model, errors::Error, routes::Json, security::auth};

/// Login a user and generate a token to be used in subsequent requests
/// 
pub async fn login(State(state): State<Arc<state::State>>,
  Json(dto): Json<model::LoginRequest>) -> Result<impl IntoResponse, Error>
{
  let unauthorized = || Error::http(StatusCode::UNAUTHORIZED, "Invalid email or password");

  // Get user data, converting errors into Unauthorized responses
  let user = db::user::fetch_by_email(state.db(), &dto.email).await.map_err(|_| unauthorized())?;
  let roles = db::user::roles(state.db(), user.id).await.map_err(|_| unauthorized())?;
  let password = db::password::fetch_active(state.db(), user.id).await.map_err(|_| unauthorized())?;

  // Validate user credentials
  let credential = model::Credential { salt: password.salt, hash: password.hash };
  auth::verify_password(&credential, &dto.password)?;

  // Generate JWT token
  let key = db::apikey::fetch_latest(state.db()).await?;
  let token = auth::encode_jwt_token(&key.value, &user, roles)?;

  Ok((StatusCode::OK, Json(serde_json::json!(
    model::LoginResponse { access_token: token, token_type: "Bearer".to_string() }
  ))))
}

/// Middleware to extract and validate a Bearer token from the request
/// 
/// - Requires the authorization header "Authorization: Bearer <token>"
/// - Extracts the token and verifies the signature erroring if invalid
/// - If valid the JWT claims are decoded and passed to the next handler
/// 
/// #### Parameters:
/// - ***req*** is the incoming request
/// - ***next*** is the next middleware or handler to call
pub async fn authorization(State(state): State<Arc<state::State>>,
  mut req: Request, next: Next) -> Result<impl IntoResponse, Error>
{
  let forbidden = || Error::http(StatusCode::FORBIDDEN, "Access denied: user not logged in");

  // Get the authorization header from the request
  let auth_header = match req.headers_mut().get(http::header::AUTHORIZATION) {
    Some(header) => header.to_str().map_err(|_| forbidden())?,
    None => return Err(forbidden()),
  };

  // Split out the JWT token
  let mut parts = auth_header.split_whitespace();
  let (_, token) = (parts.next(), parts.next().ok_or_else(|| forbidden())?);

  // Decode the JWT token using the latest API key from the database
  let key = db::apikey::fetch_latest(state.db()).await?;
  let claims = auth::decode_jwt_token(&key.value, token).map_err(|_| forbidden())?;

  // Send an error back if the token is expired
  if claims.exp < chrono::Utc::now().timestamp() as usize {
    return Err(Error::http(StatusCode::FORBIDDEN, "Bearer token has expired"));
  }

  // Insert the decoded claims into the request extensions
  req.extensions_mut().insert(claims);
  Ok(next.run(req).await)
}

#[cfg(test)]
mod tests {
  use super::{*, super::tests::insert_admin_and_login};
  use axum::{
    body::Body,
    http::{ Request, Method, StatusCode}
  };
  use tower::ServiceExt;
  use crate::{routes, state};

  #[tokio::test]
  async fn test_login_success() {
    let state = state::test().await;
    let (admin, access_token) = insert_admin_and_login(state.clone()).await;
    
    // Verify roles are included in the response
    let key = db::apikey::fetch_latest(state.db()).await.unwrap();
    let decoded_token = auth::decode_jwt_token(&key.value, &access_token).unwrap();
    let roles = db::user::roles(state.db(), admin.id).await.unwrap();
    assert_eq!(decoded_token.roles, roles);
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
        model::LoginRequest { email: email.to_string(), password: wrong_password.to_string() }))
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
    db::user::insert(state.db(), &name, &email).await.unwrap();

    // Attempt to login without a password set
    let req = Request::builder().method(Method::POST)
      .uri("/login").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::LoginRequest { email: email.to_string(), password: "somepassword".to_string() }))
      .unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::UNAUTHORIZED);
  }
}