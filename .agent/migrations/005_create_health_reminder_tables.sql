-- ═══════════════════════════════════════════════════════════
-- DSFARM SUPABASE MIGRATION - WEEK 6
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
-- HEALTH RECORDS TABLE
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS health_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  livestock_id UUID REFERENCES livestocks(id) ON DELETE CASCADE,
  offspring_id UUID REFERENCES offsprings(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  record_date DATE NOT NULL,
  medicine TEXT,
  dosage TEXT,
  cost DECIMAL(12,2),
  notes TEXT,
  next_due_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT health_type_check CHECK (
    type IN ('vaccination', 'illness', 'treatment', 'checkup', 'deworming')
  )
);

CREATE INDEX IF NOT EXISTS idx_health_farm ON health_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_health_livestock ON health_records(livestock_id);
CREATE INDEX IF NOT EXISTS idx_health_offspring ON health_records(offspring_id);
CREATE INDEX IF NOT EXISTS idx_health_date ON health_records(record_date);
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own health records" ON health_records
  FOR ALL USING (
    farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid())
  );

-- ═══════════════════════════════════════════════════════════
-- REMINDERS TABLE
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE NOT NULL,
  reference_id UUID,
  reference_type TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT reminder_type_check CHECK (
    type IN ('palpation', 'expected_birth', 'weaning', 'vaccination', 'health_check', 'mating', 'custom')
  )
);

CREATE INDEX IF NOT EXISTS idx_reminder_farm ON reminders(farm_id);
CREATE INDEX IF NOT EXISTS idx_reminder_due ON reminders(due_date);
CREATE INDEX IF NOT EXISTS idx_reminder_completed ON reminders(is_completed);
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own reminders" ON reminders
  FOR ALL USING (
    farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid())
  );

-- ═══════════════════════════════════════════════════════════
-- ADD LINEAGE COLUMNS TO LIVESTOCKS
-- ═══════════════════════════════════════════════════════════

ALTER TABLE livestocks 
  ADD COLUMN IF NOT EXISTS dam_id UUID REFERENCES livestocks(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS sire_id UUID REFERENCES livestocks(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_livestock_dam ON livestocks(dam_id);
CREATE INDEX IF NOT EXISTS idx_livestock_sire ON livestocks(sire_id);

-- ═══════════════════════════════════════════════════════════
-- VERIFY
-- ═══════════════════════════════════════════════════════════

SELECT 'Tables created successfully' as status;
