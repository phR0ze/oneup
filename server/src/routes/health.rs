use axum::{response::IntoResponse, Json};
use crate::{model::Simple, APP_NAME};

pub async fn get() -> impl IntoResponse
{
  let msg = format!("{} API Services", APP_NAME);
  let res = serde_json::json!(Simple::new(&msg));
  Json(res)
}

#[cfg(test)]
mod tests
{
  use axum::{
    body::Body,
    http::{Request, Method, StatusCode}
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;
  use crate::{model, routes, state};

  #[tokio::test]
  async fn test_get_all_users_success() 
  {
    let state = state::test().await;

    let req = Request::builder().method(Method::GET)
      .uri("/api/health")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "OneUp API Services");
  }
}