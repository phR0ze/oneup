use serde::{ Deserialize, Serialize};

/// Used during posts to create a new user
#[derive(Debug, Deserialize, Serialize)]
pub struct CreateUser {
    pub username: String,
    pub email: String,
}

/// Used during updates to change a user
#[derive(Debug, Deserialize, Serialize)]
pub struct UpdateUser {
    pub id: i64,
    pub username: Option<String>,
    pub email: Option<String>,
}

/// Full user object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct User {
    pub id: i64,
    pub username: String,
    pub email: String,
    pub created_at: chrono::DateTime<chrono::Local>,
    pub updated_at: chrono::DateTime<chrono::Local>,
}

/// Used as a response to user role requests
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize, sqlx::FromRow)]
pub struct UserRole {
    pub id: i64,
    pub name: String,
}