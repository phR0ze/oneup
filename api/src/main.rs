use axum::{routing::get, Router};
use tokio::net::TcpListener;

mod model;
mod routes;
mod state;
mod utils;

const APP_NAME: &str = "oneup";

#[tokio::main]
async fn main() -> anyhow::Result<()> {

  // Init configuration, observability and state
  let config = utils::load_config()?;
  utils::observe(APP_NAME, &config);
  let state = state::load(config).await?;

  // Configure api routes
  let app = Router::new().route("/health", get(routes::health));

  // Init api server
  let binding = format!("{}:{}", state.ip(), state.port());
  let listener = TcpListener::bind(&binding).await.unwrap();
  log::info!("Server started at: {}", binding);
  axum::serve(listener, app.into_make_service()).await?;

  Ok(())
}

// use std::env;

// fn main() {
//   // Handle help command
//   if env::args().len() == 1 || env::args().any(|x| x == "--help" || x == "-h") {
//     usage();
//     return;
//   }

//   // Handle other commands
//   if let Some(cmd) = std::env::args().nth(1) {
//     match cmd.as_str() {
//       "token" => {
//         log::info!("Generate a new api token...");
//       }
//       "run" => {
//         log::info!("Running the project...");
//         // Add run logic here
//       }
//       _ => {
//         usage();
//         return;
//       }
//     }
//   }
// }

// /// Command line usage
// fn usage() {
//   println!("Usage: ./oneup [command]");
//   println!("Commands:");
//   println!("  token   Generate a new api token");
//   println!("  run     Run the api server");
// }