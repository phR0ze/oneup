
#[derive(Debug, sqlx::FromRow)]
pub(crate) struct User {
    id: i32,
    username: String,
}
