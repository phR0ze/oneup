use chrono::{DateTime, Local};

/// Query parameter filters for various endpoints
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
pub struct Filter {
    pub user_id: Option<i64>,
    pub action_id: Option<i64>,
    pub start_date: Option<DateTime<Local>>,
    pub end_date: Option<DateTime<Local>>,
}

impl Filter {

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