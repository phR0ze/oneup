use axum::{routing::get, Router, http::StatusCode};
use axum::http::{header, Method};
use tower_http::cors;
use std::sync::Arc;

use super::{state, model};

// Exports
mod users;
mod health;

/// Configure api routes
pub(crate) fn init(state: state::State) -> Router {

  // Disabling CORS across my routes for now
  // TODO: revisit where to enable CORS
  // let cors = cors::CorsLayer::new()
  //   .allow_methods([Method::GET, Method::POST])
  //   .allow_origin(cors::Any)
  //   .allow_headers([header::CONTENT_TYPE]);

  // Define the routes
  Router::new()
    .route("/health", get(health::get))
    .route("/users", get(users::get).post(users::create))
    // .layer(cors)
    .with_state(Arc::new(state))
}

// /// General error handler
// async fn handle_error(err: reqwest::Error) -> (StatusCode, String) {
//   return (
//       StatusCode::INTERNAL_SERVER_ERROR,
//       format!("Something went wrong: {}", err),
//   );
// }

/// Generate an error response
fn err_res(status: StatusCode, message: &str) -> (StatusCode, Json<serde_json::Value>) {
  return (status, Json(serde_json::json!(model::Simple::new(message))));
}

// -------------------------------------------------------------------------------------------------
// Custom extractor for JSON payloads
// -------------------------------------------------------------------------------------------------

// An extractor wrapping `axum::Json` with a custom rejection message
#[derive(axum::extract::FromRequest)]
#[from_request(via(axum::Json), rejection(ApiError))]
pub struct Json<T>(T);

// Provides the ability to use `Json` as a response as well
impl<T: serde::Serialize> axum::response::IntoResponse for Json<T> {
    fn into_response(self) -> axum::response::Response {
        let Self(value) = self;
        axum::Json(value).into_response()
    }
}

// Custom error handling for Json extraction
#[derive(Debug)]
pub struct ApiError {
    status: StatusCode,
    message: String,
}

// Support converting `From<JsonRejection>` to `ApiError`
impl From<axum::extract::rejection::JsonRejection> for ApiError {
  fn from(rejection: axum::extract::rejection::JsonRejection) -> Self {
    Self {
      status: rejection.status(),
      message: rejection.body_text(),
    }
  }
}

// Provides the ability to use `ApiError` as a response
impl axum::response::IntoResponse for ApiError {
  fn into_response(self) -> axum::response::Response {
    let payload = serde_json::json!({
      "status": self.status.as_str(),
      "message": self.message
    });

    (self.status, axum::Json(payload)).into_response()
  }
}