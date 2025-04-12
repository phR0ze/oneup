use axum::{
  http::StatusCode,
  response::{IntoResponse, Response},
};

/// Wrap `anyhow::Error` to implement `IntoResponse` so we can use `anyhow::Error`
/// as the error type in our routes.
struct Error(anyhow::Error);

// Tell axum how to convert `Error` into a response.
impl IntoResponse for Error {
  fn into_response(self) -> Response {
    (
      StatusCode::INTERNAL_SERVER_ERROR,
      format!("Something went wrong: {}", self.0),
    ).into_response()
  }
}

// This enables using `?` on functions that return `Result<_, anyhow::Error>` to turn them into
// `Result<_, Error>` so that they will then be converted into a response automatically
impl<E> From<E> for Error
where
    E: Into<anyhow::Error>,
{
  fn from(err: E) -> Self {
      Self(err.into())
  }
}
