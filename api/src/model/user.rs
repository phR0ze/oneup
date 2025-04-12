use serde::{ Deserialize, Serialize};

/// Use during posts to create a new user
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct NewUser {
    pub(crate) name: String,
}

/// Full user object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct User {
    pub(crate) id: i64,
    pub(crate) name: String,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}