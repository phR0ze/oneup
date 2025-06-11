use serde::{ Deserialize, Serialize};

/// Used during posts to create a new Category
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct CreateCategory {
    pub(crate) name: String,
}

/// Used during updates to change a Category
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct UpdateCategory {
    pub(crate) id: i64,
    pub(crate) name: String,
}

/// Full Category object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Category {
    pub(crate) id: i64,
    pub(crate) name: String,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}