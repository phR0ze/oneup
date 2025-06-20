use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, State}, response::IntoResponse};
use crate::{db, state, model, routes::Json, errors::Error};

/// Create a new Category
/// 
/// - POST handler for `/categories`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(category): Json<model::CategoryPartial>) -> Result<impl IntoResponse, Error>
{
  let id = db::category::insert(state.db(), &category.name).await?;
  let category = db::category::fetch_by_id(state.db(), id).await?;

  Ok((StatusCode::CREATED, Json(serde_json::json!(category))))
}

/// Get all categories
/// 
/// - GET handler for `/categories`
pub async fn get(State(state): State<Arc<state::State>>)
  -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::category::fetch_all(state.db()).await?))
}

/// Get specific category by id
/// 
/// - GET handler for `/categories/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::category::fetch_by_id(state.db(), id).await?))
}

/// Update specific category by id
/// 
/// - PUT handler for `/categories/{id}`
pub async fn update_by_id(State(state): State<Arc<state::State>>, Path(id): Path<i64>,
  Json(category): Json<model::CategoryPartial>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::category::update_by_id(state.db(), id, &category.name).await?))
}

/// Delete specific category by id
/// 
/// - DELETE handler for `/categories/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::category::delete_by_id(state.db(), id).await?))
}

#[cfg(test)]
mod tests
{
  use super::{*, super::tests::login_as_admin};
  use axum::{
    body::Body,
    http::{ header, Response, Request, Method, StatusCode}
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;
  use crate::{errors, routes, state};

  #[tokio::test]
  async fn test_delete_by_id() 
  {
    let state = state::test().await;
    let category1 = "category1";
    let id = db::category::insert(state.db(), category1).await.unwrap();

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::DELETE)
      .uri(format!("/api/categories/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Category was deleted in the DB
    let err = db::category::fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_by_id() 
  {
    let state = state::test().await;
    let category1 = "category1";
    let category2 = "category2";

    // Create Category
    let id = db::category::insert(state.db(), category1).await.unwrap();
    let category = db::category::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(category.name, category1);

    // Now update Category
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::PUT)
      .uri(format!("/api/categories/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CategoryPartial { name: format!("{category2}") })
      ).unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Category was updated in the DB
    let category = db::category::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(category.name, category2);
  }

  #[tokio::test]
  async fn test_get_all_success() 
  {
    let state = state::test().await;
    let category1 = "category1";
    let category2 = "category2";
    db::category::insert(state.db(), category2).await.unwrap();
    db::category::insert(state.db(), category1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri("/api/categories")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let categories: Vec<model::Category> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(categories.len(), 3);
    assert_eq!(categories[0].name, "Unspecified");
    assert_eq!(categories[0].id, 1);
    assert_eq!(categories[1].name, category1);
    assert_eq!(categories[1].id, 3);
    assert!(categories[1].created_at <= chrono::Local::now());
    assert!(categories[1].updated_at <= chrono::Local::now());
    assert_eq!(categories[2].name, category2);
    assert_eq!(categories[2].id, 2);
    assert!(categories[2].created_at <= chrono::Local::now());
    assert!(categories[2].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_get_by_id_success() 
  {
    let state = state::test().await;
    let category1 = "category1";
    let id = db::category::insert(state.db(), category1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/api/categories/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
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
  async fn test_create_success() 
  {
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
  }

  #[tokio::test]
  async fn test_create_failure_duplicate() 
  {
    let category1 = "category1";
    let state = state::test().await;

    // Create the category for the first time
    db::category::insert(state.db(), category1).await.unwrap();

    // Now attempt to create the same Category again
    let res = create_category_req(state, category1).await;
    assert_eq!(res.status(), StatusCode::CONFLICT);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Category 'category1' already exists");
  }

  #[tokio::test]
  async fn test_create_failure_no_name_given() 
  {
    let state = state::test().await;

    // Attempt to create a Category with no name
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/api/categories")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CategoryPartial { name: "".to_string() }
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
  async fn test_create_failure_no_body() 
  {
    let state = state::test().await;

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/api/categories")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();

    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::BAD_REQUEST);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Failed to parse the request body as JSON: EOF while parsing a value at line 1 column 0");
  }

  #[tokio::test]
  async fn test_create_failure_invalid_content_type() 
  {
    let state = state::test().await;

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/api/categories")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();

    let res = routes::init(state.clone()).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  }

  // Helper function to create a Category request
  async fn create_category_req(state: Arc::<state::State>, name: &str) -> Response<Body> 
  {
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/api/categories")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CategoryPartial { name: format!("{name}") }
      )).unwrap())).unwrap();

    routes::init(state).oneshot(req).await.unwrap()
  }
}