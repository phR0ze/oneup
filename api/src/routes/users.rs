use std::sync::Arc;
use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use sqlx::SqlitePool;
use super::{err_res};
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
) -> impl IntoResponse {
//) -> Result<impl IntoResponse, (StatusCode, Json<serde_json::Value>)> {

  // Validation on user input
  // if user.name.is_empty() {
  //   return Err(err_res(StatusCode::BAD_REQUEST, "Name is required"));
  // }

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

  println!("{:?}", user);

  let res = serde_json::json!({
    "status": "ok",
    "message": "hello",
  });

  Json(res)
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
  async fn test_create_user() {
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
    assert_eq!(res.status(), StatusCode::INTERNAL_SERVER_ERROR);

    // Convert the body into a User
    // let body = hyper::body::to_bytes(res.into_body()).await.unwrap();



    // let user = insert_user(state.db(), test_user).await.expect("can't insert user");
    // assert_eq!(user.id, 1);
    // assert_eq!(user.name, test_user);
    // assert!(user.created_at <= chrono::Local::now());
    // assert!(user.updated_at <= chrono::Local::now());
  }
}