-- ============================================================================
-- CAMPUSCONNECT / LINKVIBE — COMPLETE SUPABASE DATABASE & STORAGE SCHEMA
-- ============================================================================
-- Roles Supported:
--   1. Admin   : Pre-configured / default platform administrator (never publicly registrable)
--   2. Company : Corporate partners who register, post projects, view applications, and issue certificates
--   3. Student : University candidates who register, browse projects, submit work, and earn verified certificates
--
-- File Visibility:
--   • Both Student files (resumes, documents, avatars) and Company files (logos, attachments)
--     are hosted in PUBLIC Supabase Storage buckets with public read policies.
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
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  user_type TEXT NOT NULL CHECK (user_type IN ('Student', 'Company', 'Admin')),
  university TEXT,
  phone TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 3. COMPANIES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  company_name TEXT NOT NULL,
  email TEXT NOT NULL,
  industry TEXT DEFAULT 'Information Technology',
  location TEXT DEFAULT 'Lahore, Pakistan',
  website TEXT,
  description TEXT,
  logo_url TEXT,
  verification_status TEXT DEFAULT 'verified' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 4. STUDENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  university TEXT NOT NULL,
  department TEXT DEFAULT 'Computer Science',
  degree TEXT DEFAULT 'BS',
  bio TEXT,
  resume_url TEXT,
  skills TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 5. PROJECTS / SPRINTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
  posted_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  company_name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  requirements TEXT,
  duration TEXT DEFAULT '4-6 Weeks',
  stipend TEXT DEFAULT 'Academic Credit / Verified Certificate',
  status TEXT DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Completed', 'Closed')),
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 6. APPLICATIONS & SUBMITTED WORK TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  student_email TEXT NOT NULL,
  university TEXT,
  cover_letter TEXT,
  resume_link TEXT,
  github_link TEXT,
  submission_notes TEXT,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected', 'Under Review', 'Completed')),
  submitted_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 7. CERTIFICATES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  certificate_id TEXT UNIQUE NOT NULL,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  project_title TEXT NOT NULL,
  certificate_title TEXT NOT NULL,
  issuer TEXT NOT NULL,
  issue_date TEXT NOT NULL,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

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
  message_text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 9. NOTIFICATIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'general',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 10. AUTOMATED TRIGGER: ON NEW AUTH USER REGISTRATION
-- ----------------------------------------------------------------------------
-- Automatically inserts student or company rows upon auth.users signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  role_val TEXT;
  name_val TEXT;
  uni_val TEXT;
BEGIN
  -- Read user metadata passed from Flutter signUp()
  role_val := COALESCE(new.raw_user_meta_data->>'user_type', 'Student');
  name_val := COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
  uni_val  := COALESCE(new.raw_user_meta_data->>'university', 'National University');

  -- 1. Insert into public.profiles
  INSERT INTO public.profiles (id, name, email, user_type, university)
  VALUES (new.id, name_val, new.email, role_val, uni_val)
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      user_type = EXCLUDED.user_type,
      university = EXCLUDED.university,
      updated_at = timezone('utc'::text, now());

  -- 2. Insert into role specific table
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

-- Re-create trigger safely
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 11. SUPABASE STORAGE BUCKETS (PUBLIC ACCESS)
-- ----------------------------------------------------------------------------
-- Create public buckets so company logos and student files can be viewed by anyone
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
-- Drop existing policies if they exist to avoid duplication
DROP POLICY IF EXISTS "Public Storage Read" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Storage Upload" ON storage.objects;
DROP POLICY IF EXISTS "Owner Storage Update" ON storage.objects;
DROP POLICY IF EXISTS "Owner Storage Delete" ON storage.objects;

-- Allow EVERYONE (public) to view/read all uploaded student & company files
CREATE POLICY "Public Storage Read"
ON storage.objects FOR SELECT
USING (bucket_id IN ('public-files', 'company-assets', 'student-docs', 'certificates'));

-- Allow any authenticated user (student or company) to upload files
CREATE POLICY "Authenticated Storage Upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id IN ('public-files', 'company-assets', 'student-docs', 'certificates'));

-- Allow user to update their own files
CREATE POLICY "Owner Storage Update"
ON storage.objects FOR UPDATE
TO authenticated
USING (auth.uid() = owner);

-- Allow user to delete their own files
CREATE POLICY "Owner Storage Delete"
ON storage.objects FOR DELETE
TO authenticated
USING (auth.uid() = owner);

-- ----------------------------------------------------------------------------
-- 13. TABLE ROW LEVEL SECURITY (RLS)
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES Policies
DROP POLICY IF EXISTS "Profiles Public View" ON public.profiles;
DROP POLICY IF EXISTS "Profiles Self Update" ON public.profiles;
DROP POLICY IF EXISTS "Profiles Self Insert" ON public.profiles;

CREATE POLICY "Profiles Public View" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "Profiles Self Insert" ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Profiles Self Update" ON public.profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id);

-- COMPANIES Policies
DROP POLICY IF EXISTS "Companies Public View" ON public.companies;
DROP POLICY IF EXISTS "Companies Self Manage" ON public.companies;

CREATE POLICY "Companies Public View" ON public.companies
  FOR SELECT USING (true);

CREATE POLICY "Companies Self Manage" ON public.companies
  FOR ALL TO authenticated USING (auth.uid() = user_id);

-- STUDENTS Policies
DROP POLICY IF EXISTS "Students Public View" ON public.students;
DROP POLICY IF EXISTS "Students Self Manage" ON public.students;

CREATE POLICY "Students Public View" ON public.students
  FOR SELECT USING (true);

CREATE POLICY "Students Self Manage" ON public.students
  FOR ALL TO authenticated USING (auth.uid() = user_id);

-- PROJECTS Policies
DROP POLICY IF EXISTS "Projects Public View" ON public.projects;
DROP POLICY IF EXISTS "Projects Company Manage" ON public.projects;

CREATE POLICY "Projects Public View" ON public.projects
  FOR SELECT USING (true);

CREATE POLICY "Projects Company Manage" ON public.projects
  FOR ALL TO authenticated USING (auth.uid() = posted_by);

-- APPLICATIONS Policies
DROP POLICY IF EXISTS "Applications Student Manage" ON public.applications;
DROP POLICY IF EXISTS "Applications Company View" ON public.applications;

CREATE POLICY "Applications Student Manage" ON public.applications
  FOR ALL TO authenticated USING (auth.uid() = student_id);

CREATE POLICY "Applications Company View" ON public.applications
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.projects
    WHERE public.projects.id = public.applications.project_id
    AND public.projects.posted_by = auth.uid()
  ));

-- CERTIFICATES Policies
DROP POLICY IF EXISTS "Certificates Public View" ON public.certificates;
DROP POLICY IF EXISTS "Certificates Authenticated Manage" ON public.certificates;

CREATE POLICY "Certificates Public View" ON public.certificates
  FOR SELECT USING (true);

CREATE POLICY "Certificates Authenticated Manage" ON public.certificates
  FOR ALL TO authenticated USING (true);

-- MESSAGES Policies
DROP POLICY IF EXISTS "Messages Participant Access" ON public.messages;

CREATE POLICY "Messages Participant Access" ON public.messages
  FOR ALL TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- NOTIFICATIONS Policies
DROP POLICY IF EXISTS "Notifications User Access" ON public.notifications;

CREATE POLICY "Notifications User Access" ON public.notifications
  FOR ALL TO authenticated
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 14. DEFAULT ADMIN SEED / SETUP SCRIPT
-- ----------------------------------------------------------------------------
-- Use this query to establish the default Admin credentials in Supabase.
-- Credentials configured:
--   Email    : admin@campusconnect.edu.pk
--   Password : Admin@CampusConnect2026!
--   Role     : Admin
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  admin_uid UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  admin_email TEXT := 'admin@campusconnect.edu.pk';
  admin_pass  TEXT := 'Admin@CampusConnect2026!';
BEGIN
  -- 1. Insert admin into auth.users if not present
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

  -- 2. Ensure profile exists with role 'Admin'
  INSERT INTO public.profiles (
    id,
    name,
    email,
    user_type,
    university
  ) VALUES (
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
