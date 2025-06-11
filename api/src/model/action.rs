use serde::{ Deserialize, Serialize};

/// Used during posts to create a new Action
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreateAction {
    pub(crate) desc: String,
    pub(crate) value: Option<i64>,
    pub(crate) category_id: Option<i64>,
}

/// Used during updates to change a Action
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UpdateAction {
    pub(crate) id: i64,
    pub(crate) desc: Option<String>,
    pub(crate) value: Option<i64>,
    pub(crate) category_id: Option<i64>,
}

/// Full Action object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Action {
    pub(crate) id: i64,
    pub(crate) desc: String,
    pub(crate) value: i64,
    pub(crate) category_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}
