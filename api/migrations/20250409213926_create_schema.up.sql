
-- Create user table if it doesn't exist
CREATE TABLE IF NOT EXISTS user (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Create trigger to update the updated_at field on user name change
CREATE TRIGGER update_user AFTER UPDATE OF name ON user BEGIN
  UPDATE user SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Create password table if it doesn't exist
CREATE TABLE IF NOT EXISTS password (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  salt VARCHAR(255) NOT NULL,
  hash VARCHAR(255) NOT NULL,
  user_id INTEGER NOT NULL REFERENCES user(id) on DELETE CASCADE,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- No trigger to update as passwords are never updated only created or deleted

-- Create role table if it doesn't exist
CREATE TABLE IF NOT EXISTS role (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Create trigger to update the updated_at field on role changes
CREATE TRIGGER update_role AFTER UPDATE OF name ON role BEGIN
  UPDATE role SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Pre-populate role table with default values
INSERT OR IGNORE INTO role (name) VALUES ('admin');

-- Create user_role table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_role (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  user_id INTEGER NOT NULL REFERENCES user(id) on DELETE CASCADE,
  role_id INTEGER NOT NULL REFERENCES role(id) on DELETE CASCADE,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Create category table if it doesn't exist
CREATE TABLE IF NOT EXISTS category (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Create trigger to update the updated_at field on category name change
CREATE TRIGGER update_category AFTER UPDATE OF name ON category BEGIN
  UPDATE category SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Prepopulate category table with default values
INSERT OR IGNORE INTO category (name) VALUES ('Default');


-- Create action table if it doesn't exist
CREATE TABLE IF NOT EXISTS action (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  desc VARCHAR(255) NOT NULL UNIQUE,
  value INTEGER NOT NULL DEFAULT 0,
  category_id INTEGER NOT NULL DEFAULT 1 REFERENCES category(id) on DELETE SET DEFAULT,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Create trigger to update the updated_at field on action name change
CREATE TRIGGER update_action AFTER UPDATE OF name ON action BEGIN
  UPDATE action SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Prepopulate action table with default values
INSERT OR IGNORE INTO action (desc) VALUES ('Default');

-- Create reward table if it doesn't exist
-- Automatically delete any rows that match a delete user_id
CREATE TABLE IF NOT EXISTS reward (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  value INTEGER NOT NULL,
  user_id INTEGER NOT NULL REFERENCES user(id) on DELETE CASCADE,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Create trigger to update the updated_at field on reward on field changes
CREATE TRIGGER update_reward AFTER UPDATE OF value, user_id ON reward BEGIN
  UPDATE reward SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;

-- Create point table if it doesn't exist
-- Automatically delete any rows that match a deleted user_id
-- Automatically change the action value to 1 for any rows that match a deleted action_id
CREATE TABLE IF NOT EXISTS point (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  value INTEGER NOT NULL,
  user_id INTEGER NOT NULL REFERENCES user(id) on DELETE CASCADE,
  action_id INTEGER NOT NULL DEFAULT 1 REFERENCES action(id) on DELETE SET DEFAULT,
  created_at TIMESTAMP DATETIME DEFAULT(datetime('subsec')),
  updated_at TIMESTAMP DATETIME DEFAULT(datetime('subsec'))
);

-- Create trigger to update the updated_at field on point changes
CREATE TRIGGER update_point AFTER UPDATE OF value, user_id, action_id ON point BEGIN
  UPDATE point SET updated_at = CURRENT_TIMESTAMP WHERE id=NEW.id;
END;
