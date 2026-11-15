-- ============================================================================
-- SKILLBRIDGE - UPFRONT ESCROW PAYMENT VERIFICATION WORKFLOW
-- Migration File: supabase/migrations/setup_payment_verification_workflow.sql
-- ============================================================================

-- 1. ADD COLUMNS TO PROJECTS TABLE (Idempotent)
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS escrow_amount NUMERIC(12, 2) DEFAULT 0.00;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS is_escrow_verified BOOLEAN DEFAULT false;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS payment_sent BOOLEAN DEFAULT false;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS payment_method_used TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS transaction_id TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS payment_receipt_url TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 2. CREATE INDEXES FOR FAST ADMIN LOOKUP
CREATE INDEX IF NOT EXISTS idx_projects_status_escrow 
  ON public.projects (status, is_escrow_verified);

CREATE INDEX IF NOT EXISTS idx_projects_transaction_id 
  ON public.projects (transaction_id);

-- 3. ADMIN APPROVE PAYMENT RPC FUNCTION
-- Sets status = 'Open' (Live for students), is_escrow_verified = true, payment_sent = true
CREATE OR REPLACE FUNCTION public.admin_approve_project_payment(
  p_project_id UUID,
  p_admin_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT;
  v_company_id UUID;
  v_escrow NUMERIC;
BEGIN
  -- Verify project exists
  SELECT title, company_id, COALESCE(escrow_amount, 0)
  INTO v_title, v_company_id, v_escrow
  FROM public.projects
  WHERE id = p_project_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Project not found.');
  END IF;

  -- Update project status to Open / Paid
  UPDATE public.projects
  SET 
    status = 'Open',
    is_escrow_verified = true,
    payment_sent = true,
    verified_at = timezone('utc'::text, now()),
    updated_at = timezone('utc'::text, now()),
    additional_instructions = CASE 
      WHEN p_admin_notes IS NOT NULL AND trim(p_admin_notes) <> '' 
      THEN 'Admin Escrow Note: ' || trim(p_admin_notes) 
      ELSE additional_instructions 
    END
  WHERE id = p_project_id;

  -- Record audit log if audit_logs table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
    INSERT INTO public.audit_logs (action, target, details, admin_email, created_at)
    VALUES (
      'Approve Escrow Payment',
      p_project_id::text,
      'Approved upfront deposit of PKR ' || v_escrow || ' for "' || v_title || '"',
      COALESCE(auth.jwt() ->> 'email', 'admin@skillbridge.edu.pk'),
      timezone('utc'::text, now())
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'message', 'Payment approved and project published.');
END;
$$;

-- 4. ADMIN REJECT PAYMENT RPC FUNCTION
-- Sets status = 'payment_rejected', is_escrow_verified = false, payment_sent = false
-- Triggers red alert for Company to re-submit payment proof
CREATE OR REPLACE FUNCTION public.admin_reject_project_payment(
  p_project_id UUID,
  p_rejection_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT;
BEGIN
  -- Verify project exists
  SELECT title INTO v_title
  FROM public.projects
  WHERE id = p_project_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Project not found.');
  END IF;

  -- Update project status to payment_rejected
  UPDATE public.projects
  SET 
    status = 'payment_rejected',
    is_escrow_verified = false,
    payment_sent = false,
    rejection_reason = trim(p_rejection_reason),
    additional_instructions = 'Payment Rejected: ' || trim(p_rejection_reason),
    updated_at = timezone('utc'::text, now())
  WHERE id = p_project_id;

  -- Record audit log if audit_logs table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
    INSERT INTO public.audit_logs (action, target, details, admin_email, created_at)
    VALUES (
      'Reject Escrow Payment Proof',
      p_project_id::text,
      'Rejected payment proof for "' || v_title || '". Reason: ' || trim(p_rejection_reason),
      COALESCE(auth.jwt() ->> 'email', 'admin@skillbridge.edu.pk'),
      timezone('utc'::text, now())
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'message', 'Payment rejected. Company notified to re-submit.');
END;
$$;

-- 5. RLS POLICIES FOR RE-SUBMISSION
-- Allows Company to update transaction_id and payment_receipt_url when status is payment_rejected or pending_payment
DROP POLICY IF EXISTS "Company Can Re-Submit Payment Proof" ON public.projects;
CREATE POLICY "Company Can Re-Submit Payment Proof"
  ON public.projects
  FOR UPDATE
  TO authenticated
  USING (
    (posted_by = auth.uid() OR user_id = auth.uid())
    AND status IN ('pending_payment', 'pending_verification', 'payment_rejected')
  )
  WITH CHECK (
    (posted_by = auth.uid() OR user_id = auth.uid())
    AND status IN ('pending_payment', 'pending_verification', 'payment_rejected')
  );

NOTIFY pgrst, 'reload schema';
