-- ═══════════════════════════════════════════════════════════
-- DSFARM SUPABASE MIGRATION - WEEK 2
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- Create farms table
CREATE TABLE IF NOT EXISTS farms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  animal_type TEXT NOT NULL DEFAULT 'rabbit',
  location TEXT,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT farms_animal_type_check CHECK (
    animal_type IN ('rabbit', 'goat', 'fish', 'poultry')
  )
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_farms_user_id ON farms(user_id);
CREATE INDEX IF NOT EXISTS idx_farms_animal_type ON farms(animal_type);

-- Enable Row Level Security
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only see their own farms
CREATE POLICY "Users can view own farms"
  ON farms FOR SELECT
  USING (user_id = auth.uid());

-- Users can create farms for themselves
CREATE POLICY "Users can create own farms"
  ON farms FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update their own farms
CREATE POLICY "Users can update own farms"
  ON farms FOR UPDATE
  USING (user_id = auth.uid());

-- Users can delete their own farms
CREATE POLICY "Users can delete own farms"
  ON farms FOR DELETE
  USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- VERIFY
-- ═══════════════════════════════════════════════════════════

-- Check if table was created
SELECT * FROM farms LIMIT 1;
