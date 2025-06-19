use serde::{ Deserialize, Serialize};

/// Used during updates to change a role
#[derive(Debug, Deserialize, Serialize)]
pub struct RolePartial {
    pub name: String,
}

/// Full role object from database
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize, sqlx::FromRow)]
pub struct Role {
    pub id: i64,
    pub name: String,
    pub created_at: chrono::DateTime<chrono::Local>,
    pub updated_at: chrono::DateTime<chrono::Local>,
}