use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, State}, response::IntoResponse};
use crate::{db, state, model, routes::Json, errors::Error};

/// Create a new Role
/// 
/// - POST handler for `/roles`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(role): Json<model::CreateRole>) -> Result<impl IntoResponse, Error>
{
  let id = db::role::insert(state.db(), &role.name).await?;
  let role = db::role::fetch_by_id(state.db(), id).await?;

  Ok((StatusCode::CREATED, Json(serde_json::json!(role))))
}

/// Get all roles
/// 
/// - GET handler for `/roles`
pub async fn get(State(state): State<Arc<state::State>>)
  -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::role::fetch_all(state.db()).await?))
}

/// Get specific role by id
/// 
/// - GET handler for `/roles/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::role::fetch_by_id(state.db(), id).await?))
}

/// Update specific role by id
/// 
/// - PUT handler for `/roles/{id}`
pub async fn update_by_id(State(state): State<Arc<state::State>>,
  Json(role): Json<model::UpdateRole>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::role::update_by_id(state.db(), role.id, &role.name).await?))
}

/// Delete specific role by id
/// 
/// - DELETE handler for `/roles/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::role::delete_by_id(state.db(), id).await?))
}

#[cfg(test)]
mod tests {
  use super::{*, super::tests::login_as_admin};
  use axum::{
    body::Body,
    http::{header, Response, Request, Method, StatusCode}
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;
  use crate::{errors, routes, state};

  #[tokio::test]
  async fn test_delete_by_id() {
    let state = state::test().await;
    let role1 = "role1";
    let id = db::role::insert(state.db(), role1).await.unwrap();

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::DELETE)
      .uri(format!("/roles/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Role was deleted in the DB
    let err = db::role::fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_by_id() {
    let state = state::test().await;
    let role1 = "role1";
    let role2 = "role2";

    // Create Role
    let id = db::role::insert(state.db(), role1).await.unwrap();
    let role = db::role::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(role.name, role1);

    // Now update Role
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::PUT)
      .uri(format!("/roles/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
          model::UpdateRole { id: id, name: format!("{role2}") })
      ).unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Role was updated in the DB
    let role = db::role::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(role.name, role2);
  }

  #[tokio::test]
  async fn test_get_all_success() {
    let state = state::test().await;
    let role1 = "role1";
    let role2 = "role2";
    db::role::insert(state.db(), role1).await.unwrap();
    db::role::insert(state.db(), role2).await.unwrap();

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::GET)
      .uri("/roles")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let roles: Vec<model::Role> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(roles.len(), 3);

    assert_eq!(roles[0].id, 1);
    assert_eq!(roles[0].name, "admin");

    assert_eq!(roles[1].id, 2);
    assert_eq!(roles[1].name, role1);
    assert!(roles[1].created_at <= chrono::Local::now());
    assert!(roles[1].updated_at <= chrono::Local::now());

    assert_eq!(roles[2].id, 3);
    assert_eq!(roles[2].name, role2);
    assert!(roles[2].created_at <= chrono::Local::now());
    assert!(roles[2].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_get_by_id_success() {
    let state = state::test().await;
    let role1 = "role1";
    let id = db::role::insert(state.db(), role1).await.unwrap();

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::GET)
      .uri(format!("/roles/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let role: model::Role = serde_json::from_slice(&bytes).unwrap();

    assert_eq!(role.id, 2);
    assert_eq!(role.name, role1);
    assert!(role.created_at <= chrono::Local::now());
    assert!(role.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_success() {
    let role1 = "role1";
    let state = state::test().await;
    let res = create_role_req(state, role1).await;

    // Validate the response
    assert_eq!(res.status(), StatusCode::CREATED);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let role: model::Role = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(role.id, 2);
    assert_eq!(role.name, role1);
    assert!(role.created_at <= chrono::Local::now());
    assert!(role.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_failure_duplicate() {
    let role1 = "role1";
    let state = state::test().await;

    // Create the role for the first time
    db::role::insert(state.db(), role1).await.unwrap();

    // Now attempt to create the same Role again
    let res = create_role_req(state, role1).await;
    assert_eq!(res.status(), StatusCode::CONFLICT);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Role 'role1' already exists");
  }

  #[tokio::test]
  async fn test_create_failure_no_name_given() {
    let state = state::test().await;

    // Attempt to create a Role with no name
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/roles")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateRole { name: "".to_string() }
      )).unwrap())).unwrap();

    // Spin up the server and send the request
    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Role name value is required");
  }

  #[tokio::test]
  async fn test_create_failure_no_body() {
    let state = state::test().await;

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/roles") 
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
  async fn test_create_failure_invalid_content_type() {
    let state = state::test().await;

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/roles")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();

    let res = routes::init(state.clone()).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    //let error = std::str::from_utf8(&bytes).unwrap();
    assert_eq!(simple.message, "Expected request with `Content-Type: application/json`");
  }

  // Helper function to create a Role request
  async fn create_role_req(state: Arc::<state::State>, name: &str) -> Response<Body> {
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/roles")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::CreateRole { name: format!("{name}") }
      )).unwrap())).unwrap();

    routes::init(state).oneshot(req).await.unwrap()
  }
}