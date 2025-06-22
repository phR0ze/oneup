use serde::{ Deserialize, Serialize};

/// Used during posts to create a new Action
#[derive(Debug, Default, Deserialize, Serialize)]
pub struct CreateAction {
  pub desc: String,
  pub value: Option<i64>,
  pub category_id: Option<i64>,
  pub approved: Option<bool>,
}

impl CreateAction {
    /// Create a new default CreateAction
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the description
    pub fn with_desc(mut self, desc: impl Into<String>) -> Self {
        self.desc = desc.into();
        self
    }

    /// Set the value
    pub fn with_value(mut self, value: i64) -> Self {
        self.value = Some(value);
        self
    }

    /// Set the category ID
    pub fn with_category_id(mut self, category_id: i64) -> Self {
        self.category_id = Some(category_id);
        self
    }

    /// Set approved status
    pub fn with_approved(mut self, approved: bool) -> Self {
        self.approved = Some(approved);
        self
    }
}


/// Used during updates to change a Action
#[derive(Debug, Default, Deserialize, Serialize)]
pub struct UpdateAction {
  pub desc: Option<String>,
  pub value: Option<i64>,
  pub category_id: Option<i64>,
  pub approved: Option<bool>,
}

impl UpdateAction {
    /// Create a new default UpdateAction
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the description
    pub fn with_desc(mut self, desc: impl Into<String>) -> Self {
        self.desc = Some(desc.into());
        self
    }

    /// Set the value
    pub fn with_value(mut self, value: i64) -> Self {
        self.value = Some(value);
        self
    }

    /// Set the category ID
    pub fn with_category_id(mut self, category_id: i64) -> Self {
        self.category_id = Some(category_id);
        self
    }

    /// Set approved status
    pub fn with_approved(mut self, approved: bool) -> Self {
        self.approved = Some(approved);
        self
    }
}


/// Full Action object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct Action {
  pub id: i64,
  pub desc: String,
  pub value: i64,
  pub category_id: i64,
  pub approved: bool,
  pub created_at: chrono::DateTime<chrono::Local>,
  pub updated_at: chrono::DateTime<chrono::Local>,
}