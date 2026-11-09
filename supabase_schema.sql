-- ============================================================================
-- CAMPUSCONNECT / LINKVIBE — RESILIENT SUPABASE DATABASE & STORAGE SCHEMA
-- ============================================================================
-- Designed to run smoothly whether tables already exist or are brand new.
-- Safely creates tables, adds missing columns (ALTER TABLE ADD COLUMN IF NOT EXISTS),
-- sets up triggers, public storage buckets, and permissive RLS policies.
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
  phone TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Ensure all columns exist if table was created previously
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS user_type TEXT DEFAULT 'Student';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ----------------------------------------------------------------------------
-- 3. COMPANIES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  company_name TEXT,
  email TEXT,
  industry TEXT DEFAULT 'Information Technology',
  location TEXT DEFAULT 'Lahore, Pakistan',
  website TEXT,
  description TEXT,
  logo_url TEXT,
  verification_status TEXT DEFAULT 'verified',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS industry TEXT DEFAULT 'Information Technology';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS location TEXT DEFAULT 'Lahore, Pakistan';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'verified';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ----------------------------------------------------------------------------
-- 4. STUDENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  university TEXT,
  department TEXT DEFAULT 'Computer Science',
  degree TEXT DEFAULT 'BS',
  bio TEXT,
  resume_url TEXT,
  skills TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.students ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS department TEXT DEFAULT 'Computer Science';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS degree TEXT DEFAULT 'BS';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS resume_url TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT '{}';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

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
  requirements TEXT,
  duration TEXT DEFAULT '4-6 Weeks',
  stipend TEXT DEFAULT 'Academic Credit / Verified Certificate',
  budget TEXT,
  status TEXT DEFAULT 'Open',
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Crucial: Ensure posted_by and all columns exist regardless of old table definition
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS posted_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'Development';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS requirements TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS duration TEXT DEFAULT '4-6 Weeks';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS stipend TEXT DEFAULT 'Academic Credit / Verified Certificate';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS budget TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Open';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Synchronize user_id and posted_by for compatibility with both schemas
UPDATE public.projects SET posted_by = user_id WHERE posted_by IS NULL AND user_id IS NOT NULL;
UPDATE public.projects SET user_id = posted_by WHERE user_id IS NULL AND posted_by IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 6. APPLICATIONS & SUBMITTED WORK TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  student_name TEXT,
  student_email TEXT,
  university TEXT,
  cover_letter TEXT,
  resume_link TEXT,
  github_link TEXT,
  submission_notes TEXT,
  status TEXT DEFAULT 'Pending',
  submitted_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS project_id UUID;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_name TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS student_email TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS university TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS cover_letter TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS resume_link TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS github_link TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_notes TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Pending';
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

UPDATE public.applications SET student_id = user_id WHERE student_id IS NULL AND user_id IS NOT NULL;
UPDATE public.applications SET user_id = student_id WHERE user_id IS NULL AND student_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 7. CERTIFICATES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  certificate_id TEXT,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  student_name TEXT,
  project_id UUID,
  project_title TEXT,
  certificate_title TEXT,
  issuer TEXT,
  issue_date TEXT,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS certificate_id TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS student_name TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS project_id UUID;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS project_title TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS certificate_title TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS issuer TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS issue_date TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS pdf_url TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ----------------------------------------------------------------------------
-- 8. MESSAGES / CHAT TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT,
  receiver_name TEXT,
  project_title TEXT,
  message_text TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS sender_name TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS receiver_name TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS project_title TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS message_text TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ----------------------------------------------------------------------------
-- 9. NOTIFICATIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  message TEXT,
  type TEXT DEFAULT 'general',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'general';
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ----------------------------------------------------------------------------
-- 10. AUTOMATED TRIGGER: AUTO INSERT STUDENT / COMPANY UPON AUTH SIGNUP
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
  uni_val  := COALESCE(new.raw_user_meta_data->>'university', 'National University');

  INSERT INTO public.profiles (id, name, email, user_type, university)
  VALUES (new.id, name_val, new.email, role_val, uni_val)
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      user_type = EXCLUDED.user_type,
      university = EXCLUDED.university,
      updated_at = timezone('utc'::text, now());

  IF role_val = 'Company' THEN
    INSERT INTO public.companies (user_id, company_name, email, industry)
    VALUES (new.id, name_val, new.email, uni_val)
    ON CONFLICT (user_id) DO NOTHING;
  ELSIF role_val = 'Student' THEN
    INSERT INTO public.students (user_id, full_name, email, university)
    VALUES (new.id, name_val, new.email, uni_val)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 11. SUPABASE STORAGE BUCKETS (PUBLIC VISIBILITY)
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('public-files', 'public-files', true),
  ('company-assets', 'company-assets', true),
  ('student-docs', 'student-docs', true),
  ('certificates', 'certificates', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ----------------------------------------------------------------------------
-- 12. STORAGE ROW LEVEL SECURITY (RLS) POLICIES
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
USING (auth.uid() = owner);

CREATE POLICY "Owner Storage Delete"
ON storage.objects FOR DELETE
TO authenticated
USING (auth.uid() = owner);

-- ----------------------------------------------------------------------------
-- 13. TABLE ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to ensure clean idempotent run
DROP POLICY IF EXISTS "Profiles Public View" ON public.profiles;
DROP POLICY IF EXISTS "Profiles Self Insert" ON public.profiles;
DROP POLICY IF EXISTS "Profiles Self Update" ON public.profiles;
DROP POLICY IF EXISTS "Companies Public View" ON public.companies;
DROP POLICY IF EXISTS "Companies Self Manage" ON public.companies;
DROP POLICY IF EXISTS "Students Public View" ON public.students;
DROP POLICY IF EXISTS "Students Self Manage" ON public.students;
DROP POLICY IF EXISTS "Projects Public View" ON public.projects;
DROP POLICY IF EXISTS "Projects Company Manage" ON public.projects;
DROP POLICY IF EXISTS "Applications Student Manage" ON public.applications;
DROP POLICY IF EXISTS "Applications Company View" ON public.applications;
DROP POLICY IF EXISTS "Certificates Public View" ON public.certificates;
DROP POLICY IF EXISTS "Certificates Authenticated Manage" ON public.certificates;
DROP POLICY IF EXISTS "Messages Participant Access" ON public.messages;
DROP POLICY IF EXISTS "Notifications User Access" ON public.notifications;

-- Profiles: Anyone can view, logged in users update their own
CREATE POLICY "Profiles Public View" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles Self Insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "Profiles Self Update" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Companies: Public view, company user manages own record
CREATE POLICY "Companies Public View" ON public.companies FOR SELECT USING (true);
CREATE POLICY "Companies Self Manage" ON public.companies FOR ALL TO authenticated USING (auth.uid() = user_id);

-- Students: Public view, student manages own record
CREATE POLICY "Students Public View" ON public.students FOR SELECT USING (true);
CREATE POLICY "Students Self Manage" ON public.students FOR ALL TO authenticated USING (auth.uid() = user_id);

-- Projects: Public view, company manages (matching posted_by OR user_id)
CREATE POLICY "Projects Public View" ON public.projects FOR SELECT USING (true);
CREATE POLICY "Projects Company Manage" ON public.projects FOR ALL TO authenticated
  USING (auth.uid() = posted_by OR auth.uid() = user_id);

-- Applications: Student manages own application, Company reviews
CREATE POLICY "Applications Student Manage" ON public.applications FOR ALL TO authenticated
  USING (auth.uid() = student_id OR auth.uid() = user_id);

CREATE POLICY "Applications Company View" ON public.applications FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.projects
    WHERE public.projects.id = public.applications.project_id
    AND (public.projects.posted_by = auth.uid() OR public.projects.user_id = auth.uid())
  ));

-- Certificates: Public can view & verify
CREATE POLICY "Certificates Public View" ON public.certificates FOR SELECT USING (true);
CREATE POLICY "Certificates Authenticated Manage" ON public.certificates FOR ALL TO authenticated USING (true);

-- Messages: Senders and receivers
CREATE POLICY "Messages Participant Access" ON public.messages FOR ALL TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Notifications: User has access to own notifications
CREATE POLICY "Notifications User Access" ON public.notifications FOR ALL TO authenticated
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 14. DEFAULT ADMIN SETUP SCRIPT
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  admin_uid UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  admin_email TEXT := 'admin@campusconnect.edu.pk';
  admin_pass  TEXT := 'Admin@CampusConnect2026!';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
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
      '00000000-0000-0000-0000-000000000000',
      admin_uid,
      'authenticated',
      'authenticated',
      admin_email,
      crypt(admin_pass, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"name":"CampusConnect Admin","user_type":"Admin","university":"CampusConnect Council"}',
      now(),
      now()
    );
  END IF;

  INSERT INTO public.profiles (id, name, email, user_type, university)
  VALUES (
    (SELECT id FROM auth.users WHERE email = admin_email LIMIT 1),
    'Executive Administrator',
    admin_email,
    'Admin',
    'CampusConnect Governance Council'
  )
  ON CONFLICT (id) DO UPDATE
  SET user_type = 'Admin',
      name = 'Executive Administrator';
END $$;
