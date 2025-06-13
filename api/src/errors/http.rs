use crate::model::Simple;

#[derive(Debug)]
pub struct HttpError {
    pub msg: String,
    pub status: axum::http::StatusCode,
}

impl std::fmt::Display for HttpError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "HttpError({}): {}", self.status, self.msg)?;
        Ok(())
    }
}

// Provides the ability to use `Error` as a response
impl axum::response::IntoResponse for HttpError {
    fn into_response(self) -> axum::response::Response {
        (
            self.status,
            axum::Json(serde_json::json!(Simple::new(&self.msg))),
        ).into_response()
    }
}