-- ============================================================================
-- Payment Method and project payment workflow SQL extracted from
-- supabase_schema.sql. This file contains copied statements only; it is not a
-- standalone schema because it depends on existing Supabase/application tables.
-- ============================================================================

-- Dependencies not defined in this extraction:
-- auth.users and auth.uid()
-- public.profiles (id, user_type)
-- public.companies (id, user_id)
-- public.projects (id, company_id, posted_by, user_id, status, openings,
--   assigned_student, progress, payment_sent, updated_at)
-- public.applications (id, project_id, company_id, student_id, user_id,
--   student_name, university, status, updated_at)

-- ----------------------------------------------------------------------------
-- 1. Student payment methods
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_payment_methods (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('Bank Account', 'JazzCash', 'Easypaisa')),
  account_number TEXT NOT NULL
    CHECK (length(btrim(account_number)) BETWEEN 1 AND 50),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

REVOKE ALL ON TABLE public.student_payment_methods FROM anon, PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.student_payment_methods TO authenticated;

ALTER TABLE public.student_payment_methods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Student Payment Methods Owner Access" ON public.student_payment_methods;

CREATE POLICY "Student Payment Methods Owner Access"
ON public.student_payment_methods FOR ALL TO authenticated
USING (auth.uid() = user_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- ----------------------------------------------------------------------------
-- 2. Project payment fields and assignment/confirmation records
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS user_type TEXT DEFAULT 'Student';

ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS posted_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Open';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS openings INTEGER DEFAULT 1;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS assigned_student TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS progress DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS payment_sent BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS project_id UUID;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_name TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Pending';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

UPDATE public.applications SET student_id = user_id WHERE student_id IS NULL AND user_id IS NOT NULL;
UPDATE public.applications SET user_id = student_id WHERE user_id IS NULL AND student_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.project_assignments (
  application_id UUID PRIMARY KEY
    REFERENCES public.applications(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_project_assignments_project_id
  ON public.project_assignments (project_id);

CREATE TABLE IF NOT EXISTS public.project_payment_confirmations (
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  confirmation_status TEXT NOT NULL
    CHECK (confirmation_status IN ('Received', 'Not Received')),
  confirmed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (project_id, student_id)
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.project_assignments
    GROUP BY project_id
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION
      'Multiple assignments exist for a project. Reconcile them before applying the single-assignment constraint.';
  END IF;

END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_project_assignments_one_per_project
  ON public.project_assignments (project_id);

UPDATE public.projects
SET openings = 1
WHERE openings IS DISTINCT FROM 1;

ALTER TABLE public.projects
  ALTER COLUMN openings SET DEFAULT 1,
  ALTER COLUMN openings SET NOT NULL;
ALTER TABLE public.projects
  DROP CONSTRAINT IF EXISTS projects_single_assignment_opening_check;
ALTER TABLE public.projects
  ADD CONSTRAINT projects_single_assignment_opening_check CHECK (openings = 1);

DELETE FROM public.project_payment_confirmations pc
WHERE NOT EXISTS (
  SELECT 1
  FROM public.project_assignments pa
  WHERE pa.project_id = pc.project_id
    AND pa.student_id = pc.student_id
);

ALTER TABLE public.project_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_payment_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.project_assignments FROM anon, PUBLIC, authenticated;
REVOKE ALL ON TABLE public.project_payment_confirmations
  FROM anon, PUBLIC, authenticated;

-- ----------------------------------------------------------------------------
-- 3. Shared authorization helper used by payment policies/triggers
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND lower(COALESCE(user_type, '')) = 'admin'
  );
$$;

-- ----------------------------------------------------------------------------
-- 4. Authoritative single-student project assignment
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_applicant_to_project(
  p_application_id UUID,
  p_confirm_existing BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_project_id UUID;
  v_project_company_id UUID;
  v_project_owner UUID;
  v_project_user_id UUID;
  v_student_id UUID;
  v_user_id UUID;
  v_student_name TEXT;
  v_university TEXT;
  v_application_status TEXT;
  v_payment_sent BOOLEAN;
  v_assigned_label TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required to assign an applicant.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles pr
    WHERE pr.id = auth.uid()
      AND lower(BTRIM(pr.user_type)) = 'company'
  ) THEN
    RAISE EXCEPTION 'Only company accounts can assign applicants.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.applications a
    JOIN public.projects p ON p.id = a.project_id
    LEFT JOIN public.companies c ON c.id = p.company_id
    WHERE a.id = p_application_id
      AND (
        p.posted_by = auth.uid()
        OR p.user_id = auth.uid()
        OR c.user_id = auth.uid()
      )
  ) THEN
    RAISE EXCEPTION 'Application not found or you are not authorized to assign it.';
  END IF;

  SELECT
    p.id,
    p.company_id,
    p.posted_by,
    p.user_id,
    p.payment_sent,
    a.student_id,
    a.user_id,
    a.student_name,
    a.university,
    a.status
  INTO
    v_project_id,
    v_project_company_id,
    v_project_owner,
    v_project_user_id,
    v_payment_sent,
    v_student_id,
    v_user_id,
    v_student_name,
    v_university,
    v_application_status
  FROM public.applications a
  JOIN public.projects p ON p.id = a.project_id
  WHERE a.id = p_application_id
  FOR UPDATE OF p, a;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Application not found or you are not authorized to assign it.';
  END IF;

  IF NOT EXISTS (
      SELECT 1 FROM public.profiles pr
      WHERE pr.id = auth.uid()
        AND lower(BTRIM(pr.user_type)) = 'company'
    )
    OR v_project_owner IS DISTINCT FROM auth.uid()
    AND v_project_user_id IS DISTINCT FROM auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.companies c
      WHERE c.id = v_project_company_id AND c.user_id = auth.uid()
    )
  THEN
    RAISE EXCEPTION 'Application not found or you are not authorized to assign it.';
  END IF;

  v_assigned_label := COALESCE(NULLIF(BTRIM(v_student_name), ''), 'Student');
  IF NULLIF(BTRIM(v_university), '') IS NOT NULL THEN
    v_assigned_label := v_assigned_label || ' (' || BTRIM(v_university) || ')';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.project_assignments pa
    WHERE pa.project_id = v_project_id
      AND pa.application_id <> p_application_id
  ) THEN
    RAISE EXCEPTION 'This project already has an assigned student.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.project_assignments pa
    WHERE pa.application_id = p_application_id
  ) THEN
    UPDATE public.applications
    SET status = 'Rejected',
        updated_at = timezone('utc'::text, now())
    WHERE project_id = v_project_id
      AND id <> p_application_id
      AND status IS DISTINCT FROM 'Rejected';
    UPDATE public.projects
    SET assigned_student = v_assigned_label,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_project_id;
    RETURN;
  END IF;

  IF v_payment_sent IS TRUE THEN
    RAISE EXCEPTION 'A student cannot be assigned after payment is marked sent.';
  END IF;

  IF v_student_id IS NOT NULL
    AND v_user_id IS NOT NULL
    AND v_student_id <> v_user_id
  THEN
    RAISE EXCEPTION 'The application has inconsistent student account IDs.';
  END IF;

  v_student_id := COALESCE(v_student_id, v_user_id);
  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'The application does not have a valid student account.';
  END IF;

  IF p_confirm_existing THEN
    IF v_application_status NOT IN (
      'Accepted',
      'In Progress',
      'Revision Requested',
      'Under Review',
      'Completed'
    ) THEN
      RAISE EXCEPTION 'This application is not marked as an existing assignment.';
    END IF;
  ELSIF v_application_status IS NULL OR v_application_status NOT IN (
      'Pending',
      'Under Review',
      'Shortlisted'
    )
  THEN
    RAISE EXCEPTION 'This application cannot be assigned in its current status.';
  END IF;

  INSERT INTO public.project_assignments (
    application_id,
    project_id,
    student_id
  )
  VALUES (p_application_id, v_project_id, v_student_id);

  IF p_confirm_existing IS NOT TRUE THEN
    UPDATE public.applications
    SET status = 'Accepted',
        progress = 0.15,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_application_id;

    UPDATE public.projects
    SET status = 'In Progress',
        progress = 0.15,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_project_id;
  END IF;

  UPDATE public.projects
  SET assigned_student = v_assigned_label,
      updated_at = timezone('utc'::text, now())
  WHERE id = v_project_id;

  UPDATE public.applications
  SET status = 'Rejected',
      updated_at = timezone('utc'::text, now())
  WHERE project_id = v_project_id
    AND id <> p_application_id
    AND status IS DISTINCT FROM 'Rejected';
END;
$$;

REVOKE ALL ON FUNCTION public.assign_applicant_to_project(UUID, BOOLEAN)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assign_applicant_to_project(UUID, BOOLEAN)
  TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. Payment method access and payment status RPCs
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_assigned_student_payment_details(
  p_application_id UUID
)
RETURNS TABLE(provider TEXT, account_number TEXT)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT pm.provider, pm.account_number
  FROM public.project_assignments pa
  JOIN public.projects p ON p.id = pa.project_id
  LEFT JOIN public.companies pc ON pc.id = p.company_id
  LEFT JOIN public.student_payment_methods pm ON pm.user_id = pa.student_id
  WHERE pa.application_id = p_application_id
    AND EXISTS (
      SELECT 1 FROM public.profiles pr
      WHERE pr.id = auth.uid()
        AND lower(BTRIM(pr.user_type)) = 'company'
    )
    AND (
      p.posted_by = auth.uid()
      OR p.user_id = auth.uid()
      OR pc.user_id = auth.uid()
    )
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_assigned_student_payment_details(UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_assigned_student_payment_details(UUID)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.mark_project_payment_sent(
  p_project_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.profiles pr
    WHERE pr.id = auth.uid()
      AND lower(BTRIM(pr.user_type)) = 'company'
  ) THEN
    RAISE EXCEPTION 'Only company accounts can mark project payments sent.';
  END IF;

  PERFORM set_config('app.allow_project_payment_sent_update', 'on', true);

  UPDATE public.projects p
  SET payment_sent = TRUE,
      updated_at = timezone('utc'::text, now())
  WHERE p.id = p_project_id
    AND (
      p.posted_by = auth.uid()
      OR p.user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.companies c
        WHERE c.id = p.company_id
          AND c.user_id = auth.uid()
      )
    )
    AND EXISTS (
      SELECT 1 FROM public.project_assignments pa
      WHERE pa.project_id = p.id
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Project not found, unauthorized, or no student is assigned.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_project_payment_sent(UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_project_payment_sent(UUID)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.get_student_assigned_project_payment_status()
RETURNS TABLE(
  project_id UUID,
  payment_sent BOOLEAN,
  confirmation_status TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT DISTINCT
    p.id,
    p.payment_sent,
    pc.confirmation_status
  FROM public.project_assignments pa
  JOIN public.projects p ON p.id = pa.project_id
  LEFT JOIN public.project_payment_confirmations pc
    ON pc.project_id = p.id
   AND pc.student_id = auth.uid()
  WHERE pa.student_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.profiles pr
      WHERE pr.id = auth.uid()
        AND lower(BTRIM(pr.user_type)) = 'student'
    );
$$;

REVOKE ALL ON FUNCTION public.get_student_assigned_project_payment_status()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_assigned_project_payment_status()
  TO authenticated;

CREATE OR REPLACE FUNCTION public.respond_to_project_payment(
  p_project_id UUID,
  p_received BOOLEAN
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_payment_sent BOOLEAN;
  v_confirmation_status TEXT;
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.profiles pr
    WHERE pr.id = auth.uid()
      AND lower(BTRIM(pr.user_type)) = 'student'
  ) THEN
    RAISE EXCEPTION 'Only student accounts can confirm project payments.';
  END IF;

  SELECT p.payment_sent
  INTO v_payment_sent
  FROM public.projects p
  WHERE p.id = p_project_id
    AND EXISTS (
      SELECT 1 FROM public.project_assignments pa
      WHERE pa.project_id = p.id
        AND pa.student_id = auth.uid()
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Project not found or you are not assigned to it.';
  END IF;

  IF v_payment_sent IS NOT TRUE THEN
    RAISE EXCEPTION 'The company has not marked this payment as sent.';
  END IF;

  IF p_received IS NULL THEN
    RAISE EXCEPTION 'A payment received response is required.';
  END IF;

  SELECT pc.confirmation_status
  INTO v_confirmation_status
  FROM public.project_payment_confirmations pc
  WHERE pc.project_id = p_project_id
    AND pc.student_id = auth.uid();

  IF FOUND THEN
    RETURN v_confirmation_status;
  END IF;

  v_confirmation_status := CASE
    WHEN p_received THEN 'Received'
    ELSE 'Not Received'
  END;

  INSERT INTO public.project_payment_confirmations (
    project_id,
    student_id,
    confirmation_status
  )
  VALUES (p_project_id, auth.uid(), v_confirmation_status)
  ON CONFLICT (project_id, student_id) DO NOTHING;

  IF NOT FOUND THEN
    SELECT pc.confirmation_status
    INTO v_confirmation_status
    FROM public.project_payment_confirmations pc
    WHERE pc.project_id = p_project_id
      AND pc.student_id = auth.uid();
  END IF;

  RETURN v_confirmation_status;
END;
$$;

REVOKE ALL ON FUNCTION public.respond_to_project_payment(UUID, BOOLEAN)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.respond_to_project_payment(UUID, BOOLEAN)
  TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. Payment-related RLS policies
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Companies Public View" ON public.companies;
DROP POLICY IF EXISTS "Projects Public View" ON public.projects;
DROP POLICY IF EXISTS "Projects Company Manage" ON public.projects;
DROP POLICY IF EXISTS "Applications Student Manage" ON public.applications;
DROP POLICY IF EXISTS "Applications Company View" ON public.applications;
DROP POLICY IF EXISTS "Applications Company Manage" ON public.applications;

CREATE POLICY "Projects Public View" ON public.projects FOR SELECT USING (true);
CREATE POLICY "Companies Public View" ON public.companies FOR SELECT USING (true);
CREATE POLICY "Projects Company Manage" ON public.projects FOR ALL TO authenticated
  USING (
    auth.uid() = posted_by
    OR auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.companies c
      WHERE c.id = public.projects.company_id
        AND c.user_id = auth.uid()
    )
    OR public.is_admin()
  )
  WITH CHECK (
    auth.uid() = posted_by
    OR auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.companies c
      WHERE c.id = public.projects.company_id
        AND c.user_id = auth.uid()
    )
    OR public.is_admin()
  );

CREATE POLICY "Applications Student Manage" ON public.applications FOR ALL TO authenticated
  USING (auth.uid() = student_id OR auth.uid() = user_id)
  WITH CHECK (auth.uid() = student_id OR auth.uid() = user_id);

CREATE POLICY "Applications Company View" ON public.applications FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projects p
      LEFT JOIN public.companies c ON c.id = p.company_id
      WHERE p.id = public.applications.project_id
        AND (
          p.posted_by = auth.uid()
          OR p.user_id = auth.uid()
          OR c.user_id = auth.uid()
        )
    )
    OR EXISTS (
      SELECT 1 FROM public.companies c
      WHERE c.id = public.applications.company_id
        AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "Applications Company Manage" ON public.applications FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.projects p
      LEFT JOIN public.companies c ON c.id = p.company_id
      WHERE p.id = public.applications.project_id
        AND (
          p.posted_by = auth.uid()
          OR p.user_id = auth.uid()
          OR c.user_id = auth.uid()
        )
    )
    OR EXISTS (
      SELECT 1 FROM public.companies c
      WHERE c.id = public.applications.company_id
        AND c.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.projects p
      LEFT JOIN public.companies c ON c.id = p.company_id
      WHERE p.id = public.applications.project_id
        AND (
          p.posted_by = auth.uid()
          OR p.user_id = auth.uid()
          OR c.user_id = auth.uid()
        )
    )
    OR EXISTS (
      SELECT 1 FROM public.companies c
      WHERE c.id = public.applications.company_id
        AND c.user_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- 7. Assignment, bidding, and payment-sent enforcement triggers
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_application_identity_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF (
      NEW.student_id IS NOT NULL
      AND NEW.student_id IS DISTINCT FROM auth.uid()
    ) OR (
      NEW.user_id IS NOT NULL
      AND NEW.user_id IS DISTINCT FROM auth.uid()
    ) THEN
      RAISE EXCEPTION 'An application must belong to the authenticated student.';
    END IF;
    RETURN NEW;
  END IF;

  IF auth.uid() = OLD.student_id OR auth.uid() = OLD.user_id THEN
    IF (
      NEW.student_id IS NOT NULL
      AND NEW.student_id IS DISTINCT FROM auth.uid()
    ) OR (
      NEW.user_id IS NOT NULL
      AND NEW.user_id IS DISTINCT FROM auth.uid()
    ) THEN
      RAISE EXCEPTION 'An application cannot be transferred to another student.';
    END IF;
  ELSIF NEW.student_id IS DISTINCT FROM OLD.student_id
    OR NEW.user_id IS DISTINCT FROM OLD.user_id
  THEN
    RAISE EXCEPTION 'Companies cannot change the student attached to an application.';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_application_bid_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_project_status TEXT;
  v_student_id UUID;
  v_bid_count INTEGER;
BEGIN
  IF TG_OP <> 'INSERT' THEN
    IF NEW.project_id IS DISTINCT FROM OLD.project_id
      OR COALESCE(NEW.student_id, NEW.user_id)
        IS DISTINCT FROM COALESCE(OLD.student_id, OLD.user_id)
    THEN
      RAISE EXCEPTION 'An application cannot be moved to another project or student.';
    END IF;
    RETURN NEW;
  END IF;

  v_student_id := COALESCE(NEW.student_id, NEW.user_id);
  IF NEW.project_id IS NULL OR v_student_id IS NULL THEN
    RAISE EXCEPTION 'A valid project and student are required to apply.';
  END IF;

  IF auth.uid() IS NOT NULL
    AND NOT public.is_admin()
    AND NOT EXISTS (
      SELECT 1
      FROM public.profiles pr
      WHERE pr.id = auth.uid()
        AND lower(BTRIM(pr.user_type)) = 'student'
    )
  THEN
    RAISE EXCEPTION 'Only student accounts can apply to projects.';
  END IF;

  SELECT p.status
  INTO v_project_status
  FROM public.projects p
  WHERE p.id = NEW.project_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Project not found.';
  END IF;

  IF lower(BTRIM(COALESCE(v_project_status, ''))) NOT IN ('open', 'active') THEN
    RAISE EXCEPTION 'This project is not accepting applications.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.project_assignments pa
    WHERE pa.project_id = NEW.project_id
  ) THEN
    RAISE EXCEPTION 'This project already has an assigned student.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.applications a
    WHERE a.project_id = NEW.project_id
      AND COALESCE(a.student_id, a.user_id) = v_student_id
  ) THEN
    RAISE EXCEPTION 'You have already applied to this project.';
  END IF;

  SELECT count(*)::INTEGER
  INTO v_bid_count
  FROM public.applications a
  WHERE a.project_id = NEW.project_id;

  IF v_bid_count >= 10 THEN
    RAISE EXCEPTION 'This project has reached the maximum of 10 applications.';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_application_assignment_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.status IN ('Accepted', 'In Progress', 'Revision Requested', 'Completed') THEN
      RAISE EXCEPTION 'This status requires an authoritative project assignment.';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.status IN ('Accepted', 'In Progress', 'Revision Requested', 'Completed')
    AND NOT EXISTS (
      SELECT 1
      FROM public.project_assignments pa
      WHERE pa.application_id = NEW.id
        AND pa.project_id = NEW.project_id
        AND pa.student_id = COALESCE(NEW.student_id, NEW.user_id)
    )
  THEN
    RAISE EXCEPTION 'This status requires an authoritative project assignment.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.project_assignments pa
    WHERE pa.application_id = NEW.id
      AND pa.project_id = NEW.project_id
  ) AND NEW.status IN ('Pending', 'Shortlisted', 'Rejected')
  THEN
    RAISE EXCEPTION 'An assigned application cannot be marked as unassigned.';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.guard_project_payment_sent_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  IF NEW.payment_sent IS DISTINCT FROM OLD.payment_sent
    AND current_setting('app.allow_project_payment_sent_update', true)
      IS DISTINCT FROM 'on'
  THEN
    RAISE EXCEPTION 'Payment status must be changed through the authorized payment RPC.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_application_identity_insert ON public.applications;
DROP TRIGGER IF EXISTS prevent_application_identity_changes ON public.applications;
DROP TRIGGER IF EXISTS enforce_application_bid_rules ON public.applications;
DROP TRIGGER IF EXISTS enforce_application_assignment_status ON public.applications;
DROP TRIGGER IF EXISTS guard_project_payment_sent_update ON public.projects;

CREATE TRIGGER prevent_application_identity_insert
BEFORE INSERT ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.prevent_application_identity_changes();

CREATE TRIGGER prevent_application_identity_changes
BEFORE UPDATE OF student_id, user_id ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.prevent_application_identity_changes();

CREATE TRIGGER enforce_application_bid_rules
BEFORE INSERT OR UPDATE OF project_id, student_id, user_id ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.enforce_application_bid_rules();

CREATE TRIGGER enforce_application_assignment_status
BEFORE INSERT OR UPDATE OF status ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.enforce_application_assignment_status();

CREATE TRIGGER guard_project_payment_sent_update
BEFORE UPDATE OF payment_sent ON public.projects
FOR EACH ROW
EXECUTE FUNCTION public.guard_project_payment_sent_update();

-- ----------------------------------------------------------------------------
-- 8. Supporting indexes used by assignment/payment lookups
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_projects_posted_by ON public.projects (posted_by);
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON public.projects (user_id);
CREATE INDEX IF NOT EXISTS idx_projects_company_id ON public.projects (company_id);
CREATE INDEX IF NOT EXISTS idx_applications_project_id ON public.applications (project_id);
CREATE INDEX IF NOT EXISTS idx_applications_student_id ON public.applications (student_id);
