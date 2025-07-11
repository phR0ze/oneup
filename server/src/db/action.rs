use sqlx::SqlitePool;
use axum::http::StatusCode;
use crate::{ errors, model };

/// Insert a new Action into the database
/// 
/// - error on empty desc
/// - error on duplicate desc
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***action*** - CreateAction struct containing the action data
/// 
/// #### Returns
/// - ***id*** - id of the action
pub async fn insert(db: &SqlitePool, action: &model::CreateAction) -> errors::Result<i64>
{
  validate_desc(&action.desc)?;

  // Validate and set defaults
  let value = action.value.unwrap_or(0);
  let category_id = action.category_id.unwrap_or(1);
  let approved = if action.approved.unwrap_or(false) { 1 } else { 0 };

  // Create new Action in database
  let result = sqlx::query(r#"INSERT INTO action (desc, value, category_id, approved) VALUES (?, ?, ?, ?)"#)
    .bind(&action.desc).bind(value).bind(category_id).bind(approved).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {

      // Error on duplicates
      if errors::Error::is_sqlx_unique_violation(&e) {
        let msg = format!("Action '{}' already exists", action.desc);
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      }

      // Error on entity not found
      if errors::Error::is_sqlx_foreign_key_constraint_failed(&e) {
        let msg = format!("Invalid category_id '{category_id}'");
        log::warn!("{msg}");
        return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
      }

      // Error on other SQL errors
      let msg = format!("Error inserting action '{}'", action.desc);
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get an action by id from the database
/// 
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***id*** - id of the action to fetch
/// 
/// #### Returns
/// - ***action*** - action entry
pub async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::Action>
{
  let result = sqlx::query_as::<_, model::Action>(r#"SELECT * FROM action WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(action) => Ok(action),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("Action with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching action with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all actions from the database
/// 
/// - orders the actions by desc ignoring case
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***db*** - database connection pool
/// - ***filter*** - supports:
///   - ***approved=***
/// 
/// #### Returns
/// - ***actions*** - actions entries
pub async fn fetch_all(db: &SqlitePool, filter: model::Filter) ->
  errors::Result<Vec<model::Action>>
{
  let result = if !filter.any_action_filters() {

    // Get all actions when no filter options are specified
    sqlx::query_as::<_, model::Action>(r#"SELECT * FROM action ORDER BY LOWER(desc)"#)
      .fetch_all(db).await
  } else {

    // Get actions with the given filter
    let where_clause = filter.to_actions_where_clause(db).await?;
    let query_str = format!(r#"SELECT * FROM action {where_clause} ORDER BY LOWER(desc)"#);
    let mut query = sqlx::query_as::<_, model::Action>(&query_str);
    if let Some(approved) = filter.approved {
      query = query.bind(approved);
    }
    query.fetch_all(db).await
  };

  match result {
    Ok(actions) => Ok(actions),
    Err(e) => {
      let msg = format!("Error fetching actions");
      log::error!("{msg}");
      Err(errors::Error::from_sqlx(e, &msg))
    }
  }

}

/// Update a Action in the database
/// 
/// - error on not found
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***id*** id of the action to update
/// - ***action*** UpdateAction struct containing the fields to update
pub async fn update_by_id(db: &SqlitePool, id: i64, action: &model::UpdateAction) -> errors::Result<()>
{
  let existing_action = fetch_by_id(db, id).await?;

  // Validate and set defaults
  let desc = action.desc.as_deref().unwrap_or(&existing_action.desc);
  let value = action.value.unwrap_or(existing_action.value);
  let category_id = action.category_id.unwrap_or(existing_action.category_id);
  let approved = if action.approved.unwrap_or(existing_action.approved) { 1 } else { 0 };
  validate_desc(&desc)?;

  // Update action in database
  let result = sqlx::query(r#"UPDATE action SET desc = ?, value = ?, category_id = ?, approved = ? WHERE id = ?"#)
    .bind(&desc).bind(value).bind(category_id).bind(approved).bind(&id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error updating action with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

/// Delete a Action in the database
/// 
/// - error on other SQL errors
/// 
/// #### Parameters
/// - ***id*** id of the action to delete
pub async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()>
{
  // Don't allow deletion of the Unspecified action
  if id == 1 {
    let msg = format!("Cannot delete 'Unspecified' action");
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
  }

  let result = sqlx::query(r#"DELETE from action WHERE id = ?"#).bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting action with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

// Helper for desc not given error
fn validate_desc(desc: &str) -> errors::Result<()>
{
  if desc.is_empty() {
    let msg = "Action desc value is required";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests
{
  use super::*;
  use crate::{db, state};

  #[tokio::test]
  async fn test_delete_success()
  {
    let state = state::test().await;
    let action1 = "action1";
    let create_action = model::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    let id = insert(state.db(), &create_action).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_delete_failure_on_default()
  {
    let state = state::test().await;

    let err = delete_by_id(state.db(), 1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Cannot delete 'Unspecified' action"));

    let action = fetch_by_id(state.db(), 1).await.unwrap();
    assert_eq!(action.id, 1);
    assert_eq!(action.desc, "Unspecified");
  }

  #[tokio::test]
  async fn test_update_success()
  {
    let state = state::test().await;
    let action1 = "action1";
    let action2 = "action2";
    let category1 = "category1";
    let create_action = model::CreateAction {
      desc: action1.to_string(),
      value: Some(2),
      category_id: None,
      approved: None,
    };
    let id = insert(state.db(), &create_action).await.unwrap();
    let category_id = db::category::insert(state.db(), category1).await.unwrap();

    update_by_id(state.db(), id, &model::UpdateAction {
      desc: Some(action2.to_string()),
      value: Some(3),
      category_id: Some(category_id),
      approved: Some(true),
    }).await.unwrap();

    let action = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(action.id, 2);
    assert_eq!(action.desc, action2);
    assert_eq!(action.value, 3);
    assert_eq!(action.category_id, category_id);
  }

  #[tokio::test]
  async fn test_update_failure_no_desc()
  {
    let state = state::test().await;
    let action1 = "action1";
    let create_action = model::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    let id = insert(state.db(), &create_action).await.unwrap();

    let err = update_by_id(state.db(), id, &model::UpdateAction {
      desc: Some("".to_string()),
      value: None,
      category_id: None,
      approved: None,
    }).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Action desc value is required"));
  }

  #[tokio::test]
  async fn test_update_failure_not_found()
  {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, &model::UpdateAction {
      desc: None,
      value: None,
      category_id: None,
      approved: None,
    }).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Action with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success()
  {
    let state = state::test().await;
    let action1 = "action1";

    // Insert a new Action
    let create_action = model::CreateAction {
      desc: action1.to_string(),
      value: Some(2),
      category_id: None,
      approved: None,
    };
    let id = insert(state.db(), &create_action).await.unwrap();
    assert_eq!(id, 2);

    let action = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(action.id, 2);
    assert_eq!(action.desc, action1);
    assert_eq!(action.value, 2);
    assert_eq!(action.category_id, 1);
    assert!(action.created_at <= chrono::Local::now());
    assert!(action.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_all_approved() {
    let state = state::test().await;
    let action1 = "action1";
    let action2 = "action2";

    // Insert two actions with different approval status
    let create_action1 = model::CreateAction::new()
      .with_desc(action1)
      .with_approved(true);
    let id1 = insert(state.db(), &create_action1).await.unwrap();

    let create_action2 = model::CreateAction::new()
      .with_desc(action2)
      .with_approved(false);
    insert(state.db(), &create_action2).await.unwrap();

    // Fetch only approved actions
    let filter = model::Filter::new().with_approved(true);
    let actions = fetch_all(state.db(), filter).await.unwrap();

    // Should only get the approved action
    assert_eq!(actions.len(), 1);
    assert_eq!(actions[0].id, id1);
    assert_eq!(actions[0].desc, action1);
    assert_eq!(actions[0].approved, true);
  }

  #[tokio::test]
  async fn test_fetch_all_success()
  {
    let state = state::test().await;
    let action1 = "action1";
    let action2 = "action2";

    let create_action2 = model::CreateAction {
      desc: action2.to_string(),
      value: Some(2),
      category_id: None,
      approved: None,
    };
    insert(state.db(), &create_action2).await.unwrap();
    std::thread::sleep(std::time::Duration::from_millis(2));
    let create_action1 = model::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    insert(state.db(), &create_action1).await.unwrap();
    let actions = fetch_all(state.db(), model::Filter::new()).await.unwrap();
    assert_eq!(actions.len(), 3);

    assert_eq!(actions[0].id, 3);
    assert_eq!(actions[0].desc, action1);
    assert_eq!(actions[0].value, 0);
    assert_eq!(actions[0].category_id, 1);
    assert!(actions[0].created_at <= chrono::Local::now());
    assert!(actions[0].updated_at <= chrono::Local::now());

    assert_eq!(actions[1].id, 2);
    assert_eq!(actions[1].desc, action2);
    assert_eq!(actions[1].value, 2);
    assert_eq!(actions[1].category_id, 1);
    assert!(actions[1].created_at <= chrono::Local::now());
    assert!(actions[1].updated_at <= chrono::Local::now());

    assert_eq!(actions[2].id, 1);
    assert_eq!(actions[2].desc, "Unspecified");
    assert_eq!(actions[2].value, 0);
    assert_eq!(actions[2].category_id, 1);
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found()
  {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("Action with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_failure_duplicate()
  {
    let state = state::test().await;
    let action1 = "action1";

    let create_action = model::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    insert(state.db(), &create_action).await.unwrap();
    let err = insert(state.db(), &create_action).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::CONFLICT);
    assert_eq!(err.msg, format!("Action '{action1}' already exists"));
  }

  #[tokio::test]
  async fn test_insert_failure_empty_desc()
  {
    let state = state::test().await;

    let create_action = model::CreateAction {
      desc: "".to_string(),
      value: None,
      category_id: None,
      approved: None,
    };
    let err = insert(state.db(), &create_action).await.unwrap_err();
    let err = err.as_http().unwrap();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, "Action desc value is required");
  }

  #[tokio::test]
  async fn test_insert_failure_invalid_category_id()
  {
    let state = state::test().await;
    let action1 = "action1";

    let create_action = model::CreateAction {
      desc: action1.to_string(),
      value: None,
      category_id: Some(-1),
      approved: None,
    };
    let err = insert(state.db(), &create_action).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(err.msg, format!("Invalid category_id '-1'"));
  }
}