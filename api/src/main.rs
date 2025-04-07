use std::env;

fn main() {
    // Handle help command
    if env::args().len() == 1 || env::args().any(|x| x == "--help" || x == "-h") {
        usage();
        return;
    }

    // Handle other commands
    if let Some(cmd) = std::env::args().nth(1) {
        match cmd.as_str() {
            "token" => {
                println!("Generate a new api token...");
            }
            "run" => {
                println!("Running the project...");
                // Add run logic here
            }
            _ => {
                usage();
                return;
            }
        }
    }
}

fn usage() {
    println!("Usage: ./oneup [command]");
    println!("Commands:");
    println!("  token   Generate a new api token");
    println!("  run     Run the api server");
}