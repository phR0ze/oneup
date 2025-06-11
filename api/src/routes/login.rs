use axum::{extract::{Path, Query, State}, http::StatusCode, response::IntoResponse};
use std::sync::Arc;
use crate::{db, state, model, errors::Error, routes::Json, security::auth};

/// Login a user and generate a token to be used in subsequent requests
pub async fn login(State(state): State<Arc<state::State>>,
    Json(dto): Json<model::LoginAttempt>) -> Result<impl IntoResponse, Error>
{
    // Get the user password from the database
    let password = db::password::fetch_active(state.db(), dto.user_id).await?;

    // Validate user credentials
    let credential = auth::Credential { salt: password.salt, hash: password.hash };
    auth::verify_password(&credential, &dto.password)?;

    // Generate JWT token
    let user = db::user::fetch_by_id(state.db(), dto.user_id).await?;
    // let token = auth::encode_jwt_token(&state.jwt_secret, &user)?;
    //Ok((StatusCode::OK, Json(serde_json::json!({ "token": token }))))
    Ok((StatusCode::OK, Json(serde_json::json!({ "token": "foo"}))))
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

}