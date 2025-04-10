use sqlx::sqlite::{ SqlitePool, Sqlite };
use sqlx::migrate::Migrator;
use dotenvy::dotenv;
use super::model::Config;

// Embed migrations from the `./migrations` directory into the app.
// - Relative to the project root i.e. where `Cargo.toml` is located.
static MIGRATOR: Migrator = sqlx::migrate!();

/// Application state
pub(crate) struct State {
  pub(crate) db: SqlitePool,
}

/// Load state
/// - Load configuration
/// - Connect to the database
/// - TODO: add error handling
pub(crate) async fn load() -> State {

  // Load configuration
  let config = load_config();

  // Connect to the database
  let db = db_connect(&config.db_url).await;

  // Return state
  State { db }
}

/// Load configuration
/// - Prioritize cli flags, then env vars, then .env file, then config file
/// - TODO: add config file support
/// - TODO: support reading env vars first before .env overrides them
/// - TODO: return a Result instead of panicking
/// - TODO: add logging
fn load_config() -> Config {

  // Optionally set environment variables based on .env file
  dotenv().ok();

  // Load configuration from environment variables
  match envy::from_env::<Config>() {
    Ok(config) => {
      println!("Configuration loaded: \n  {:?}", config);
      return config
    },
    Err(e) => panic!("Error loading configuration: {}", e),
  }
}

/// Connect to the given DB
/// - Creates a new SQLite database if needed
/// - Returns a connection pool
/// - TODO: add error handling
/// - TODO: add logging
async fn db_connect(db_url: &str) -> SqlitePool {

  // Open a connection to the DB, creating if needed
  let pool = match SqlitePool::connect(db_url).await {
    Ok(pool) => {
      println!("Database connection pool created successfully");
      return pool;
    },
    Err(e) => panic!("Error creating database connection: {}", e),
  };

  // // Run migrations automatically to ensure the database is up to date
  // match sqlx::migrate!("../migrations").run(&pool).await {
  //   Ok(pool) => {
  //     println!("Database migrations applied successfully");
  //     return pool;
  //   },
  //   Err(e) => panic!("Error applying migrations: {}", e),
  // }
}
