use serde::{ Deserialize, Serialize};

/// Used during posts to create a new user
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreateUser {
    pub(crate) name: String,
    pub(crate) email: String,
}

/// Used during updates to change a user
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UpdateUser {
    pub(crate) id: i64,
    pub(crate) name: Option<String>,
    pub(crate) email: Option<String>,
}

/// Full user object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct User {
    pub(crate) id: i64,
    pub(crate) name: String,
    pub(crate) email: String,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}

/// Full user object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UserRole {
    pub(crate) id: i64,
    pub(crate) user_id: i64,
    pub(crate) role_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}