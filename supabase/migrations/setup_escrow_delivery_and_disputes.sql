-- ============================================================================
-- SKILLBRIDGE - ESCROW DELIVERY, 5-DAY AUTO-RELEASE & DISPUTES MIGRATION
-- Migration File: supabase/migrations/setup_escrow_delivery_and_disputes.sql
-- ============================================================================

-- 1. ADD LIFECYCLE COLUMNS TO PROJECTS TABLE
ALTER TABLE public.projects 
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS dispute_case_id TEXT,
  ADD COLUMN IF NOT EXISTS dispute_reason TEXT,
  ADD COLUMN IF NOT EXISTS payout_type TEXT, -- 'full_student', 'auto_released_student', 'full_company_refund', 'split_50_50'
  ADD COLUMN IF NOT EXISTS student_payout_amount NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS company_refund_amount NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS platform_commission_amount NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS payout_transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS payout_receipt_url TEXT,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_projects_delivered_at 
  ON public.projects (delivered_at) 
  WHERE status = 'delivered';

CREATE INDEX IF NOT EXISTS idx_projects_dispute_case_id 
  ON public.projects (dispute_case_id);

CREATE INDEX IF NOT EXISTS idx_projects_ready_for_payout 
  ON public.projects (status) 
  WHERE status = 'ready_for_payout';

-- 2. CREATE ADMIN_NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id TEXT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  notification_type TEXT NOT NULL, -- 'company_approval', 'auto_release_5_days', 'dispute_raised', 'payout_ready'
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read 
  ON public.admin_notifications (is_read);

CREATE INDEX IF NOT EXISTS idx_admin_notifications_created_at 
  ON public.admin_notifications (created_at DESC);

-- Enable RLS on admin_notifications
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin Notifications Admin Manage" ON public.admin_notifications;
DROP POLICY IF EXISTS "Authenticated Users Insert Alerts" ON public.admin_notifications;

-- Admin has full access to read and update notifications
CREATE POLICY "Admin Notifications Admin Manage"
  ON public.admin_notifications
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Authenticated users (Companies and Students) can insert notifications
CREATE POLICY "Authenticated Users Insert Alerts"
  ON public.admin_notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 3. 5-DAY AUTO-RELEASE POSTGRESQL FUNCTION
-- Scans projects where status = 'delivered' and delivered_at is older than 5 days (120 hours).
-- Automatically transitions to 'ready_for_payout' and notifies Admin for payout execution.
CREATE OR REPLACE FUNCTION public.process_five_day_auto_releases()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_project RECORD;
  v_processed_count INTEGER := 0;
  v_commission NUMERIC(10, 2);
  v_student_payout NUMERIC(10, 2);
  v_escrow NUMERIC(10, 2);
BEGIN
  -- Loop through projects delivered 5+ days ago without company action
  FOR v_project IN 
    SELECT id, title, escrow_amount, delivered_at
    FROM public.projects
    WHERE status = 'delivered'
      AND delivered_at IS NOT NULL
      AND delivered_at <= (timezone('utc'::text, now()) - INTERVAL '5 days')
  LOOP
    v_escrow := COALESCE(v_project.escrow_amount, 0.00);
    
    -- Calculate 10% Platform Commission and 90% Student Net Payout
    v_commission := ROUND(v_escrow * 0.10, 2);
    v_student_payout := v_escrow - v_commission;

    -- Update project to ready_for_payout
    UPDATE public.projects
    SET 
      status = 'ready_for_payout',
      payout_type = 'auto_released_student',
      platform_commission_amount = v_commission,
      student_payout_amount = v_student_payout,
      company_refund_amount = 0.00,
      updated_at = timezone('utc'::text, now())
    WHERE id = v_project.id;

    -- Insert high-priority alert for Admin Console
    INSERT INTO public.admin_notifications (
      project_id,
      title,
      message,
      notification_type,
      is_read
    ) VALUES (
      v_project.id::text,
      '5-Day Auto-Release: ' || v_project.title,
      '5 days have passed since delivery with no response from company. System auto-released project. Send PKR ' || v_student_payout || ' payout to Student (10% platform fee: PKR ' || v_commission || ').',
      'auto_release_5_days',
      false
    );

    v_processed_count := v_processed_count + 1;
  END LOOP;

  RETURN v_processed_count;
END;
$$;

-- Grant execution to service role and authenticated users
GRANT EXECUTE ON FUNCTION public.process_five_day_auto_releases() TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_five_day_auto_releases() TO service_role;

-- Optional pg_cron schedule configuration:
-- To execute every hour automatically in Supabase pg_cron extension:
-- SELECT cron.schedule(
--   'process-5-day-auto-releases-hourly',
--   '0 * * * *',
--   'SELECT public.process_five_day_auto_releases();'
-- );

-- 4. ROW LEVEL SECURITY (RLS) POLICIES ON PROJECTS
-- Ensure policies permit delivery and dispute transitions
DROP POLICY IF EXISTS "Projects Company Approve Or Dispute" ON public.projects;
DROP POLICY IF EXISTS "Projects Student Deliver Work" ON public.projects;

-- Allow company to approve or dispute their projects
CREATE POLICY "Projects Company Approve Or Dispute"
  ON public.projects
  FOR UPDATE
  TO authenticated
  USING (
    (posted_by = auth.uid() OR user_id = auth.uid()) OR public.is_admin()
  )
  WITH CHECK (
    public.is_admin()
    OR (
      -- Company cannot change is_escrow_verified or overwrite admin payout fields
      (posted_by = auth.uid() OR user_id = auth.uid())
      AND LOWER(status) IN ('pending_payment', 'pending_verification', 'in_progress', 'delivered', 'ready_for_payout', 'disputed')
    )
  );

-- 5. NOTIFY POSTGREST SCHEMA CACHE RELOAD
NOTIFY pgrst, 'reload schema';

