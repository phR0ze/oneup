# OneUp rust API

### Quick links
* [Overview](#overview)
  * [Configuration](#configuration)
  * [Web Server](#web-server)
  * [SQLx Migrations](#sqlx-migrations)

## Overview

### Configuration
A combination of `dotenvy` to set environment variables based on a `.env` file and then `envy` to 
load any configuration from the environment variables into a `serde` deserialized struct provides a 
nice approach to configuration.

**Example**
```.env
# IP and Port to listen on
IP=0.0.0.0
PORT=8080
LOG_LEVEL=info

# Database URL
DATABASE_URL=sqlite://sqlite.db
```

### Errors

### Web Server
[Axum is my chosen web framework](https://github.com/phR0ze/tech-docs/tree/main/src/development/languages/rust/web/axum).
It provides a modern Tokio and Tower compatible service that is quite flexible and intuitive.

### SQLx Migrations
1. Install SQLx CLI
   ```bash
   $ cargo install sqlx-cli --no-default-features --features rustls,sqlite
   ```
2. Create a migration script
   ```bash
   $ sqlx migrate add -r create_schema
   ```
3. Apply migration in code
   ```bash
   $ sqlx::migrate!().run(&pool).await?;
   ```
