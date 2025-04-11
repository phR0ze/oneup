use axum::{response::IntoResponse, Json};

pub async fn health() -> impl IntoResponse {
  const MESSAGE: &str = "API Services";

  let res = serde_json::json!({
      "status": "ok",
      "message": MESSAGE
  });

  Json(res)
}
