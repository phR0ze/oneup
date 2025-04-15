use std::sync::Arc;
use axum::{extract::State, http::StatusCode, response::IntoResponse};
use sqlx::SqlitePool;
use super::{Json, err_res};
use crate::{state, model};

/// Get users
pub async fn get() -> impl IntoResponse {
  const MESSAGE: &str = "Users";

  let res = serde_json::json!({
      "status": "ok",
      "message": MESSAGE
  });

  Json(res)
}

/// Create a new user
/// 
/// - POST handler for `/users`
/// - returns `201 Created` and the JSON user object on success
/// - returns 
pub async fn create(
  State(state): State<Arc<state::State>>,
  Json(user): Json<model::NewUser>,
) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {

  // Validation on user input
  println!("{:?}", user);
  if user.name.is_empty() {
    Err(err_res(StatusCode::BAD_REQUEST, "Name value is required"))
  } else {
    Ok(Json(serde_json::json!({"foo": "bar"})))
  }

  // println!("{:?}", user);

  // let res = serde_json::json!({
  //   "status": "ok",
  //   "message": "hello",
  // });

  // Json(res)

  // TODO: layer in security
  // let sensitive_headers = vec![header::AUTHORIZATION, header::COOKIE].into();

  // Insert the user into the database
  // let result = sqlx::query(r#"INSERT INTO users (name) VALUES (?)"#)
  //   .bind(&user.name).execute(state.db()).await
  //   .map_err(|err: sqlx::Error| err.to_string());

  // Check if we hit the duplicate err
  // if let Err(err) = result {
  //   if err.contains("Duplicate entry") {
  //     return Err((StatusCode::CONFLICT, Json(serde_json::json!({
  //       "status": "error",
  //       "message": "User already exists",
  //     }))));
  //   }
  //   //return Err(err_res(StatusCode::INTERNAL_SERVER_ERROR, &format!("{:?}", err)));

  //   return Err((StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
  //     "status": "error",
  //     "message": &format!("{:?}", err),
  //   }))));
  // }

  // // Otherwise get and return the newly created user
  // let user_name = &user.name;
  // let result: model::User = sqlx::query_as(r#"SELECT * FROM users WHERE name = $1"#)
  //   .bind(user_name)
  //   .fetch_one(state.db()).await
  //   .map_err(|e| err_res(StatusCode::INTERNAL_SERVER_ERROR, &format!("{:?}", e)))?;

  // println!("{:?}", result);
  // //Ok(Json(serde_json::json!({"foo": "bar"})))
  // Err(err_res(StatusCode::INTERNAL_SERVER_ERROR, "Not implemented"))

}

// Insert a new user into the database and return the new user object
async fn insert_user(db: &SqlitePool, name: &str) -> anyhow::Result<model::User> {
  let user = sqlx::query_as::<_, model::User>(r#"INSERT INTO users (name) VALUES (?)"#)
    .bind(name).fetch_one(db).await?;
  Ok(user)
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
  use crate::routes;
  use crate::state;

  #[tokio::test]
  async fn test_create_user_success() {
    let state = state::test().await;
    let test_user = "test_user";

    // Create the request
    let req = Request::builder().method(Method::POST)
      .uri("/users")
      .header("content-type", "application/json")
      .body(Body::from(format!(r#"{{"name": "{}"}}"#, test_user)))
      .unwrap();

    // Spin up the server and send the request
    let res = routes::init(state)
      .oneshot(req)
      .await
      .unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::ACCEPTED);
    let body = res.into_body().collect().await.unwrap().to_bytes();
    let user: model::User = serde_json::from_slice(&body).unwrap();

    assert_eq!(user.id, 1);
    // assert_eq!(user.name, test_user);
    // assert!(user.created_at <= chrono::Local::now());
    // assert!(user.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_user_failure_no_name_given() {
    let state = state::test().await;

    // Attempt to create a user with no name
    let req = Request::builder()
      .method(Method::POST)
      .uri("/users")
      .header("content-type", "application/json")
      .body(Body::from(
        serde_json::to_vec(&serde_json::json!({
          "name": ""
        })).unwrap()
      )).unwrap();

    // Spin up the server and send the request
    let res = routes::init(state)
      .oneshot(req)
      .await
      .unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::BAD_REQUEST);
    let bytes = res.into_body().collect().await.unwrap().to_bytes().to_vec();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Name value is required");
  }

  #[tokio::test]
  async fn test_create_user_failure_no_body() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/users")
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();

    let res = routes::init(state)
      .oneshot(req)
      .await
      .unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::BAD_REQUEST);
    let bytes = res.into_body().collect().await.unwrap().to_bytes().to_vec();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Failed to parse the request body as JSON: EOF while parsing a value at line 1 column 0");
  }

  #[tokio::test]
  async fn test_create_user_failure_invalid_content_type() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/users")
      .body(Body::empty()).unwrap();

    let res = routes::init(state)
      .oneshot(req)
      .await
      .unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let bytes = res.into_body().collect().await.unwrap().to_bytes().to_vec();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    //let error = std::str::from_utf8(&bytes).unwrap();
    assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  }
}