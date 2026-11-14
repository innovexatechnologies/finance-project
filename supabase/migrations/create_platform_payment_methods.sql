-- ============================================================================
-- SKILLBRIDGE - PLATFORM PAYMENT METHODS & ESCROW SETTINGS
-- Migration File: supabase/migrations/create_platform_payment_methods.sql
-- ============================================================================

-- 1. CREATE TABLE
CREATE TABLE IF NOT EXISTS public.platform_payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  method_type TEXT NOT NULL,                     -- 'Bank Account', 'JazzCash', 'EasyPaisa', 'NayaPay'
  bank_or_wallet_name TEXT NOT NULL,             -- 'Meezan Bank', 'HBL', 'JazzCash', 'EasyPaisa', 'NayaPay'
  account_title TEXT NOT NULL,                   -- e.g. 'SkillBridge Escrow Services'
  account_number TEXT NOT NULL,                  -- Account or Mobile Number
  iban TEXT,                                     -- Optional IBAN for bank accounts
  instructions TEXT,                             -- Special instructions shown to company during checkout
  is_active BOOLEAN NOT NULL DEFAULT true,       -- Active / Inactive toggle
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. INDEXES
CREATE INDEX IF NOT EXISTS idx_platform_payment_methods_active 
  ON public.platform_payment_methods (is_active);

CREATE INDEX IF NOT EXISTS idx_platform_payment_methods_type 
  ON public.platform_payment_methods (method_type);

-- 3. UPDATED_AT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.handle_platform_payment_methods_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_platform_payment_methods_updated_at ON public.platform_payment_methods;
CREATE TRIGGER trg_platform_payment_methods_updated_at
  BEFORE UPDATE ON public.platform_payment_methods
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_platform_payment_methods_updated_at();

-- 4. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.platform_payment_methods ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Platform Payment Methods Admin Manage" ON public.platform_payment_methods;
DROP POLICY IF EXISTS "Platform Payment Methods Read Active" ON public.platform_payment_methods;

-- Policy 1: Full CRUD for Administrators only
CREATE POLICY "Platform Payment Methods Admin Manage"
  ON public.platform_payment_methods
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Policy 2: Authenticated Users (Company / Students) can ONLY read active payment methods
-- Administrators can read all records (active and inactive)
CREATE POLICY "Platform Payment Methods Read Active"
  ON public.platform_payment_methods
  FOR SELECT
  TO authenticated
  USING (is_active = true OR public.is_admin());

-- 5. INITIAL SEED DATA (Default Escrow Payment Accounts)
INSERT INTO public.platform_payment_methods (
  method_type,
  bank_or_wallet_name,
  account_title,
  account_number,
  iban,
  instructions,
  is_active
)
SELECT
  'Bank Account',
  'Meezan Bank Ltd',
  'SkillBridge Escrow Services Pvt Ltd',
  '01020304050607',
  'PK36MEZN0001020304050607',
  'Please transfer the exact project amount. In the transfer purpose or memo, include your Project ID.',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.platform_payment_methods WHERE bank_or_wallet_name = 'Meezan Bank Ltd'
);

INSERT INTO public.platform_payment_methods (
  method_type,
  bank_or_wallet_name,
  account_title,
  account_number,
  iban,
  instructions,
  is_active
)
SELECT
  'JazzCash',
  'JazzCash Merchant',
  'SkillBridge Admin Escrow',
  '03001234567',
  NULL,
  'Send project funding via JazzCash Till / Mobile Account. Save the 12-digit TID and screenshot.',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.platform_payment_methods WHERE bank_or_wallet_name = 'JazzCash Merchant'
);

INSERT INTO public.platform_payment_methods (
  method_type,
  bank_or_wallet_name,
  account_title,
  account_number,
  iban,
  instructions,
  is_active
)
SELECT
  'EasyPaisa',
  'EasyPaisa Wallet',
  'SkillBridge Admin Escrow',
  '03451234567',
  NULL,
  'Send project funding via EasyPaisa. Retain the Transaction ID (TRX ID) and payment confirmation slip.',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.platform_payment_methods WHERE bank_or_wallet_name = 'EasyPaisa Wallet'
);

INSERT INTO public.platform_payment_methods (
  method_type,
  bank_or_wallet_name,
  account_title,
  account_number,
  iban,
  instructions,
  is_active
)
SELECT
  'NayaPay',
  'NayaPay Wallet',
  'SkillBridge Admin Escrow',
  '03331234567',
  NULL,
  'Pay via NayaPay to NayaPay ID @skillbridge or account number. Upload receipt screenshot after transfer.',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.platform_payment_methods WHERE bank_or_wallet_name = 'NayaPay Wallet'
);

-- 6. RELOAD SCHEMA CACHE
NOTIFY pgrst, 'reload schema';

