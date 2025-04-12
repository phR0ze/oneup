use axum::{routing::get, Router, http::StatusCode, Json};
use axum::http::{header, Method};
use tower_http::cors;
use super::state;
use std::sync::Arc;

// Exports
mod users;
mod health;

/// Configure api routes
pub(crate) fn init(state: state::State) -> Router {

  // Disabling CORS across my routes for now
  // TODO: revisit where to enable CORS
  let cors = cors::CorsLayer::new()
    .allow_methods([Method::GET, Method::POST])
    .allow_origin(cors::Any)
    .allow_headers([header::CONTENT_TYPE]);

  // Define the routes
  Router::new()
    .route("/health", get(health::get))
    .route("/users", get(users::get).post(users::create))
    .layer(cors)
    .with_state(Arc::new(state))
}

/// Generate an error response
fn err_res(status: StatusCode, message: &str) -> (StatusCode, Json<serde_json::Value>) {
  return (status, Json(serde_json::json!({
    "status": "error",
    "message": message,
  })))
}
