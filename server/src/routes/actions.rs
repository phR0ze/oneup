use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, State}, response::IntoResponse};
use crate::{db, state, model, routes::Json, errors::Error};

/// Create a new Action
/// 
/// - POST handler for `/actions`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(action): Json<model::action::CreateAction>) -> Result<impl IntoResponse, Error>
{
  let id = db::action::insert(state.db(), &action).await?;
  let action = db::action::fetch_by_id(state.db(), id).await?;

  Ok((StatusCode::CREATED, Json(serde_json::json!(action))))
}

/// Get all actions
/// 
/// - GET handler for `/actions`
pub async fn get(State(state): State<Arc<state::State>>)
  -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::action::fetch_all(state.db()).await?))
}

/// Get specific action by id
/// 
/// - GET handler for `/actions/{id}`
pub async fn get_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::action::fetch_by_id(state.db(), id).await?))
}

/// Update specific action by id
/// 
/// - PUT handler for `/actions/{id}`
pub async fn update_by_id(State(state): State<Arc<state::State>>, Path(id): Path<i64>,
  Json(action): Json<model::action::UpdateAction>) -> Result<impl IntoResponse, Error>
{
  db::action::update_by_id(state.db(), id, &action).await?;
  Ok(Json(serde_json::json!({})))
}

/// Delete specific action by id
/// 
/// - DELETE handler for `/actions/{id}`
pub async fn delete_by_id(State(state): State<Arc<state::State>>,
  Path(id): Path<i64>) -> Result<impl IntoResponse, Error>
{
  Ok(Json(db::action::delete_by_id(state.db(), id).await?))
}

#[cfg(test)]
mod tests
{
  use super::{*, super::tests::login_as_admin};
  use axum::{
    body::Body,
    http::{header, Response, Request, Method, StatusCode}
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;
  use crate::{errors, routes, state};

  #[tokio::test]
  async fn test_delete_by_id()
  {
    let state = state::test().await;
    let action1 = "action1";
    let create_action = model::action::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    let id = db::action::insert(state.db(), &create_action).await.unwrap();

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::DELETE)
      .uri(format!("/api/actions/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::empty()).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Action was deleted in the DB
    let err = db::action::fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_by_id()
  {
    let state = state::test().await;
    let action1 = "action1";
    let action2 = "action2";

    // Create Action
    let create_action = model::action::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    let id = db::action::insert(state.db(), &create_action).await.unwrap();
    let action = db::action::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(action.desc, action1);

    // Now update Action
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::PUT)
      .uri(format!("/api/actions/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::action::UpdateAction {
          desc: Some(action2.to_string()), value: None, category_id: None, approved: None
        })
      ).unwrap())).unwrap();
    let res = routes::init(state.clone()).oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    // Now check that the Action was updated in the DB
    let action = db::action::fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(action.desc, action2);
  }

  #[tokio::test]
  async fn test_get_all_success()
  {
    let state = state::test().await;
    let action1 = "action1";
    let action2 = "action2";
    let create_action2 = model::action::CreateAction {
      desc: action2.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    db::action::insert(state.db(), &create_action2).await.unwrap();
    std::thread::sleep(std::time::Duration::from_millis(2));
    let create_action1 = model::action::CreateAction {
      desc: action1.to_string(),
      value: Some(2),
      category_id: None,
      approved: None,
    };
    db::action::insert(state.db(), &create_action1).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri("/api/actions")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let actions: Vec<model::Action> = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(actions.len(), 3);
    assert_eq!(actions[0].id, 1);
    assert_eq!(actions[0].desc, "Unspecified");
    assert_eq!(actions[0].value, 0);

    assert_eq!(actions[1].id, 3);
    assert_eq!(actions[1].desc, action1);
    assert_eq!(actions[1].value, 2);
    assert!(actions[1].created_at <= chrono::Local::now());
    assert!(actions[1].updated_at <= chrono::Local::now());

    assert_eq!(actions[2].id, 2);
    assert_eq!(actions[2].desc, action2);
    assert_eq!(actions[2].value, 0);
    assert!(actions[2].created_at <= chrono::Local::now());
    assert!(actions[2].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_get_by_id_success()
  {
    let state = state::test().await;
    let action1 = "action1";
    let create_action = model::action::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    let id = db::action::insert(state.db(), &create_action).await.unwrap();

    let req = Request::builder().method(Method::GET)
      .uri(format!("/api/actions/{}", id))
      .header(header::CONTENT_TYPE, "application/json")
      .body(Body::empty()).unwrap();
    let res = routes::init(state).oneshot(req).await.unwrap();

    assert_eq!(res.status(), StatusCode::OK);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let action: model::Action = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(action.desc, action1);
    assert_eq!(action.id, 2);
    assert!(action.created_at <= chrono::Local::now());
    assert!(action.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_success()
  {
    let action1 = "action1";
    let state = state::test().await;
    let res = create_action_req(state, action1).await;

    // Validate the response
    assert_eq!(res.status(), StatusCode::CREATED);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let action: model::Action = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(action.id, 2);
    assert_eq!(action.desc, action1);
    assert!(action.created_at <= chrono::Local::now());
    assert!(action.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_create_failure_duplicate()
  {
    let action1 = "action1";
    let state = state::test().await;

    // Create the action for the first time
    let create_action = model::action::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    db::action::insert(state.db(), &create_action).await.unwrap();

    // Now attempt to create the same Action again
    let res = create_action_req(state, action1).await;
    assert_eq!(res.status(), StatusCode::CONFLICT);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Action 'action1' already exists");
  }

  #[tokio::test]
  async fn test_create_failure_no_desc_given()
  {
    let state = state::test().await;

    // Attempt to create a Action with no desc
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/api/actions")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::action::CreateAction { desc: "".to_string(), value: None, category_id: None, approved: None }
      )).unwrap())).unwrap();

    // Spin up the server and send the request
    let res = routes::init(state).oneshot(req).await.unwrap();

    // Validate the response
    assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let simple: model::Simple = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(simple.message, "Action desc value is required");
  }

  #[tokio::test]
  async fn test_create_failure_no_body()
  {
    let state = state::test().await;

    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/api/actions")
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
      .uri("/api/actions")
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

  // Helper function to create a Action request
  async fn create_action_req(state: Arc::<state::State>, desc: &str) -> Response<Body>
  {
    let (_, access_token) = login_as_admin(state.clone()).await;
    let req = Request::builder().method(Method::POST)
      .uri("/api/actions")
      .header(header::CONTENT_TYPE, "application/json")
      .header(header::AUTHORIZATION, format!("Bearer {}", access_token))
      .body(Body::from(serde_json::to_vec(&serde_json::json!(
        model::action::CreateAction { desc: format!("{desc}"), value: None, category_id: None, approved: None }
      )).unwrap())).unwrap();

    routes::init(state).oneshot(req).await.unwrap()
  }
}