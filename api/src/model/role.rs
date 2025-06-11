use serde::{ Deserialize, Serialize};

/// Used during posts to create a new role
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct CreateRole {
    pub(crate) name: String,
}

/// Used during updates to change a role
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct UpdateRole {
    pub(crate) id: i64,
    pub(crate) name: String,
}

/// Full role object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Role {
    pub(crate) id: i64,
    pub(crate) name: String,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}