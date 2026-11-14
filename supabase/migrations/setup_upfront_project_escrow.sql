-- ============================================================================
-- SKILLBRIDGE - UPFRONT PLATFORM-MANAGED CUSTODIAL ESCROW MIGRATION
-- Migration File: supabase/migrations/setup_upfront_project_escrow.sql
-- ============================================================================

-- 1. ADD / VERIFY ESCROW COLUMNS ON PROJECTS TABLE
ALTER TABLE public.projects 
  ADD COLUMN IF NOT EXISTS escrow_amount NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS payment_method_used TEXT,
  ADD COLUMN IF NOT EXISTS transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS payment_receipt_url TEXT,
  ADD COLUMN IF NOT EXISTS is_escrow_verified BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Ensure default status for newly created projects is 'pending_payment'
ALTER TABLE public.projects 
  ALTER COLUMN status SET DEFAULT 'pending_payment';

-- 2. CREATE PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_projects_escrow_status 
  ON public.projects (status, is_escrow_verified);

CREATE INDEX IF NOT EXISTS idx_projects_transaction_id 
  ON public.projects (transaction_id);

CREATE INDEX IF NOT EXISTS idx_projects_company_status 
  ON public.projects (company_id, status);

-- 3. SETUP STORAGE BUCKET FOR PAYMENT RECEIPTS
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'payment_receipts',
  'payment_receipts',
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf'];

-- Storage RLS Policies
DROP POLICY IF EXISTS "Companies and Authenticated Users Upload Receipts" ON storage.objects;
DROP POLICY IF EXISTS "Public and Admins Read Receipts" ON storage.objects;
DROP POLICY IF EXISTS "Admins Full Access to Receipts" ON storage.objects;

-- Policy 1: Authenticated users can upload payment receipt screenshots
CREATE POLICY "Companies and Authenticated Users Upload Receipts"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'payment_receipts');

-- Policy 2: Allow reading payment receipts (public URL or authenticated)
CREATE POLICY "Public and Admins Read Receipts"
  ON storage.objects
  FOR SELECT
  TO authenticated, anon
  USING (bucket_id = 'payment_receipts');

-- Policy 3: Admins can update/delete receipts if needed
CREATE POLICY "Admins Full Access to Receipts"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'payment_receipts' AND public.is_admin())
  WITH CHECK (bucket_id = 'payment_receipts' AND public.is_admin());

-- 4. ROW LEVEL SECURITY (RLS) POLICIES ON PROJECTS TABLE
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Drop obsolete / conflicting policies if any
DROP POLICY IF EXISTS "Projects Student Read Verified Open" ON public.projects;
DROP POLICY IF EXISTS "Projects Company Manage Own" ON public.projects;
DROP POLICY IF EXISTS "Projects Company Update Proof" ON public.projects;
DROP POLICY IF EXISTS "Projects Admin Full Manage" ON public.projects;
DROP POLICY IF EXISTS "Projects Public Read" ON public.projects;

-- Policy A: Students can ONLY read projects that are live & verified (status = 'open' AND is_escrow_verified = true)
-- Or projects where the student has an assigned role or active application
CREATE POLICY "Projects Student Read Verified Open"
  ON public.projects
  FOR SELECT
  TO authenticated
  USING (
    -- Live verified projects open to students
    (LOWER(status) = 'open' AND is_escrow_verified = true)
    OR
    -- Company viewing their own projects (even if pending payment/verification)
    (posted_by = auth.uid() OR user_id = auth.uid())
    OR
    -- Platform Admin viewing all projects
    (public.is_admin())
    OR
    -- Student assigned to this project
    (assigned_student = auth.uid()::text)
  );

-- Policy B: Companies can insert their own projects (default status: 'pending_payment')
CREATE POLICY "Projects Company Insert Draft"
  ON public.projects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be their own user account
    (posted_by = auth.uid() OR user_id = auth.uid())
    -- Companies cannot self-verify escrow upon insertion
    AND (is_escrow_verified = false OR public.is_admin())
  );

-- Policy C: Companies can update their own projects (e.g. submit TID, payment receipt, or edit drafts)
-- But CANNOT self-approve escrow or set status to 'open' without Admin verification
CREATE POLICY "Projects Company Update Own"
  ON public.projects
  FOR UPDATE
  TO authenticated
  USING (
    (posted_by = auth.uid() OR user_id = auth.uid()) OR public.is_admin()
  )
  WITH CHECK (
    public.is_admin()
    OR (
      -- Company cannot change is_escrow_verified to true
      (is_escrow_verified = false)
      -- Company cannot directly set status to 'open' or 'completed'
      AND (LOWER(status) IN ('draft', 'pending_payment', 'pending_verification', 'in_progress', 'delivered'))
    )
  );

-- Policy D: Admins have full CRUD access across all projects
CREATE POLICY "Projects Admin Full Manage"
  ON public.projects
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 5. NOTIFY POSTGREST SCHEMA CACHE RELOAD
NOTIFY pgrst, 'reload schema';

