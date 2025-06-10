use std::sync::Arc;
use axum::{http::StatusCode, extract::{Path, State}, response::IntoResponse};
use crate::{state, model, routes::Json, errors::Error};

/// Login a user
/// 
/// - The first user created will automatically be assigned the admin role
/// - POST handler for `/users`
pub async fn create(State(state): State<Arc<state::State>>,
  Json(user): Json<model::CreateUser>) -> Result<impl IntoResponse, Error>
{
  // Check if we should assign the admin role to this user
  let admin = !model::user::any(state.db()).await?;

  // Create the user
  let id = model::user::insert(state.db(), &user.name, &user.email).await?;
  let user = model::user::fetch_by_id(state.db(), id).await?;

  // Now add the admin role if needed
  if admin {
    let admin_role_id = 1; // is auto populated and can't be be deleted
    model::user::assign_role(state.db(), user.id, admin_role_id).await?;
  }

  Ok((StatusCode::CREATED, Json(serde_json::json!(user))))
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