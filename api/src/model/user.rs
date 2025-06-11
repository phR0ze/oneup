use serde::{ Deserialize, Serialize};

/// Used during posts to create a new user
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct CreateUser {
    pub(crate) name: String,
    pub(crate) email: String,
}

/// Used during updates to change a user
#[derive(Debug, Deserialize, Serialize)]
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

/// Used as a response to user role requests
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UserRole {
    pub(crate) id: i64,
    pub(crate) name: String,
}