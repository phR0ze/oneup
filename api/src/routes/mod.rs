/*!
 * Axum routes and middleware configuration.
 */
use std::{sync::Arc, time::Duration};
use axum::{
    extract::Request, http::header, middleware, response::Response, routing::{delete, get, post, put}, Router
};
use tower_http::{
    cors, trace::TraceLayer,
};
use uuid::Uuid;
use http_body_util::BodyExt;

use crate::state;

// Exports
mod health;
mod auth;
mod users;
mod roles;
mod passwords;
mod actions;
mod categories;
mod points;
mod rewards;

/// Configure api routes
pub(crate) fn init(state: Arc::<state::State>) -> Router 
{
    // Disabling CORS across my routes for now
    // TODO: revisit harening this later
    let cors = cors::CorsLayer::new()
        .allow_origin(cors::Any)
        //.allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_methods(cors::Any)
        .allow_headers(cors::Any);
        //.allow_headers([header::CONTENT_TYPE]);

    // No authorization is required for these routes
    let public_routes = Router::new()
        .route("/health", get(health::get))
        .route("/login", post(auth::login))
        .route("/actions", get(actions::get))
        .route("/actions/{opt}", get(actions::get_by_id))
        .route("/categories", get(categories::get))
        .route("/categories/{opt}", get(categories::get_by_id))
        .route("/passwords", get(passwords::get))
        .route("/passwords/{opt}", get(passwords::get_by_id))
        .route("/roles", get(roles::get))
        .route("/roles/{opt}", get(roles::get_by_id))
        .route("/points", get(points::get).post(points::create))
        .route("/points/{opt}", get(points::get_by_id).put(points::update_by_id).delete(points::delete_by_id))
        .route("/points/sum", get(points::sum))
        .route("/rewards", get(rewards::get).post(rewards::create))
        .route("/rewards/sum", get(rewards::sum))
        .route("/rewards/{opt}", get(rewards::get_by_id).put(rewards::update_by_id).delete(rewards::delete_by_id))
        .route("/users",get(users::get))
        .route("/users/{opt}", get(users::get_by_id))
        .route("/users/{opt}/roles", get(users::get_roles));

    // Authorization is required for these routes
    let private_routes = Router::new()
        .route("/users", post(users::create))
        .route("/users/{opt}", put(users::update_by_id).delete(users::delete_by_id))
        .route("/passwords", post(passwords::create))
        .route("/passwords/{opt}", delete(passwords::delete_by_id))
        .route("/roles", post(roles::create))
        .route("/roles/{opt}", put(roles::update_by_id).delete(roles::delete_by_id))
        .route("/categories", post(categories::create))
        .route("/categories/{opt}", put(categories::update_by_id).delete(categories::delete_by_id))
        .route("/actions", post(actions::create))
        .route("/actions/{opt}", put(actions::update_by_id).delete(actions::delete_by_id))
        .layer(middleware::from_fn_with_state(state.clone(), auth::authorization));

    // Merge all routers into the final router
    Router::new()
        .merge(public_routes)
        .merge(private_routes)

        // Add CORS layer to allow cross-origin requests i.e. Swagger UI for development
        .layer(cors)

        // Add custom middleware to log request and response bodies on debug level
        .layer(middleware::from_fn(log_bodies_on_debug))

        // Add the tracing layer for observability
        .layer(TraceLayer::new_for_http()

            // Wrapping request with span information     
            .make_span_with(|request: &Request| {
                let method = request.method();
                let uri = request.uri().path();
                let request_id = Uuid::new_v4().simple().to_string()[..8].to_string();
                tracing::info_span!("request", id = %request_id, method = %method, uri = %uri)
            })
            .on_request(|request: &Request, _span: &tracing::Span| {
                tracing::info!("Started: {} {}", request.method(), request.uri());
            })
            .on_response(|response: &Response, latency: Duration, _span: &tracing::Span| {
                let length = response.headers().get(header::CONTENT_LENGTH)
                    .and_then(|v| v.to_str().ok())
                    .and_then(|v| v.parse::<usize>().ok())
                    .unwrap_or(0);
                tracing::info!("Response: {}, len: {}, in {:?}", response.status(), length, latency);
            })
        )
        // Add the state layer to access application state
        .with_state(state)
}

// -------------------------------------------------------------------------------------------------
// Custom middleware to log request and response bodies on debug level
// -------------------------------------------------------------------------------------------------
async fn log_bodies_on_debug(request: Request, next: middleware::Next) -> Response {
    // Log request body if present
    if tracing::enabled!(tracing::Level::DEBUG) {
        let (parts, body) = request.into_parts();
        let bytes = match body.collect().await {
            Ok(collected) => collected.to_bytes(),
            Err(_) => {
                tracing::debug!("Failed to collect request body");
                let request = Request::from_parts(parts, axum::body::Body::empty());
                let response = next.run(request).await;
                return response;
            }
        };
        
        if !bytes.is_empty() {
            if let Ok(json) = serde_json::from_slice::<serde_json::Value>(&bytes) {
                tracing::debug!("Request body: {}", json);
            } else {
                tracing::debug!("Request body (non-JSON): {} bytes", bytes.len());
            }
        }
        
        let request = Request::from_parts(parts, bytes.into());
        let response = next.run(request).await;
        
        // Log response body if present
        let (parts, body) = response.into_parts();
        let bytes = match body.collect().await {
            Ok(collected) => collected.to_bytes(),
            Err(_) => {
                tracing::debug!("Failed to collect response body");
                return Response::from_parts(parts, axum::body::Body::empty());
            }
        };
        
        if !bytes.is_empty() {
            if let Ok(json) = serde_json::from_slice::<serde_json::Value>(&bytes) {
                tracing::debug!("Response body: {}", json);
            } else {
                tracing::debug!("Response body (non-JSON): {} bytes", bytes.len());
            }
        }
        
        Response::from_parts(parts, bytes.into())
    } else {
        next.run(request).await
    }
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
impl<T: serde::Serialize> axum::response::IntoResponse for Json<T> 
{
    fn into_response(self) -> axum::response::Response 
    {
        let Self(value) = self;
        axum::Json(value).into_response()
    }
}

#[cfg(test)]
mod tests 
{
    use super::*;
    use axum::{
        body::Body, http::{header, Method, Request, StatusCode},
    };
    use http_body_util::BodyExt;
    use tower::ServiceExt;
    use crate::{db, model, state};

    // Helper test function to login as the admin user
    pub async fn login_as_admin(state: Arc<state::State>) -> (model::User, String)
    {
        let req = Request::builder().method(Method::POST)
            .uri("/login")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(serde_json::to_vec(&serde_json::json!(
                model::LoginRequest { handle: "admin".to_string(), password: "admin".to_string() }
            )).unwrap())).unwrap();
        let res = init(state.clone()).oneshot(req).await.unwrap();

        // Validate the response and return then admin user and access token
        assert_eq!(res.status(), StatusCode::OK);
        let bytes = res.into_body().collect().await.unwrap().to_bytes();
        let login_response: model::LoginResponse = serde_json::from_slice(&bytes).unwrap();

        let admin_user = db::user::fetch_by_handle(state.db(), "admin").await.unwrap();
        (admin_user, login_response.access_token)
    }
}