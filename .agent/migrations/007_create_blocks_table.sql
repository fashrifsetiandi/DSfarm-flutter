-- Migration: 007_create_blocks_table.sql
-- Create blocks table and update housings

-- Blocks table
CREATE TABLE IF NOT EXISTS blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  code VARCHAR(20) NOT NULL,
  name VARCHAR(100),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(farm_id, code)
);

-- RLS for blocks
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own blocks" ON blocks;
CREATE POLICY "Users can manage own blocks" ON blocks
  USING (farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid()));

-- Update housings table to include block reference
ALTER TABLE housings ADD COLUMN IF NOT EXISTS block_id UUID REFERENCES blocks(id) ON DELETE SET NULL;
ALTER TABLE housings ADD COLUMN IF NOT EXISTS position VARCHAR(20);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_housings_block_id ON housings(block_id);
CREATE INDEX IF NOT EXISTS idx_blocks_farm_id ON blocks(farm_id);
