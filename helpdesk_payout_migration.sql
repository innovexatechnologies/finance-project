-- ============================================================================
-- SKILLBRIDGE HELPDESK ESCROW PAYOUT MIGRATION
-- Layer 1: Database Schema & Migration for 2-Day + 1-Day HelpDesk Payout System
-- ============================================================================

-- Step 1: Ensure columns exist on projects table
ALTER TABLE public.projects 
  ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS has_help_request BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'escrow_held';

-- Ensure constraint on payment_status if not already constrained
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_projects_payment_status'
  ) THEN
    ALTER TABLE public.projects 
      ADD CONSTRAINT check_projects_payment_status 
      CHECK (payment_status IN ('escrow_held', 'paid', 'refunded', 'disputed'));
  END IF;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- Step 2: Ensure student bank detail columns are accessible on student_payment_methods and profiles
ALTER TABLE public.student_payment_methods
  ADD COLUMN IF NOT EXISTS account_title TEXT,
  ADD COLUMN IF NOT EXISTS bank_name TEXT;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS bank_name TEXT,
  ADD COLUMN IF NOT EXISTS account_title TEXT,
  ADD COLUMN IF NOT EXISTS account_number_iban TEXT;

-- Step 3: Create helpdesk_tickets table
CREATE TABLE IF NOT EXISTS public.helpdesk_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_project_id ON public.helpdesk_tickets(project_id);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_student_id ON public.helpdesk_tickets(student_id);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_company_id ON public.helpdesk_tickets(company_id);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_status ON public.helpdesk_tickets(status);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_created_at ON public.helpdesk_tickets(created_at);

-- Step 4: Row Level Security (RLS) Policies
ALTER TABLE public.helpdesk_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Helpdesk Tickets Authenticated Access" ON public.helpdesk_tickets;
CREATE POLICY "Helpdesk Tickets Authenticated Access"
  ON public.helpdesk_tickets
  FOR ALL
  TO authenticated
  USING (
    student_id = auth.uid() 
    OR company_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
        AND (profiles.user_type ILIKE 'admin' OR profiles.user_type ILIKE 'super_admin')
    )
  )
  WITH CHECK (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
        AND (profiles.user_type ILIKE 'admin' OR profiles.user_type ILIKE 'super_admin')
    )
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.helpdesk_tickets TO authenticated;

-- Optional Commenting
COMMENT ON TABLE public.helpdesk_tickets IS 'Stores escalated student helpdesk tickets when company does not respond within 48h after submission.';
COMMENT ON COLUMN public.helpdesk_tickets.created_at IS 'Timestamp used to enforce the 24-hour final response deadline for the company before Admin payout.';

