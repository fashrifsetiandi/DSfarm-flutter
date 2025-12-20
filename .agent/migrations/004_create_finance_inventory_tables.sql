-- ═══════════════════════════════════════════════════════════
-- DSFARM SUPABASE MIGRATION - WEEK 5
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
-- FINANCE CATEGORIES TABLE
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS finance_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  icon TEXT,
  is_system BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT category_type_check CHECK (
    type IN ('income', 'expense')
  ),
  UNIQUE(farm_id, name, type)
);

CREATE INDEX IF NOT EXISTS idx_finance_categories_farm ON finance_categories(farm_id);
ALTER TABLE finance_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own categories" ON finance_categories
  FOR ALL USING (
    farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid())
  );

-- ═══════════════════════════════════════════════════════════
-- FINANCE TRANSACTIONS TABLE
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS finance_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES finance_categories(id) ON DELETE RESTRICT,
  type TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  transaction_date DATE NOT NULL,
  description TEXT,
  reference_id UUID,
  reference_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  
  CONSTRAINT transaction_type_check CHECK (
    type IN ('income', 'expense')
  )
);

CREATE INDEX IF NOT EXISTS idx_transactions_farm ON finance_transactions(farm_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON finance_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON finance_transactions(type);
ALTER TABLE finance_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own transactions" ON finance_transactions
  FOR ALL USING (
    farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid())
  );

-- ═══════════════════════════════════════════════════════════
-- INVENTORY ITEMS TABLE
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  unit TEXT,
  quantity DECIMAL(10,2) DEFAULT 0,
  minimum_stock DECIMAL(10,2),
  unit_price DECIMAL(12,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  
  CONSTRAINT inventory_type_check CHECK (
    type IN ('feed', 'medicine', 'equipment', 'supply')
  ),
  UNIQUE(farm_id, name)
);

CREATE INDEX IF NOT EXISTS idx_inventory_farm ON inventory_items(farm_id);
CREATE INDEX IF NOT EXISTS idx_inventory_type ON inventory_items(type);
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own inventory" ON inventory_items
  FOR ALL USING (
    farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid())
  );

-- ═══════════════════════════════════════════════════════════
-- STOCK MOVEMENTS TABLE
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  movement_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT movement_type_check CHECK (
    type IN ('purchase', 'usage', 'adjustment')
  )
);

CREATE INDEX IF NOT EXISTS idx_movements_item ON stock_movements(inventory_item_id);
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own movements" ON stock_movements
  FOR ALL USING (
    inventory_item_id IN (
      SELECT id FROM inventory_items 
      WHERE farm_id IN (SELECT id FROM farms WHERE user_id = auth.uid())
    )
  );

-- ═══════════════════════════════════════════════════════════
-- VERIFY
-- ═══════════════════════════════════════════════════════════

SELECT 'Tables created successfully' as status;
