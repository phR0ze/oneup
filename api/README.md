# OneUp rust API

## SQLx Migrations
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