use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, State}, response::IntoResponse};
use crate::{state, model, routes::Json, errors::Error};

/// Get all Categorys
/// 
/// - GET handler for `/Categorys`
pub async fn get_all(State(state): State<Arc<state::State>>)
  -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::category::fetch_all(state.db()).await?))
}

/// Get Category by id
/// 
/// - GET handler for `/Categorys/{id}`
pub async fn get(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::category::fetch_by_id(state.db(), id).await?))
}

/// Create a new Category
/// 
/// - POST handler for `/Categorys`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(category): Json<model::CreateCategory>) -> Result<impl IntoResponse, Error>
{
  let id = model::category::insert(state.db(), &category.name).await?;
  let category = model::category::fetch_by_id(state.db(), id).await?;

  Ok((StatusCode::CREATED, Json(serde_json::json!(category))))
}

/// Update Category
/// 
/// - PUT handler for `/Categorys/{Category}`
pub async fn update(State(state): State<Arc<state::State>>,
  Json(category): Json<model::UpdateCategory>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::category::update(state.db(), category.id, &category.name).await?))
}

/// Delete Category
/// 
/// - DELETE handler for `/Categorys/{id}`
pub async fn delete(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(model::category::delete(state.db(), id).await?))
}

#[cfg(test)]
mod tests {
  use super::*;
  use axum::{
    body::Body,
    http::{ Response, Request, Method, StatusCode}
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;
  use crate::{errors, routes, state};

  #[tokio::test]
  async fn test_delete_category() {
    let state = state::test().await;
    let category1 = "category1";
    let id = model::category::insert(state.db(), category1).await.unwrap();

    let req = Request::builder().method(Method::DELETE)
      .uri(format!("/categories/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Category was deleted in the DB
    let err = model::category::fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_category() {
    let state = state::test().await;
    let category1 = "category1";
    let category2 = "category2";

    // Create Category
    let id = model::category::insert(state.db(), category1).await.unwrap();
    let category = model::category::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(category.name, category1);

    // Now update Category
    let req = Request::builder().method(Method::PUT)
      .uri(format!("/categories/{}", id))
      .header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
          model::UpdateCategory { id: id, name: format!("{category2}") })
      ).unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Category was updated in the DB
    let category = model::category::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(category.name, category2);
  }

  #[tokio::test]
  async fn test_get_all_categorys_success() {
    let state = state::test().await;
    let category1 = "category1";
    let category2 = "category2";
    model::category::insert(state.db(), category2).await.unwrap();
    model::category::insert(state.db(), category1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri("/categories").header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let categories: Vec<model::Category> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(categories.len(), 3);
    assert_eq!(categories[0].name, "Default");
    assert_eq!(categories[0].id, 1);
    assert_eq!(categories[1].name, category1);
    assert_eq!(categories[1].id, 3);
    assert!(categories[1].created_at <= chrono::Local::now());
    assert!(categories[1].updated_at <= chrono::Local::now());
    assert_eq!(categories[1].created_at, categories[1].updated_at);
    assert_eq!(categories[2].name, category2);
    assert_eq!(categories[2].id, 2);
    assert!(categories[2].created_at <= chrono::Local::now());
    assert!(categories[2].updated_at <= chrono::Local::now());
    assert_eq!(categories[2].created_at, categories[2].updated_at);
  }

  #[tokio::test]
  async fn test_get_category_by_id_success() {
    let state = state::test().await;
    let category1 = "category1";
    let id = model::category::insert(state.db(), category1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/categories/{}", id))
      .header("content-type", "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let category: model::Category = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(category.name, category1);
    assert_eq!(category.id, 2);
    assert!(category.created_at <= chrono::Local::now());
    assert!(category.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_category_success() {
    let category1 = "category1";
    let state = state::test().await;
    let res = create_category_req(state, category1).await;

    // Validate the response
    assert_eq!(res.status(), StatusCode::CREATED);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let category: model::Category = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(category.id, 2);
    assert_eq!(category.name, category1);
    assert!(category.created_at <= chrono::Local::now());
    assert!(category.updated_at <= chrono::Local::now());
    assert_eq!(category.created_at, category.updated_at);
  }

  #[tokio::test]
  async fn test_create_category_failure_duplicate() {
    let category1 = "category1";
    let state = state::test().await;

    // Create the category for the first time
    model::category::insert(state.db(), category1).await.unwrap();

    // Now attempt to create the same Category again
    let res = create_category_req(state, category1).await;
    assert_eq!(res.status(), StatusCode::CONFLICT);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Category 'category1' already exists");
  }

  #[tokio::test]
  async fn test_create_category_failure_no_name_given() {
    let state = state::test().await;

    // Attempt to create a Category with no name
    let req = Request::builder().method(Method::POST)
      .uri("/categories").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateCategory { name: "".to_string() }
      )).unwrap())).unwrap();

    // Spin up the server and send the request
    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Category name value is required");
  }

  #[tokio::test]
  async fn test_create_category_failure_no_body() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/categories") .header("content-type", "application/json")
      .body(Body::empty()).unwrap();

    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::BAD_REQUEST);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Failed to parse the request body as JSON: EOF while parsing a value at line 1 column 0");
  }

  #[tokio::test]
  async fn test_create_category_failure_invalid_content_type() {
    let state = state::test().await;

    let req = Request::builder().method(Method::POST)
      .uri("/categories").body(Body::empty()).unwrap();

    let res = routes::init(state.clone()).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    //let error = std::str::from_utf8(&bytes).unwrap();
    assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  }

  // Helper function to create a Category request
  async fn create_category_req(state: Arc::<state::State>, name: &str) -> Response<Body> {
    let req = Request::builder().method(Method::POST)
      .uri("/categories").header("content-type", "application/json")
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateCategory { name: format!("{name}") }
      )).unwrap())).unwrap();

    routes::init(state).oneshot(req).await.unwrap()
  }
}