-- Remove approved column from action table
-- Note: SQLite doesn't support DROP COLUMN directly, so we need to recreate the table
-- This is a simplified version - in production you'd need to handle data migration

-- Create temporary table with new schema
CREATE TABLE action_temp (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  desc VARCHAR(255) NOT NULL UNIQUE,
  value INTEGER NOT NULL DEFAULT 0,
  category_id INTEGER NOT NULL DEFAULT 1 REFERENCES category(id) on DELETE SET DEFAULT,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Copy data from old table to new table
INSERT INTO action_temp (id, desc, value, category_id, created_at, updated_at)
SELECT id, desc, value, category_id, created_at, updated_at FROM action;

-- Drop old table
DROP TABLE action;

-- Rename new table to original name
ALTER TABLE action_temp RENAME TO action;

-- Recreate the trigger
CREATE TRIGGER update_action AFTER UPDATE OF desc ON action BEGIN
  UPDATE action SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END; 