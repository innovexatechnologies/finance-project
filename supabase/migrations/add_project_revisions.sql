-- ============================================================================
-- SKILLBRIDGE - PROJECT REVISION REQUEST (MAX 2 REVISIONS LIMIT) MIGRATION
-- Migration File: supabase/migrations/add_project_revisions.sql
-- ============================================================================

-- 1. ADD REVISION TRACKING COLUMNS TO PROJECTS TABLE
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS revision_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_revisions INTEGER NOT NULL DEFAULT 2,
  ADD COLUMN IF NOT EXISTS revision_notes TEXT,
  ADD COLUMN IF NOT EXISTS last_revision_requested_at TIMESTAMPTZ;

-- 2. ENFORCE MAXIMUM 2 REVISIONS CONSTRAINT
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_projects_revision_count'
  ) THEN
    ALTER TABLE public.projects
      ADD CONSTRAINT chk_projects_revision_count
      CHECK (revision_count >= 0 AND revision_count <= 2);
  END IF;
END $$;

-- 3. ENSURE STATUS CHECK ACCEPTS 'revision_requested'
-- If any existing constraint restricts status, update it safely:
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_projects_status'
  ) THEN
    ALTER TABLE public.projects DROP CONSTRAINT chk_projects_status;
  END IF;
  
  -- Add updated status domain check if desired
  -- 'pending_payment', 'pending_verification', 'Open', 'In Progress', 
  -- 'delivered', 'revision_requested', 'ready_for_payout', 'completed', 'disputed', 'Closed', 'Cancelled'
END $$;

-- Performance index for revision requested queries
CREATE INDEX IF NOT EXISTS idx_projects_revision_requested
  ON public.projects (status)
  WHERE status = 'revision_requested';

-- 4. CONFIRM 5-DAY AUTO-RELEASE ONLY RUNS ON 'delivered' STATUS
-- Note: When status is 'revision_requested', the project is skipped by this function,
-- pausing the 5-day auto-release timer. When student re-delivers, delivered_at is
-- reset to now() and status becomes 'delivered', restarting the 5-day countdown.
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
  -- Strictly targets projects in 'delivered' state older than 5 days.
  -- Projects in 'revision_requested' or 'disputed' are paused and untouched.
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
      '5 days passed without company action. System auto-released payout. Send PKR ' || v_student_payout || ' payout to Student (10% fee: PKR ' || v_commission || ').',
      'auto_release_5_days',
      false
    );

    v_processed_count := v_processed_count + 1;
  END LOOP;

  RETURN v_processed_count;
END;
$$;

