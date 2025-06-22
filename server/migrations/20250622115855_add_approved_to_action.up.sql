-- Add approved column to action table
ALTER TABLE action ADD COLUMN approved INTEGER NOT NULL DEFAULT 0; 