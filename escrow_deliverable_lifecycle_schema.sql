-- =============================================================================
-- SKILLBRIDGE ESCROW, DELIVERABLE REVIEW & PAYOUT LIFECYCLE SCHEMA
-- Separate standalone SQL file created per user requirements.
-- Safe to execute repeatedly (Idempotent).
-- =============================================================================

-- 1. Ensure projects table has all deliverable review & escrow disbursal columns
DO $$
BEGIN
    -- Revision tracking columns (Strictly 1 revision allowed with 2-day deadline)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'revision_count') THEN
        ALTER TABLE projects ADD COLUMN revision_count INT DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'max_revisions') THEN
        ALTER TABLE projects ADD COLUMN max_revisions INT DEFAULT 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'revision_notes') THEN
        ALTER TABLE projects ADD COLUMN revision_notes TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'last_revision_requested_at') THEN
        ALTER TABLE projects ADD COLUMN last_revision_requested_at TIMESTAMPTZ;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'revision_deadline') THEN
        ALTER TABLE projects ADD COLUMN revision_deadline TIMESTAMPTZ;
    END IF;

    -- Deliverable & Escrow Payout Columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'delivered_at') THEN
        ALTER TABLE projects ADD COLUMN delivered_at TIMESTAMPTZ;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'dispute_case_id') THEN
        ALTER TABLE projects ADD COLUMN dispute_case_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'dispute_reason') THEN
        ALTER TABLE projects ADD COLUMN dispute_reason TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'payout_type') THEN
        ALTER TABLE projects ADD COLUMN payout_type TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'student_payout_amount') THEN
        ALTER TABLE projects ADD COLUMN student_payout_amount NUMERIC(12,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'company_refund_amount') THEN
        ALTER TABLE projects ADD COLUMN company_refund_amount NUMERIC(12,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'platform_commission_amount') THEN
        ALTER TABLE projects ADD COLUMN platform_commission_amount NUMERIC(12,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'payout_transaction_id') THEN
        ALTER TABLE projects ADD COLUMN payout_transaction_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'payout_receipt_url') THEN
        ALTER TABLE projects ADD COLUMN payout_receipt_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'completed_at') THEN
        ALTER TABLE projects ADD COLUMN completed_at TIMESTAMPTZ;
    END IF;
END $$;

-- 2. Ensure applications table has corresponding sync columns for instant student reflection
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'applications' AND column_name = 'payout_transaction_id') THEN
        ALTER TABLE applications ADD COLUMN payout_transaction_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'applications' AND column_name = 'payout_receipt_url') THEN
        ALTER TABLE applications ADD COLUMN payout_receipt_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'applications' AND column_name = 'payment_method') THEN
        ALTER TABLE applications ADD COLUMN payment_method TEXT DEFAULT 'JazzCash Merchant';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'applications' AND column_name = 'account_number') THEN
        ALTER TABLE applications ADD COLUMN account_number TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'applications' AND column_name = 'account_title') THEN
        ALTER TABLE applications ADD COLUMN account_title TEXT;
    END IF;
END $$;

-- 3. Create admin_notifications table if not exists
CREATE TABLE IF NOT EXISTS admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id TEXT,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL, -- 'payout_ready', 'revision_requested', 'dispute_raised', 'company_approval', 'payout_completed'
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and permissive policy for admin notifications
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'admin_notifications' 
        AND policyname = 'allow_authenticated_all_admin_notifications'
    ) THEN
        CREATE POLICY allow_authenticated_all_admin_notifications 
        ON admin_notifications 
        FOR ALL 
        TO authenticated 
        USING (true) 
        WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'admin_notifications' 
        AND policyname = 'allow_anon_select_admin_notifications'
    ) THEN
        CREATE POLICY allow_anon_select_admin_notifications 
        ON admin_notifications 
        FOR SELECT 
        TO anon 
        USING (true);
    END IF;
END $$;

-- 4. Create payment_receipts Storage Bucket for transfer screenshots
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment_receipts', 'payment_receipts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage policies for payment_receipts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND policyname = 'allow_public_read_payment_receipts'
    ) THEN
        CREATE POLICY allow_public_read_payment_receipts 
        ON storage.objects 
        FOR SELECT 
        TO public 
        USING (bucket_id = 'payment_receipts');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND policyname = 'allow_authenticated_insert_payment_receipts'
    ) THEN
        CREATE POLICY allow_authenticated_insert_payment_receipts 
        ON storage.objects 
        FOR INSERT 
        TO authenticated 
        WITH CHECK (bucket_id = 'payment_receipts');
    END IF;
END $$;

-- 5. Helper Stored Procedure: admin_approve_project_payment
CREATE OR REPLACE FUNCTION admin_approve_project_payment(
    p_project_id TEXT,
    p_admin_notes TEXT DEFAULT 'Approved by Administrator'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE projects
    SET 
        status = 'Open',
        is_escrow_verified = true,
        payment_sent = true,
        verified_at = NOW(),
        rejection_reason = NULL,
        updated_at = NOW()
    WHERE id = p_project_id::UUID;

    RETURN jsonb_build_object('success', true, 'message', 'Project approved and published');
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- 6. Helper Stored Procedure: admin_reject_project_payment
CREATE OR REPLACE FUNCTION admin_reject_project_payment(
    p_project_id TEXT,
    p_rejection_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE projects
    SET 
        status = 'payment_rejected',
        is_escrow_verified = false,
        payment_sent = false,
        rejection_reason = p_rejection_reason,
        updated_at = NOW()
    WHERE id = p_project_id::UUID;

    RETURN jsonb_build_object('success', true, 'message', 'Payment proof rejected');
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

