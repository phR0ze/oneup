use axum::{response::IntoResponse, routing::get, Json, Router};
use model::Config;
use tokio::net::TcpListener;

mod model;
mod state;
mod utils;

const APP_NAME: &str = "oneup";

#[tokio::main]
async fn main() {
  utils::observe(APP_NAME);
  let state = state::load().await;

  // state.db.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT NOT NULL)").await.unwrap();

  // Initialize api server
  // let app = Router::new().route("/health", get(health_handler));

  // log::info!("Server started successfully at 0.0.0.0:8080");

  // let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
  // axum::serve(listener, app.into_make_service())
  //     .await
  //     .unwrap();
}

pub async fn health_handler() -> impl IntoResponse {
    const MESSAGE: &str = "API Services";

    let res = serde_json::json!({
        "status": "ok",
        "message": MESSAGE
    });

    Json(res)
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