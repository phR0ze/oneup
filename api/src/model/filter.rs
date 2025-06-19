use chrono::{DateTime, Local};

/// Query parameter filters for various endpoints
#[derive(Debug, Default, Clone, serde::Deserialize, serde::Serialize)]
pub struct Filter {
    pub user_id: Option<i64>,
    pub action_id: Option<i64>,
    pub role_id: Option<i64>,
    pub role_name: Option<String>,
    pub start_date: Option<DateTime<Local>>,
    pub end_date: Option<DateTime<Local>>,
}

impl Filter {

    /// Set the date range
    pub fn with_date_range(mut self, start: DateTime<Local>, end: DateTime<Local>) -> Self {
        self.start_date = Some(start);
        self.end_date = Some(end);
        self
    }

    /// Set the user id
    pub fn with_user_id(mut self, user_id: i64) -> Self {
        self.user_id = Some(user_id);
        self
    }

    /// Set the action id
    pub fn with_action_id(mut self, action_id: i64) -> Self {
        self.action_id = Some(action_id);
        self
    }

    /// Set the role id
    pub fn with_role_id(mut self, role_id: i64) -> Self {
        self.role_id = Some(role_id);
        self
    }

    /// Set the role name
    pub fn with_role_name(mut self, role_name: String) -> Self {
        self.role_name = Some(role_name);
        self
    }

    /// Set the role name
    /// Get the date range as DateTime objects if both dates are present
    pub fn date_range(&self) -> Option<(DateTime<Local>, DateTime<Local>)> {
        match (&self.start_date, &self.end_date) {
            (Some(start), Some(end)) => {
                Some((*start, *end))
            }
            _ => None,
        }
    }

    /// Are any of the filter values set?
    pub fn any(&self) -> bool {
        self.user_id.is_some() || self.action_id.is_some() || (self.start_date.is_some() && self.end_date.is_some())
    }
}