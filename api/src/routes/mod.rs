/*!
 * Axum route handlers
 */
use axum::{routing::get, Router};
use std::sync::Arc;

use super::state;

// Exports
mod users;
mod health;

/// Configure api routes
pub(crate) fn init(state: state::State) -> Router {

  // TODO: layer in security
  // let sensitive_headers = vec![header::AUTHORIZATION, header::COOKIE].into();

  // Disabling CORS across my routes for now
  // TODO: revisit where to enable CORS
  // let cors = cors::CorsLayer::new()
  //   .allow_methods([Method::GET, Method::POST])
  //   .allow_origin(cors::Any)
  //   .allow_headers([header::CONTENT_TYPE]);

  // Define the routes
  Router::new()
    .route("/health", get(health::get))
    .route("/users", get(users::get_all).post(users::create))
    .route("/users/{id}", get(users::get_user_by_id))
    // .layer(cors)
    .with_state(Arc::new(state))
}

// -------------------------------------------------------------------------------------------------
// Custom rejection for JSON payloads so that we can return a consistent error response whether it
// was generated by an extractor early on or by application code during the handling of the request.
// -------------------------------------------------------------------------------------------------

// Converts into an `errors::Error` in the extraction rejection path
#[derive(axum::extract::FromRequest)]
#[from_request(via(axum::Json), rejection(crate::errors::Error))]
pub struct Json<T>(T);

// Converts to `IntoResponse` in the positve extraction path
impl<T: serde::Serialize> axum::response::IntoResponse for Json<T> {
    fn into_response(self) -> axum::response::Response {
        let Self(value) = self;
        axum::Json(value).into_response()
    }
}
