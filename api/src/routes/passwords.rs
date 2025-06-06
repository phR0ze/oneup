use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, Query, State}, response::IntoResponse};
use crate::{state, model, routes::Json, errors::Error};

// /// Create a new password
// /// 
// /// - POST handler for `/passwords`
// pub async fn create(State(state): State<Arc<state::State>>,
//   Json(password): Json<model::CreatePassword>) -> Result<impl IntoResponse, Error>
// {
 
//   let salt = model::password::generate_salt();
//   let hash = model::password::hash_password(&password.value, &salt)?;

//   // Retrieve and respond with the stored password
//   let id = model::password::insert(state.db(), salt, hash, password.user_id).await?;
//   let password = model::password::fetch_by_id(state.db(), id).await?;
//   Ok((StatusCode::CREATED, Json(serde_json::json!(password))))
// }

// /// Get all passwords or filter by user id
// /// 
// /// - GET handler for `/passwords`
// /// - GET handler for `/passwords?user_id={id}`
// pub async fn get(State(state): State<Arc<state::State>>,
//   Query(params): Query<model::Filter>) -> Result<impl IntoResponse, Error>
// {
//   // Filter by user_id
//   if let Some(user_id) = params.user_id {
//     return Ok(Json(model::password::fetch_by_user_id(state.db(), user_id).await?));
//   }

//   // Fetch all passwords if no user_id is provided
//   Ok(Json(model::password::fetch_all(state.db()).await?))
// }

// /// Get specific password by id
// /// 
// /// - GET handler for `/passwords/{id}`
// pub async fn get_by_id(State(state): State<Arc<state::State>>,
//   Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
// {
//   Ok(Json(model::password::fetch_by_id(state.db(), id).await?))
// }

// /// Update specific password by id
// /// 
// /// - PUT handler for `/passwords/{id}`
// pub async fn update_by_id(State(state): State<Arc<state::State>>,
//   Json(password): Json<model::UpdatePassword>) -> Result<impl IntoResponse, Error>
// {
//   Ok(Json(model::password::update_by_id(state.db(), password.id, password.value).await?))
// }

// /// Delete specific password by id
// /// 
// /// - DELETE handler for `/passwords/{id}`
// pub async fn delete_by_id(State(state): State<Arc<state::State>>,
//   Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
// {
//   Ok(Json(model::password::delete_by_id(state.db(), id).await?))
// }

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

//   #[tokio::test]
//   async fn test_delete_by_id() {
//     let state = state::test().await;
//     let password1 = 10;
//     let user1 = "user1";
//     let user_id = model::user::insert(state.db(), user1).await.unwrap();
//     let id = model::password::insert(state.db(), password1, user_id).await.unwrap();

//     let req = Request::builder().method(Method::DELETE)
//       .uri(format!("/passwords/{}", id))
//       .header("content-type", "application/json")
//       .body(Body::empty()).unwrap();
//     let res = routes::init(state.clone()).oneshot(req).await.unwrap();
//     assert_eq!(res.status(), StatusCode::OK);

//     // Now check that the password was deleted in the DB
//     let err = model::password::fetch_by_id(state.db(), id).await.unwrap_err();
//     assert_eq!(err.kind, errors::ErrorKind::NotFound);
//   }

//   #[tokio::test]
//   async fn test_update_by_id() {
//     let state = state::test().await;
//     let password1 = 10;
//     let password2 = 20;
//     let user1 = "user1";
//     let user_id = model::user::insert(state.db(), user1).await.unwrap();

//     // Create password
//     let id = model::password::insert(state.db(), password1, user_id).await.unwrap();
//     let password = model::password::fetch_by_id(state.db(), id).await.unwrap();
//     assert_eq!(password.value, password1);

//     // Now update password
//     let req = Request::builder().method(Method::PUT)
//       .uri(format!("/passwords/{}", id))
//       .header("content-type", "application/json")
//       .body(Body::from(serde_json::to_vec(&serde_json::json!(
//           model::UpdatePassword { id: id, value: password2 })
//       ).unwrap())).unwrap();
//     let res = routes::init(state.clone()).oneshot(req).await.unwrap();
//     assert_eq!(res.status(), StatusCode::OK);

//     // Now check that the password was updated in the DB
//     let password = model::password::fetch_by_id(state.db(), id).await.unwrap();
//     assert_eq!(password.value, password2);
//   }

//   #[tokio::test]
//   async fn test_get_all() {
//     let state = state::test().await;
//     let password1 = 10;
//     let password2 = 20;
//     let password3 = 20;
//     let user1 = "user1";
//     let user2 = "user2";
//     let user_id_1 = model::user::insert(state.db(), user1).await.unwrap();
//     let user_id_2 = model::user::insert(state.db(), user2).await.unwrap();
//     model::password::insert(state.db(), password1, user_id_1).await.unwrap();
//     model::password::insert(state.db(), password2, user_id_1).await.unwrap();
//     model::password::insert(state.db(), password3, user_id_2).await.unwrap();

//     let req = Request::builder().method(Method::GET)
//       .uri("/passwords").header("content-type", "application/json")
//       .body(Body::empty()).unwrap();
//     let res = routes::init(state).oneshot(req).await.unwrap();

//     assert_eq!(res.status(), StatusCode::OK);
//     let bytes = res.into_body().collect().await.unwrap().to_bytes();
//     let passwords: Vec<model::Password> = serde_json::from_slice(&bytes).unwrap();
//     assert_eq!(passwords.len(), 3);
//     assert_eq!(passwords[0].value, password1);

//     assert_eq!(passwords[0].id, 1);
//     assert_eq!(passwords[0].user_id, user_id_1);
//     assert!(passwords[0].created_at <= chrono::Local::now());
//     assert!(passwords[0].updated_at <= chrono::Local::now());
//     assert_eq!(passwords[0].created_at, passwords[0].updated_at);
//     assert_eq!(passwords[1].value, password2);

//     assert_eq!(passwords[1].id, 2);
//     assert_eq!(passwords[1].user_id, user_id_1);
//     assert!(passwords[1].created_at <= chrono::Local::now());
//     assert!(passwords[1].updated_at <= chrono::Local::now());
//     assert_eq!(passwords[1].created_at, passwords[1].updated_at);

//     assert_eq!(passwords[2].id, 3);
//     assert_eq!(passwords[2].user_id, user_id_2);
//     assert!(passwords[2].created_at <= chrono::Local::now());
//     assert!(passwords[2].updated_at <= chrono::Local::now());
//     assert_eq!(passwords[2].created_at, passwords[1].updated_at);
//   }

//   #[tokio::test]
//   async fn test_get_by_user_id() {
//     let state = state::test().await;
//     let password1 = 10;
//     let password2 = 20;
//     let password3 = 20;
//     let user1 = "user1";
//     let user2 = "user2";
//     let user_id_1 = model::user::insert(state.db(), user1).await.unwrap();
//     let user_id_2 = model::user::insert(state.db(), user2).await.unwrap();
//     model::password::insert(state.db(), password1, user_id_1).await.unwrap();
//     model::password::insert(state.db(), password2, user_id_1).await.unwrap();
//     model::password::insert(state.db(), password3, user_id_2).await.unwrap();

//     let req = Request::builder().method(Method::GET)
//       .uri(format!("/passwords?user_id={user_id_1}"))
//       .header("content-type", "application/json")
//       .body(Body::empty()).unwrap();
//     let res = routes::init(state).oneshot(req).await.unwrap();

//     assert_eq!(res.status(), StatusCode::OK);
//     let bytes = res.into_body().collect().await.unwrap().to_bytes();
//     let passwords: Vec<model::Password> = serde_json::from_slice(&bytes).unwrap();
//     assert_eq!(passwords.len(), 2);
//     assert_eq!(passwords[0].value, password1);

//     assert_eq!(passwords[0].id, 1);
//     assert_eq!(passwords[0].user_id, user_id_1);
//     assert!(passwords[0].created_at <= chrono::Local::now());
//     assert!(passwords[0].updated_at <= chrono::Local::now());
//     assert_eq!(passwords[0].created_at, passwords[0].updated_at);
//     assert_eq!(passwords[1].value, password2);

//     assert_eq!(passwords[1].id, 2);
//     assert_eq!(passwords[1].user_id, user_id_1);
//     assert!(passwords[1].created_at <= chrono::Local::now());
//     assert!(passwords[1].updated_at <= chrono::Local::now());
//     assert_eq!(passwords[1].created_at, passwords[1].updated_at);
//   }

//   #[tokio::test]
//   async fn test_get_by_id_success() {
//     let state = state::test().await;
//     let password1 = 10;
//     let user1 = "user1";
//     let user_id = model::user::insert(state.db(), user1).await.unwrap();
//     let id = model::password::insert(state.db(), password1, user_id).await.unwrap();

//     let req = Request::builder().method(Method::GET)
//       .uri(format!("/passwords/{}", id))
//       .header("content-type", "application/json")
//       .body(Body::empty()).unwrap();
//     let res = routes::init(state).oneshot(req).await.unwrap();

//     assert_eq!(res.status(), StatusCode::OK);
//     let bytes = res.into_body().collect().await.unwrap().to_bytes();
//     let password: model::Password = serde_json::from_slice(&bytes).unwrap();
//     assert_eq!(password.value, password1);
//     assert_eq!(password.id, 1);
//     assert_eq!(password.user_id, user_id);
//     assert!(password.created_at <= chrono::Local::now());
//     assert!(password.updated_at <= chrono::Local::now());
//   }

//   #[tokio::test]
//   async fn test_create_success() {
//     let state = state::test().await;
//     let password1 = 10;
//     let user1 = "user1";
//     let user_id = model::user::insert(state.db(), user1).await.unwrap();

//     let req = Request::builder().method(Method::POST)
//       .uri("/passwords").header("content-type", "application/json")
//       .body(Body::from(serde_json::to_vec(&serde_json::json!(
//         model::CreatePassword { value: password1, user_id: user_id }))
//       .unwrap())).unwrap();
//     let res = routes::init(state).oneshot(req).await.unwrap();

//     // Validate the response
//     assert_eq!(res.status(), StatusCode::CREATED);
//     let bytes = res.into_body().collect().await.unwrap().to_bytes();
//     let password: model::Password = serde_json::from_slice(&bytes).unwrap();
//     assert_eq!(password.id, 1);
//     assert_eq!(password.value, password1);
//     assert_eq!(password.user_id, user_id);
//     assert!(password.created_at <= chrono::Local::now());
//     assert!(password.updated_at <= chrono::Local::now());
//     assert_eq!(password.created_at, password.updated_at);
//   }

//   #[tokio::test]
//   async fn test_create_failure_no_body() {
//     let state = state::test().await;

//     let req = Request::builder().method(Method::POST)
//       .uri("/passwords") .header("content-type", "application/json")
//       .body(Body::empty()).unwrap();

//     let res = routes::init(state).oneshot(req).await.unwrap();

//     // Validate the response
//     assert_eq!(res.status(), StatusCode::BAD_REQUEST);
//     let bytes = res.into_body().collect().await.unwrap().to_bytes();
//     let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
//     assert_eq!(simple.message, "Failed to parse the request body as JSON: EOF while parsing a value at line 1 column 0");
//   }

  // #[tokio::test]
  // async fn test_create_failure_invalid_content_type() {
  //   let state = state::test().await;

  //   let req = Request::builder().method(Method::POST)
  //     .uri("/passwords").body(Body::empty()).unwrap();

  //   let res = routes::init(state.clone()).oneshot(req).await.unwrap();

  //   // Validate the response
  //   assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
  //   let bytes = res.into_body().collect().await.unwrap().to_bytes();
  //   let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
  //   assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  // }
}