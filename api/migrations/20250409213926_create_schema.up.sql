
-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create trigger to update the updated_at field on user name change
CREATE TRIGGER update_users AFTER UPDATE OF name ON users BEGIN
  UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Create passwords table if it doesn't exist
CREATE TABLE IF NOT EXISTS passwords (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  salt VARCHAR(255) NOT NULL,
  hash VARCHAR(255) NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) on DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create trigger to update the updated_at field on password changes
CREATE TRIGGER update_passwords AFTER UPDATE OF salt, hash ON passwords BEGIN
  UPDATE passwords SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Create categories table if it doesn't exist
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create trigger to update the updated_at field on categories name change
CREATE TRIGGER update_categories AFTER UPDATE OF name ON categories BEGIN
  UPDATE categories SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Prepopulate categories table with default values
INSERT OR IGNORE INTO categories (name) VALUES ('Default');

-- Create rewards table if it doesn't exist
-- Automatically delete any rows that match a delete user_id
CREATE TABLE IF NOT EXISTS rewards (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  value INTEGER NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) on DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create trigger to update the updated_at field on rewards on field changes
CREATE TRIGGER update_rewards AFTER UPDATE OF value, user_id ON rewards BEGIN
  UPDATE rewards SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Create points table if it doesn't exist
-- Automatically delete any rows that match a delete user_id
-- Automatically change the category value to 1 for any rows that match a delete category_id
CREATE TABLE IF NOT EXISTS points (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  value INTEGER NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) on DELETE CASCADE,
  category_id INTEGER NOT NULL DEFAULT 1 REFERENCES categories(id) on DELETE SET DEFAULT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create trigger to update the updated_at field on points changes
CREATE TRIGGER update_points AFTER UPDATE OF value, user_id, category_id ON points BEGIN
  UPDATE points SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;
