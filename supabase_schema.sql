-- ============================================================================
-- CAMPUSCONNECT / LINKVIBE — PRODUCTION SUPABASE DATABASE & STORAGE SCHEMA
-- ============================================================================
-- Idempotent & backward-compatible migration script for Student, Company, and
-- Admin panels. Safely evolves existing tables, fixes cross-panel RLS
-- permissions, sets up public storage buckets, and configures default Admin.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. EXTENSIONS
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 2. USER PROFILES TABLE (Linked with Supabase Auth)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  user_type TEXT DEFAULT 'Student',
  university TEXT,
  department TEXT DEFAULT 'Computer Science',
  degree TEXT DEFAULT 'BS',
  semester TEXT DEFAULT '1st Semester',
  cgpa DOUBLE PRECISION DEFAULT 0.0,
  phone TEXT,
  bio TEXT,
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  account_status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS user_type TEXT DEFAULT 'Student';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS department TEXT DEFAULT 'Computer Science';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS degree TEXT DEFAULT 'BS';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS semester TEXT DEFAULT '1st Semester';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS cgpa DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'active';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

UPDATE public.profiles
SET user_type = 'Student'
WHERE user_type IS NULL OR trim(user_type) = '';

-- ----------------------------------------------------------------------------
-- 3. COMPANIES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name TEXT,
  email TEXT,
  industry TEXT DEFAULT 'Software & Cloud Services',
  location TEXT DEFAULT '',
  city TEXT DEFAULT '',
  address TEXT DEFAULT '',
  website TEXT DEFAULT '',
  description TEXT DEFAULT '',
  contact_person TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  registration_number TEXT DEFAULT '',
  logo_url TEXT,
  logo_initial TEXT DEFAULT 'CO',
  is_email_verified BOOLEAN DEFAULT false,
  verification_status TEXT DEFAULT 'not_submitted',
  account_status TEXT DEFAULT 'active',
  evidence_file_name TEXT,
  evidence_file_type TEXT,
  evidence_file_size TEXT,
  evidence_url TEXT,
  admin_feedback TEXT,
  reviewer_name TEXT,
  suspension_reason TEXT,
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS industry TEXT DEFAULT 'Software & Cloud Services';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS location TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS city TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS address TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS website TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS contact_person TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS registration_number TEXT DEFAULT '';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS logo_initial TEXT DEFAULT 'CO';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT false;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'not_submitted';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'active';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS evidence_file_name TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS evidence_file_type TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS evidence_file_size TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS evidence_url TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS admin_feedback TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS reviewer_name TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_verification_status_check;

-- ----------------------------------------------------------------------------
-- 4. STUDENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  phone TEXT DEFAULT '',
  university TEXT,
  department TEXT DEFAULT 'Computer Science',
  degree TEXT DEFAULT 'BS',
  semester TEXT DEFAULT '1st Semester',
  cgpa DOUBLE PRECISION DEFAULT 0.0,
  bio TEXT DEFAULT '',
  resume_url TEXT DEFAULT '',
  github_url TEXT DEFAULT '',
  portfolio_url TEXT DEFAULT '',
  skills TEXT[] DEFAULT '{}',
  verification_status TEXT DEFAULT 'pending',
  verification_doc TEXT DEFAULT '',
  account_status TEXT DEFAULT 'active',
  suspension_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.students ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS department TEXT DEFAULT 'Computer Science';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS degree TEXT DEFAULT 'BS';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS semester TEXT DEFAULT '1st Semester';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS cgpa DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT '';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS resume_url TEXT DEFAULT '';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS github_url TEXT DEFAULT '';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS portfolio_url TEXT DEFAULT '';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT '{}';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS verification_doc TEXT DEFAULT '';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'active';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ----------------------------------------------------------------------------
-- 4A. PRIVATE STUDENT PAYMENT METHODS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_payment_methods (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('Bank Account', 'JazzCash', 'Easypaisa')),
  account_number TEXT NOT NULL
    CHECK (length(btrim(account_number)) BETWEEN 1 AND 50),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 5. PROJECTS / SPRINTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID,
  posted_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  company_name TEXT,
  category TEXT DEFAULT 'Development',
  description TEXT,
  requirements TEXT DEFAULT '',
  deliverables TEXT DEFAULT '',
  additional_instructions TEXT DEFAULT '',
  work_mode TEXT DEFAULT 'Remote',
  duration TEXT DEFAULT '3-4 Weeks',
  deadline TEXT DEFAULT 'Flexible',
  openings INTEGER DEFAULT 1,
  skills TEXT[] DEFAULT '{}',
  stipend TEXT DEFAULT 'Academic Credit / Verified Certificate',
  budget TEXT DEFAULT '',
  status TEXT DEFAULT 'Open',
  assigned_student TEXT,
  progress DOUBLE PRECISION DEFAULT 0.0,
  payment_sent BOOLEAN NOT NULL DEFAULT FALSE,
  attachment_url TEXT,
  moderation_reason TEXT,
  moderator_name TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS posted_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'Development';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS requirements TEXT DEFAULT '';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS deliverables TEXT DEFAULT '';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS additional_instructions TEXT DEFAULT '';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS work_mode TEXT DEFAULT 'Remote';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS duration TEXT DEFAULT '3-4 Weeks';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS deadline TEXT DEFAULT 'Flexible';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS openings INTEGER DEFAULT 1;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT '{}';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS stipend TEXT DEFAULT 'Academic Credit / Verified Certificate';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS budget TEXT DEFAULT '';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Open';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS assigned_student TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS progress DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS payment_sent BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS moderation_reason TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS moderator_name TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

ALTER TABLE public.projects DROP CONSTRAINT IF EXISTS projects_status_check;

UPDATE public.projects SET posted_by = user_id WHERE posted_by IS NULL AND user_id IS NOT NULL;
UPDATE public.projects SET user_id = posted_by WHERE user_id IS NULL AND posted_by IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 6. APPLICATIONS & SUBMITTED WORK TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID,
  project_title TEXT,
  company_id UUID,
  company_name TEXT,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  student_name TEXT,
  student_email TEXT,
  university TEXT,
  student_degree TEXT DEFAULT 'BS Computer Science',
  student_department TEXT DEFAULT 'Computer Science',
  student_semester TEXT DEFAULT 'Senior',
  student_cgpa DOUBLE PRECISION DEFAULT 0.0,
  skills TEXT[] DEFAULT '{}',
  availability TEXT DEFAULT '',
  cover_letter TEXT DEFAULT '',
  resume_link TEXT DEFAULT '',
  portfolio_link TEXT DEFAULT '',
  github_link TEXT DEFAULT '',
  submission_title TEXT DEFAULT '',
  submission_notes TEXT DEFAULT '',
  submitted_work_url TEXT DEFAULT '',
  file_name TEXT DEFAULT '',
  company_feedback TEXT,
  progress DOUBLE PRECISION DEFAULT 0.0,
  status TEXT DEFAULT 'Pending',
  report_status TEXT DEFAULT 'clear',
  report_reason TEXT,
  reported_by TEXT,
  investigation_notes JSONB DEFAULT '[]'::jsonb,
  review_history JSONB DEFAULT '[]'::jsonb,
  work_submitted_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS project_id UUID;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS project_title TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_name TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_email TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_degree TEXT DEFAULT 'BS Computer Science';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_department TEXT DEFAULT 'Computer Science';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_semester TEXT DEFAULT 'Senior';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_cgpa DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT '{}';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS availability TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS cover_letter TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS resume_link TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS portfolio_link TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS github_link TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_title TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_notes TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submitted_work_url TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS file_name TEXT DEFAULT '';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS company_feedback TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS progress DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Pending';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS report_status TEXT DEFAULT 'clear';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS report_reason TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS reported_by TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS investigation_notes JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS review_history JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS work_submitted_at TIMESTAMPTZ;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

ALTER TABLE public.applications DROP CONSTRAINT IF EXISTS applications_status_check;

UPDATE public.applications SET student_id = user_id WHERE student_id IS NULL AND user_id IS NOT NULL;
UPDATE public.applications SET user_id = student_id WHERE user_id IS NULL AND student_id IS NOT NULL;

-- A private, server-authoritative record of company selections.
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

-- ----------------------------------------------------------------------------
-- 7. CERTIFICATES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  certificate_id TEXT,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  student_name TEXT,
  student_university TEXT DEFAULT '',
  student_degree TEXT DEFAULT '',
  company_id UUID,
  company_name TEXT DEFAULT '',
  project_id UUID,
  project_title TEXT,
  certificate_title TEXT DEFAULT 'Certificate of Project Completion',
  certificate_type TEXT DEFAULT 'completion',
  issuer TEXT,
  issue_date TEXT,
  overall_rating DOUBLE PRECISION DEFAULT 5.0,
  recommendation_letter TEXT DEFAULT '',
  signatory_name TEXT DEFAULT '',
  signatory_title TEXT DEFAULT 'Corporate Partner',
  status TEXT DEFAULT 'valid',
  cryptographic_hash TEXT DEFAULT '',
  verification_url TEXT DEFAULT '',
  revocation_reason TEXT,
  revoking_admin_name TEXT,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS certificate_id TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS student_name TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS student_university TEXT DEFAULT '';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS student_degree TEXT DEFAULT '';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS company_name TEXT DEFAULT '';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS project_id UUID;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS project_title TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS certificate_title TEXT DEFAULT 'Certificate of Project Completion';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS certificate_type TEXT DEFAULT 'completion';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS issuer TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS issue_date TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS overall_rating DOUBLE PRECISION DEFAULT 5.0;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS recommendation_letter TEXT DEFAULT '';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS signatory_name TEXT DEFAULT '';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS signatory_title TEXT DEFAULT 'Corporate Partner';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'valid';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS cryptographic_hash TEXT DEFAULT '';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS verification_url TEXT DEFAULT '';
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS revocation_reason TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS revoking_admin_name TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS pdf_url TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ----------------------------------------------------------------------------
-- 8. SAVED PROJECTS, SUPPORT TICKETS, USER SETTINGS, TAXONOMIES & AUDIT LOGS
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;

CREATE TABLE IF NOT EXISTS public.saved_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  project_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, project_id)
);

CREATE TABLE IF NOT EXISTS public.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_name TEXT,
  user_email TEXT,
  user_role TEXT DEFAULT 'Student',
  category TEXT,
  subject TEXT,
  message TEXT,
  status TEXT DEFAULT 'Open',
  admin_response TEXT,
  assigned_to TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_prefs JSONB DEFAULT '{}'::jsonb,
  privacy_settings JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.platform_taxonomies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_type TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(item_type, name)
);

CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_email TEXT,
  action TEXT,
  target TEXT,
  details TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 11. ADMIN HELPER FUNCTION (SECURITY DEFINER, NO RECURSION)
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
-- 12. AUTOMATED TRIGGER: AUTO INSERT STUDENT / COMPANY UPON AUTH SIGNUP
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  role_val TEXT;
  name_val TEXT;
  uni_val TEXT;
BEGIN
  role_val := COALESCE(new.raw_user_meta_data->>'user_type', 'Student');
  name_val := COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
  uni_val  := COALESCE(new.raw_user_meta_data->>'university', '');

  INSERT INTO public.profiles (id, name, email, user_type, university)
  VALUES (new.id, name_val, new.email, role_val, uni_val)
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      user_type = EXCLUDED.user_type,
      university = COALESCE(NULLIF(EXCLUDED.university, ''), public.profiles.university),
      updated_at = timezone('utc'::text, now());

  IF lower(role_val) = 'company' THEN
    IF NOT EXISTS (SELECT 1 FROM public.companies WHERE user_id = new.id) THEN
      INSERT INTO public.companies (user_id, company_name, email, industry, verification_status, logo_initial)
      VALUES (
        new.id,
        name_val,
        new.email,
        COALESCE(NULLIF(uni_val, ''), 'Software & Cloud Services'),
        'not_submitted',
        upper(left(regexp_replace(name_val, '[^a-zA-Z0-9]', '', 'g') || 'CO', 2))
      );
    END IF;
  ELSIF lower(role_val) = 'student' THEN
    IF NOT EXISTS (SELECT 1 FROM public.students WHERE user_id = new.id) THEN
      INSERT INTO public.students (user_id, full_name, email, university)
      VALUES (new.id, name_val, new.email, uni_val);
    END IF;
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 12B. DIRECT SIGNUP AUTO-CONFIRMATION & IN-APP AUTH RPCs (NO EMAIL LIMITS)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.auto_confirm_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  new.email_confirmed_at := COALESCE(new.email_confirmed_at, timezone('utc'::text, now()));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_auto_confirm ON auth.users;
CREATE TRIGGER on_auth_user_auto_confirm
  BEFORE INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_auth_user();

UPDATE auth.users
SET email_confirmed_at = COALESCE(email_confirmed_at, timezone('utc'::text, now()))
WHERE email_confirmed_at IS NULL;

CREATE OR REPLACE FUNCTION public.confirm_user_email_in_app(target_email TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  clean_email TEXT := lower(trim(COALESCE(target_email, '')));
BEGIN
  IF clean_email = '' THEN
    RETURN;
  END IF;
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, timezone('utc'::text, now())),
      confirmation_token = COALESCE(confirmation_token, ''),
      updated_at = timezone('utc'::text, now())
  WHERE lower(email) = clean_email;
END;
$$;

CREATE OR REPLACE FUNCTION public.register_user_in_app(
  target_email TEXT,
  target_password TEXT,
  full_name TEXT DEFAULT '',
  user_type TEXT DEFAULT 'Student',
  organization TEXT DEFAULT ''
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  clean_email TEXT := lower(trim(COALESCE(target_email, '')));
  clean_pass TEXT := trim(COALESCE(target_password, ''));
  clean_name TEXT := trim(COALESCE(full_name, ''));
  clean_org TEXT := trim(COALESCE(organization, ''));
  clean_role TEXT := CASE WHEN lower(trim(COALESCE(user_type, ''))) = 'company' THEN 'Company' ELSE 'Student' END;
  new_uid UUID := gen_random_uuid();
  detected_instance_id UUID := '00000000-0000-0000-0000-000000000000'::UUID;
  col_name TEXT;
BEGIN
  IF clean_email = '' OR clean_pass = '' THEN
    RAISE EXCEPTION 'Email and password are required.';
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = clean_email) THEN
    RAISE EXCEPTION 'An account with this email already exists.';
  END IF;

  IF clean_name = '' THEN
    clean_name := split_part(clean_email, '@', 1);
  END IF;

  SELECT instance_id INTO detected_instance_id
  FROM auth.users
  WHERE instance_id IS NOT NULL
  LIMIT 1;
  detected_instance_id := COALESCE(
    detected_instance_id,
    '00000000-0000-0000-0000-000000000000'::UUID
  );

  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    detected_instance_id,
    new_uid,
    'authenticated',
    'authenticated',
    clean_email,
    crypt(clean_pass, gen_salt('bf')),
    timezone('utc'::text, now()),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'name', clean_name,
      'user_type', clean_role,
      'university', clean_org
    ),
    timezone('utc'::text, now()),
    timezone('utc'::text, now())
  );

  FOR col_name IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name = 'users'
      AND column_name IN (
        'confirmation_token',
        'recovery_token',
        'email_change_token_new',
        'email_change',
        'email_change_token_current',
        'reauthentication_token',
        'phone_change',
        'phone_change_token'
      )
  LOOP
    EXECUTE format(
      'UPDATE auth.users SET %I = COALESCE(%I, '''') WHERE id = $1 AND %I IS NULL',
      col_name, col_name, col_name
    ) USING new_uid;
  END LOOP;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_sso_user'
  ) THEN
    EXECUTE 'UPDATE auth.users SET is_sso_user = COALESCE(is_sso_user, false) WHERE id = $1' USING new_uid;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_anonymous'
  ) THEN
    EXECUTE 'UPDATE auth.users SET is_anonymous = COALESCE(is_anonymous, false) WHERE id = $1' USING new_uid;
  END IF;

  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    new_uid,
    jsonb_build_object(
      'sub', new_uid::text,
      'email', clean_email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    new_uid::text,
    timezone('utc'::text, now()),
    timezone('utc'::text, now()),
    timezone('utc'::text, now())
  );

  RETURN new_uid;
END;
$$;

CREATE OR REPLACE FUNCTION public.reset_user_password_in_app(
  target_email TEXT,
  new_password TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  clean_email TEXT := lower(trim(COALESCE(target_email, '')));
  clean_pass TEXT := trim(COALESCE(new_password, ''));
  target_uid UUID;
  col_name TEXT;
BEGIN
  IF clean_email = '' THEN
    RAISE EXCEPTION 'Please enter your email address.';
  END IF;
  IF clean_pass = '' THEN
    RAISE EXCEPTION 'Please enter a new password.';
  END IF;

  SELECT id INTO target_uid
  FROM auth.users
  WHERE lower(email) = clean_email
  LIMIT 1;

  IF target_uid IS NULL THEN
    RAISE EXCEPTION 'No account found for this email address.';
  END IF;

  UPDATE auth.users
  SET encrypted_password = crypt(clean_pass, gen_salt('bf')),
      email_confirmed_at = COALESCE(email_confirmed_at, timezone('utc'::text, now())),
      updated_at = timezone('utc'::text, now())
  WHERE id = target_uid;

  FOR col_name IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name = 'users'
      AND column_name IN (
        'confirmation_token',
        'recovery_token',
        'email_change_token_new',
        'email_change',
        'email_change_token_current',
        'reauthentication_token',
        'phone_change',
        'phone_change_token'
      )
  LOOP
    EXECUTE format(
      'UPDATE auth.users SET %I = COALESCE(%I, '''') WHERE id = $1 AND %I IS NULL',
      col_name, col_name, col_name
    ) USING target_uid;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.provision_admin_in_app(
  target_email TEXT,
  target_password TEXT,
  full_name TEXT DEFAULT 'Platform Administrator',
  department TEXT DEFAULT 'SkillBridge Governance Council'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  clean_email TEXT := lower(trim(COALESCE(target_email, '')));
  clean_pass TEXT := trim(COALESCE(target_password, ''));
  clean_name TEXT := trim(COALESCE(full_name, ''));
  clean_dept TEXT := trim(COALESCE(department, ''));
  new_uid UUID := gen_random_uuid();
  detected_instance_id UUID := '00000000-0000-0000-0000-000000000000'::UUID;
  col_name TEXT;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only authenticated administrators can provision admin accounts.';
  END IF;

  IF clean_email = '' OR clean_pass = '' THEN
    RAISE EXCEPTION 'Administrator email and password are required.';
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = clean_email) THEN
    RAISE EXCEPTION 'An account with this email already exists.';
  END IF;

  IF clean_name = '' THEN
    clean_name := 'Platform Administrator';
  END IF;
  IF clean_dept = '' THEN
    clean_dept := 'SkillBridge Governance Council';
  END IF;

  SELECT instance_id INTO detected_instance_id
  FROM auth.users
  WHERE instance_id IS NOT NULL
  LIMIT 1;
  detected_instance_id := COALESCE(
    detected_instance_id,
    '00000000-0000-0000-0000-000000000000'::UUID
  );

  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    detected_instance_id,
    new_uid,
    'authenticated',
    'authenticated',
    clean_email,
    crypt(clean_pass, gen_salt('bf')),
    timezone('utc'::text, now()),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'name', clean_name,
      'user_type', 'Admin',
      'university', clean_dept
    ),
    timezone('utc'::text, now()),
    timezone('utc'::text, now())
  );

  FOR col_name IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name = 'users'
      AND column_name IN (
        'confirmation_token',
        'recovery_token',
        'email_change_token_new',
        'email_change',
        'email_change_token_current',
        'reauthentication_token',
        'phone_change',
        'phone_change_token'
      )
  LOOP
    EXECUTE format(
      'UPDATE auth.users SET %I = COALESCE(%I, '''') WHERE id = $1 AND %I IS NULL',
      col_name, col_name, col_name
    ) USING new_uid;
  END LOOP;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_sso_user'
  ) THEN
    EXECUTE 'UPDATE auth.users SET is_sso_user = COALESCE(is_sso_user, false) WHERE id = $1' USING new_uid;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_anonymous'
  ) THEN
    EXECUTE 'UPDATE auth.users SET is_anonymous = COALESCE(is_anonymous, false) WHERE id = $1' USING new_uid;
  END IF;

  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    new_uid,
    jsonb_build_object(
      'sub', new_uid::text,
      'email', clean_email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    new_uid::text,
    timezone('utc'::text, now()),
    timezone('utc'::text, now()),
    timezone('utc'::text, now())
  );

  INSERT INTO public.profiles (id, name, email, user_type, university, is_verified, account_status)
  VALUES (new_uid, clean_name, clean_email, 'Admin', clean_dept, true, 'active')
  ON CONFLICT (id) DO UPDATE
  SET user_type = 'Admin',
      name = EXCLUDED.name,
      university = EXCLUDED.university,
      is_verified = true,
      account_status = 'active';

  RETURN new_uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.confirm_user_email_in_app(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.register_user_in_app(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_user_password_in_app(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.provision_admin_in_app(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 13. SUPABASE STORAGE BUCKETS (PUBLIC VISIBILITY)
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('public-files', 'public-files', true),
  ('company-assets', 'company-assets', true),
  ('student-docs', 'student-docs', true),
  ('certificates', 'certificates', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ----------------------------------------------------------------------------
-- 14. STORAGE ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public Storage Read" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Storage Upload" ON storage.objects;
DROP POLICY IF EXISTS "Owner Storage Update" ON storage.objects;
DROP POLICY IF EXISTS "Owner Storage Delete" ON storage.objects;

CREATE POLICY "Public Storage Read"
ON storage.objects FOR SELECT
USING (bucket_id IN ('public-files', 'company-assets', 'student-docs', 'certificates'));

CREATE POLICY "Authenticated Storage Upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id IN ('public-files', 'company-assets', 'student-docs', 'certificates'));

CREATE POLICY "Owner Storage Update"
ON storage.objects FOR UPDATE
TO authenticated
USING (auth.uid() = owner OR public.is_admin());

CREATE POLICY "Owner Storage Delete"
ON storage.objects FOR DELETE
TO authenticated
USING (auth.uid() = owner OR public.is_admin());

-- ----------------------------------------------------------------------------
-- 15. TABLE ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_payment_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_taxonomies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles Public View" ON public.profiles;
DROP POLICY IF EXISTS "Profiles Self Insert" ON public.profiles;
DROP POLICY IF EXISTS "Profiles Self Update" ON public.profiles;
DROP POLICY IF EXISTS "Profiles Self Manage" ON public.profiles;
DROP TRIGGER IF EXISTS prevent_profile_role_changes ON public.profiles;

DROP POLICY IF EXISTS "Companies Public View" ON public.companies;
DROP POLICY IF EXISTS "Companies Self Manage" ON public.companies;

DROP POLICY IF EXISTS "Students Public View" ON public.students;
DROP POLICY IF EXISTS "Students Self Manage" ON public.students;
DROP POLICY IF EXISTS "Student Payment Methods Owner Access" ON public.student_payment_methods;

DROP POLICY IF EXISTS "Projects Public View" ON public.projects;
DROP POLICY IF EXISTS "Projects Company Manage" ON public.projects;

DROP POLICY IF EXISTS "Applications Student Manage" ON public.applications;
DROP POLICY IF EXISTS "Applications Company View" ON public.applications;
DROP POLICY IF EXISTS "Applications Company Manage" ON public.applications;
DROP POLICY IF EXISTS "Applications Company Delete" ON public.applications;
DROP POLICY IF EXISTS "Applications Admin Manage" ON public.applications;
DROP TRIGGER IF EXISTS prevent_application_identity_insert ON public.applications;
DROP TRIGGER IF EXISTS prevent_application_identity_changes ON public.applications;

DROP POLICY IF EXISTS "Certificates Public View" ON public.certificates;
DROP POLICY IF EXISTS "Certificates Authenticated Manage" ON public.certificates;

DROP POLICY IF EXISTS "Saved Projects User Access" ON public.saved_projects;
DROP POLICY IF EXISTS "Support Tickets Access" ON public.support_tickets;
DROP POLICY IF EXISTS "User Settings Self Access" ON public.user_settings;
DROP POLICY IF EXISTS "Platform Taxonomies Public Read" ON public.platform_taxonomies;
DROP POLICY IF EXISTS "Platform Taxonomies Admin Manage" ON public.platform_taxonomies;
DROP POLICY IF EXISTS "Admin Audit Logs Access" ON public.admin_audit_logs;

CREATE POLICY "Profiles Public View" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles Self Insert" ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id OR public.is_admin());
CREATE POLICY "Profiles Self Update" ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id OR public.is_admin());

CREATE OR REPLACE FUNCTION public.prevent_profile_role_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  IF auth.uid() IS NOT NULL
    AND auth.uid() = OLD.id
    AND NOT public.is_admin()
    AND NEW.user_type IS DISTINCT FROM OLD.user_type
  THEN
    RAISE EXCEPTION 'Account roles cannot be changed by the account owner.';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER prevent_profile_role_changes
BEFORE UPDATE OF user_type ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.prevent_profile_role_changes();

CREATE POLICY "Companies Public View" ON public.companies FOR SELECT USING (true);
CREATE POLICY "Companies Self Manage" ON public.companies FOR ALL TO authenticated
  USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Students Public View" ON public.students FOR SELECT USING (true);
CREATE POLICY "Students Self Manage" ON public.students FOR ALL TO authenticated
  USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

REVOKE ALL ON TABLE public.student_payment_methods FROM anon, PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.student_payment_methods TO authenticated;
CREATE POLICY "Student Payment Methods Owner Access"
ON public.student_payment_methods FOR ALL TO authenticated
USING (auth.uid() = user_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR public.is_admin());

REVOKE ALL ON TABLE public.project_assignments FROM anon, PUBLIC, authenticated;
REVOKE ALL ON TABLE public.project_payment_confirmations
  FROM anon, PUBLIC, authenticated;

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

CREATE POLICY "Projects Public View" ON public.projects FOR SELECT USING (true);
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

CREATE POLICY "Applications Company Delete" ON public.applications FOR DELETE TO authenticated
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

DROP TRIGGER IF EXISTS enforce_application_bid_rules ON public.applications;
CREATE TRIGGER enforce_application_bid_rules
BEFORE INSERT OR UPDATE OF project_id, student_id, user_id ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.enforce_application_bid_rules();

DROP TRIGGER IF EXISTS enforce_application_assignment_status ON public.applications;
CREATE TRIGGER enforce_application_assignment_status
BEFORE INSERT OR UPDATE OF status ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.enforce_application_assignment_status();

DROP TRIGGER IF EXISTS guard_project_payment_sent_update ON public.projects;
CREATE TRIGGER guard_project_payment_sent_update
BEFORE UPDATE OF payment_sent ON public.projects
FOR EACH ROW
EXECUTE FUNCTION public.guard_project_payment_sent_update();

CREATE TRIGGER prevent_application_identity_insert
BEFORE INSERT ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.prevent_application_identity_changes();

CREATE TRIGGER prevent_application_identity_changes
BEFORE UPDATE OF student_id, user_id ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.prevent_application_identity_changes();

CREATE POLICY "Applications Admin Manage" ON public.applications FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Certificates Public View" ON public.certificates FOR SELECT USING (true);
CREATE POLICY "Certificates Authenticated Manage" ON public.certificates FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Saved Projects User Access" ON public.saved_projects FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Support Tickets Access" ON public.support_tickets FOR ALL TO authenticated
  USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "User Settings Self Access" ON public.user_settings FOR ALL TO authenticated
  USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Platform Taxonomies Public Read" ON public.platform_taxonomies FOR SELECT USING (true);
CREATE POLICY "Platform Taxonomies Admin Manage" ON public.platform_taxonomies FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Admin Audit Logs Access" ON public.admin_audit_logs FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ----------------------------------------------------------------------------
-- 16. DEFAULT ADMIN SETUP
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  admin_uid UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  existing_uid UUID;
  detected_instance_id UUID := '00000000-0000-0000-0000-000000000000'::UUID;
  admin_email TEXT := 'admin@skillbridge.edu.pk';
  admin_pass  TEXT := 'Admin@SkillBridge2026!';
  col_name TEXT;
BEGIN
  PERFORM set_config('search_path', 'public, auth, extensions', true);

  SELECT instance_id INTO detected_instance_id
  FROM auth.users
  WHERE instance_id IS NOT NULL
  LIMIT 1;
  detected_instance_id := COALESCE(
    detected_instance_id,
    '00000000-0000-0000-0000-000000000000'::UUID
  );

  SELECT id INTO existing_uid FROM auth.users WHERE lower(email) = admin_email LIMIT 1;
  IF existing_uid IS NULL THEN
    SELECT id INTO existing_uid FROM auth.users WHERE lower(email) = 'admin@campusconnect.edu.pk' LIMIT 1;
  END IF;
  IF existing_uid IS NULL THEN
    SELECT id INTO existing_uid FROM auth.users WHERE id = admin_uid LIMIT 1;
  END IF;

  IF existing_uid IS NULL THEN
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      detected_instance_id,
      admin_uid,
      'authenticated',
      'authenticated',
      admin_email,
      crypt(admin_pass, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"name":"Executive Administrator","user_type":"Admin","university":"SkillBridge Governance Council"}'::jsonb,
      now(),
      now()
    );
    existing_uid := admin_uid;
  ELSE
    UPDATE auth.users
    SET instance_id = COALESCE(instance_id, detected_instance_id),
        aud = 'authenticated',
        role = 'authenticated',
        email = admin_email,
        encrypted_password = crypt(admin_pass, gen_salt('bf')),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
        raw_user_meta_data = '{"name":"Executive Administrator","user_type":"Admin","university":"SkillBridge Governance Council"}'::jsonb,
        updated_at = now()
    WHERE id = existing_uid;
  END IF;

  -- Prevent GoTrue "Database error querying schema" caused by NULL string token columns
  FOR col_name IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'auth'
      AND table_name = 'users'
      AND column_name IN (
        'confirmation_token',
        'recovery_token',
        'email_change_token_new',
        'email_change',
        'email_change_token_current',
        'reauthentication_token',
        'phone_change',
        'phone_change_token'
      )
  LOOP
    EXECUTE format(
      'UPDATE auth.users SET %I = COALESCE(%I, '''') WHERE id = $1 AND %I IS NULL',
      col_name, col_name, col_name
    ) USING existing_uid;
  END LOOP;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_sso_user'
  ) THEN
    EXECUTE 'UPDATE auth.users SET is_sso_user = COALESCE(is_sso_user, false) WHERE id = $1' USING existing_uid;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_anonymous'
  ) THEN
    EXECUTE 'UPDATE auth.users SET is_anonymous = COALESCE(is_anonymous, false) WHERE id = $1' USING existing_uid;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM auth.identities WHERE user_id = existing_uid AND provider = 'email'
  ) THEN
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      existing_uid,
      jsonb_build_object(
        'sub', existing_uid::text,
        'email', admin_email,
        'email_verified', true,
        'phone_verified', false
      ),
      'email',
      existing_uid::text,
      now(),
      now(),
      now()
    );
  ELSE
    UPDATE auth.identities
    SET identity_data = jsonb_build_object(
          'sub', existing_uid::text,
          'email', admin_email,
          'email_verified', true,
          'phone_verified', false
        ),
        provider_id = CASE
          WHEN COALESCE(provider_id, '') = '' OR lower(provider_id) LIKE '%@%' THEN existing_uid::text
          ELSE provider_id
        END,
        updated_at = now()
    WHERE user_id = existing_uid AND provider = 'email';
  END IF;

  INSERT INTO public.profiles (id, name, email, user_type, university, is_verified, account_status)
  VALUES (
    existing_uid,
    'Executive Administrator',
    admin_email,
    'Admin',
    'SkillBridge Governance Council',
    true,
    'active'
  )
  ON CONFLICT (id) DO UPDATE
  SET user_type = 'Admin',
      email = EXCLUDED.email,
      name = 'Executive Administrator',
      university = 'SkillBridge Governance Council',
      is_verified = true,
      account_status = 'active';
END $$;

-- ----------------------------------------------------------------------------
-- 17. COMPANY PANEL PRODUCTION HARDENING, INDEXES & DELETE ACCOUNT RPC
-- ----------------------------------------------------------------------------

-- 17a. Deduplicate public.companies by user_id & enforce unique company per user
DELETE FROM public.companies a
USING public.companies b
WHERE a.user_id IS NOT NULL
  AND a.user_id = b.user_id
  AND (
    COALESCE(a.updated_at, a.created_at, now()) < COALESCE(b.updated_at, b.created_at, now())
    OR (
      COALESCE(a.updated_at, a.created_at, now()) = COALESCE(b.updated_at, b.created_at, now())
      AND a.ctid < b.ctid
    )
  );

CREATE UNIQUE INDEX IF NOT EXISTS idx_companies_unique_user_id
  ON public.companies (user_id)
  WHERE user_id IS NOT NULL;

-- 17b. Backfill missing company rows for existing Company auth accounts
INSERT INTO public.companies (
  user_id,
  company_name,
  email,
  industry,
  verification_status,
  logo_initial
)
SELECT
  p.id,
  COALESCE(NULLIF(trim(p.name), ''), NULLIF(split_part(COALESCE(p.email, ''), '@', 1), ''), 'Company Partner'),
  COALESCE(p.email, ''),
  COALESCE(NULLIF(trim(p.university), ''), 'Software & Cloud Services'),
  'not_submitted',
  upper(left(regexp_replace(COALESCE(NULLIF(trim(p.name), ''), 'CO'), '[^a-zA-Z0-9]', '', 'g') || 'CO', 2))
FROM public.profiles p
WHERE lower(COALESCE(p.user_type, '')) = 'company'
  AND NOT EXISTS (
    SELECT 1 FROM public.companies c WHERE c.user_id = p.id
  );

-- 17c. Backfill company_id on projects & applications
UPDATE public.projects p
SET company_id = c.id
FROM public.companies c
WHERE p.company_id IS NULL
  AND c.user_id IN (p.posted_by, p.user_id);

UPDATE public.applications a
SET company_id = p.company_id
FROM public.projects p
WHERE a.company_id IS NULL
  AND a.project_id = p.id
  AND p.company_id IS NOT NULL;

-- 17d. Deduplicate certificates per (student_id, project_id) & prevent duplicates
DELETE FROM public.certificates a
USING public.certificates b
WHERE a.student_id IS NOT NULL
  AND a.project_id IS NOT NULL
  AND a.student_id = b.student_id
  AND a.project_id = b.project_id
  AND (
    COALESCE(a.created_at, now()) < COALESCE(b.created_at, now())
    OR (COALESCE(a.created_at, now()) = COALESCE(b.created_at, now()) AND a.ctid < b.ctid)
  );

CREATE UNIQUE INDEX IF NOT EXISTS idx_certificates_student_project
  ON public.certificates (student_id, project_id)
  WHERE student_id IS NOT NULL AND project_id IS NOT NULL;

-- 17e. Account deletion RPC used by CompanySettingsService.deleteAccount()
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  uid UUID := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.applications
  WHERE project_id IN (
    SELECT p.id FROM public.projects p
    LEFT JOIN public.companies c ON c.id = p.company_id
    WHERE p.posted_by = uid OR p.user_id = uid OR c.user_id = uid
  )
  OR student_id = uid
  OR user_id = uid;

  DELETE FROM public.projects
  WHERE posted_by = uid
     OR user_id = uid
     OR company_id IN (SELECT id FROM public.companies WHERE user_id = uid);

  DELETE FROM public.companies WHERE user_id = uid;
  DELETE FROM public.students WHERE user_id = uid;
  DELETE FROM public.saved_projects WHERE user_id = uid;
  DELETE FROM public.support_tickets WHERE user_id = uid;
  DELETE FROM public.user_settings WHERE user_id = uid;
  DELETE FROM public.profiles WHERE id = uid;

  DELETE FROM auth.users WHERE id = uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- 17f. Performance indexes for Company, Student & Admin queries
CREATE INDEX IF NOT EXISTS idx_projects_posted_by ON public.projects (posted_by);
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON public.projects (user_id);
CREATE INDEX IF NOT EXISTS idx_projects_company_id ON public.projects (company_id);
CREATE INDEX IF NOT EXISTS idx_applications_project_id ON public.applications (project_id);
CREATE INDEX IF NOT EXISTS idx_applications_student_id ON public.applications (student_id);
CREATE INDEX IF NOT EXISTS idx_certificates_student_id ON public.certificates (student_id);

