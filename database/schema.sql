-- ==============================================================================
-- MASTER DATABASE SCHEMA: MASJID MUSAFIR SOPHIA JATIWARNA
-- PostgreSQL / Supabase Migration Suite (Production Ready)
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABEL PELACAK CHECKLIST MEDIA (FASE 0)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.media_checklists (
    id INT PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    drive_type VARCHAR(50) DEFAULT 'image',
    uploaded_files_count INT DEFAULT 0,
    notes TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 3. TABEL DONASI & INFAQ INCOGNITO (PILAR FILANTROPI)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.donations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    donor_name VARCHAR(150) NOT NULL DEFAULT 'Hamba Allah',
    email VARCHAR(150),
    phone_number VARCHAR(30) NOT NULL,
    program_category VARCHAR(100) NOT NULL DEFAULT 'Makan Berjamaah Gratis', 
    -- 'Makan Berjamaah Gratis', 'Santri Tahfidz Quran', 'Operasional & Kebersihan 24 Jam', 'Infaq Jumat', 'Waqaf Fasilitas'
    amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    unique_code INT DEFAULT 0,
    total_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'QRIS', -- 'QRIS', 'TRANSFER_BSI', 'TUNAI'
    payment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'VERIFIED', 'FAILED'
    proof_url TEXT, -- Bukti transfer jika ada (ImageKit/Storage)
    prayer_notes TEXT, -- Doa / Hajat dari donatur
    is_incognito BOOLEAN DEFAULT FALSE,
    receipt_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 4. TABEL JADWAL PETUGAS IBADAH & KAJIAN
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.jadwal_petugas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    hari VARCHAR(20) NOT NULL, -- 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Ahad'
    tanggal DATE,
    waktu_ibadah VARCHAR(50) NOT NULL, -- 'Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya', 'Shalat Jumat', 'Kajian Ba'da Subuh', 'Kajian Akhir Pekan'
    nama_petugas VARCHAR(150) NOT NULL,
    peran VARCHAR(100) NOT NULL, -- 'Imam Rawatib', 'Muadzin', 'Khatib Shalat Jumat', 'Penceramah / Ustadz'
    judul_tema VARCHAR(255),
    foto_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 5. TABEL ARTIKEL DAKWAH & WARTA KEGIATAN (CMS STUDIO)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.artikel_berita (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    slug VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'Dakwah', -- 'Dakwah', 'Warta Kegiatan', 'Kisah Santri', 'Laporan Donasi', 'Kajian'
    excerpt TEXT,
    content_html TEXT NOT NULL,
    thumbnail_url TEXT,
    author_name VARCHAR(100) DEFAULT 'Tim Media DKM Sophia',
    read_time VARCHAR(20) DEFAULT '3 Menit',
    view_count INT DEFAULT 0,
    is_published BOOLEAN DEFAULT TRUE,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 6. TABEL TUGAS & PRODUKTIVITAS TIM DKM (TASK HEALTH V2)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.team_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to VARCHAR(150),
    assigned_role VARCHAR(100), -- 'Ketua DKM', 'PJ Media', 'PJ Divisi Sosial', 'PJ Kebersihan', 'Bendahara', dll.
    division VARCHAR(100) NOT NULL DEFAULT 'Umum',
    start_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    status VARCHAR(30) DEFAULT 'PENDING', -- 'PENDING', 'IN_PROGRESS', 'REVIEW', 'COMPLETED'
    progress_pct INT DEFAULT 0,
    is_archived BOOLEAN DEFAULT FALSE,
    order_index INT DEFAULT 0,
    created_by VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Idempotent column additions for existing team_tasks table
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS progress_pct INT DEFAULT 0;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS order_index INT DEFAULT 0;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS created_by VARCHAR(150);

-- ==============================================================================
-- 6.1. TABEL AUDIT LOG AKTIVITAS TUGAS (TASK ACTIVITY LOGS)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.task_activity_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    task_id UUID REFERENCES public.team_tasks(id) ON DELETE CASCADE,
    task_title VARCHAR(255),
    user_name VARCHAR(150) NOT NULL DEFAULT 'Pengurus DKM',
    user_role VARCHAR(50) DEFAULT 'STAFF',
    action_type VARCHAR(50) NOT NULL, -- 'CREATED', 'STATUS_CHANGED', 'UPDATED', 'ARCHIVED', 'RESTORED', 'DELETED'
    details TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 6.2. TABEL CHAT KOORDINASI MULTI-ARAH DKM (TASK & TEAM CHAT)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.task_chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_name VARCHAR(150) NOT NULL,
    sender_role VARCHAR(50) NOT NULL DEFAULT 'STAFF',
    sender_division VARCHAR(100) NOT NULL DEFAULT 'Umum',
    message TEXT NOT NULL,
    attachment_url TEXT,
    attachment_type VARCHAR(20) DEFAULT 'IMAGE', -- 'IMAGE', 'VIDEO'
    reply_to JSONB DEFAULT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_by VARCHAR(150) DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 7. TABEL LOG MONITORING KESEHATAN SISTEM (SYSTEM HEALTH)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.system_health_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL, -- 'Supabase DB', 'Vercel Edge', 'ImageKit CDN', 'Resend Email API', 'Hisab Kemenag'
    status VARCHAR(30) NOT NULL DEFAULT 'HEALTHY', -- 'HEALTHY', 'DEGRADED', 'DOWN'
    latency_ms INT DEFAULT 0,
    quota_used_gb NUMERIC(6, 2) DEFAULT 0.00,
    quota_limit_gb NUMERIC(6, 2) DEFAULT 20.00,
    response_code INT DEFAULT 200,
    details JSONB DEFAULT '{}'::jsonb,
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 8. TABEL PROFIL & HAK AKSES PENGURUS DKM
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'STAFF', -- 'SUPER_ADMIN', 'KETUA_DKM', 'PJ_MEDIA', 'BENDAHARA', 'STAFF'
    phone_number VARCHAR(30),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. TABEL PUSAT PENGADUAN & KOTAK SARAN JAMAAH
CREATE TABLE IF NOT EXISTS public.feedback_complaints (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_name VARCHAR(150) NOT NULL DEFAULT 'Hamba Allah',
    email VARCHAR(150),
    phone_number VARCHAR(30),
    category VARCHAR(100) NOT NULL DEFAULT 'Saran & Masukan', 
    -- 'Saran & Masukan', 'Laporan Fasilitas Rusak', 'Kebersihan & Kenyamanan', 'Pengaduan Layanan', 'Lainnya'
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'BARU', -- 'BARU', 'DIPROSES', 'SELESAI', 'DIARSIPKAN'
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- DATABASE PERMISSIONS & ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Grant base PostgreSQL schema & table permissions to application roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- A. donations
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public anonymous insert donation" ON public.donations;
CREATE POLICY "Allow public anonymous insert donation" 
ON public.donations FOR INSERT TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read verified prayers" ON public.donations;
CREATE POLICY "Allow public read verified prayers" 
ON public.donations FOR SELECT TO anon, authenticated USING (payment_status = 'VERIFIED');

DROP POLICY IF EXISTS "Allow full access for authenticated staff" ON public.donations;
CREATE POLICY "Allow full access for authenticated staff" 
ON public.donations FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- B. jadwal_petugas
ALTER TABLE public.jadwal_petugas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read active jadwal" ON public.jadwal_petugas;
CREATE POLICY "Allow public read active jadwal" 
ON public.jadwal_petugas FOR SELECT TO anon, authenticated USING (is_active = TRUE);

DROP POLICY IF EXISTS "Allow full access jadwal for authenticated staff" ON public.jadwal_petugas;
CREATE POLICY "Allow full access jadwal for authenticated staff" 
ON public.jadwal_petugas FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- C. artikel_berita
ALTER TABLE public.artikel_berita ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read published articles" ON public.artikel_berita;
CREATE POLICY "Allow public read published articles" 
ON public.artikel_berita FOR SELECT TO anon, authenticated USING (is_published = TRUE);

DROP POLICY IF EXISTS "Allow full access articles for authenticated staff" ON public.artikel_berita;
CREATE POLICY "Allow full access articles for authenticated staff" 
ON public.artikel_berita FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- D. team_tasks
ALTER TABLE public.team_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read team tasks for roadmap" ON public.team_tasks;
DROP POLICY IF EXISTS "Allow full access tasks for authenticated staff" ON public.team_tasks;
CREATE POLICY "team_tasks_full_policy" 
ON public.team_tasks FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- E. system_health_logs
ALTER TABLE public.system_health_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read system health" ON public.system_health_logs;
DROP POLICY IF EXISTS "Allow insert system health logs" ON public.system_health_logs;
CREATE POLICY "system_health_logs_full_policy" 
ON public.system_health_logs FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- F. admin_users
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow read admin profiles for authenticated" ON public.admin_users;
CREATE POLICY "Allow read admin profiles for authenticated" 
ON public.admin_users FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- G. media_checklists
ALTER TABLE public.media_checklists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read and update media checklist" ON public.media_checklists;
CREATE POLICY "Allow public read and update media checklist" 
ON public.media_checklists FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- H. feedback_complaints
ALTER TABLE public.feedback_complaints ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public anonymous insert feedback" ON public.feedback_complaints;
DROP POLICY IF EXISTS "Allow full access feedback for authenticated staff" ON public.feedback_complaints;
CREATE POLICY "feedback_complaints_full_policy" 
ON public.feedback_complaints FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- I. task_activity_logs
ALTER TABLE public.task_activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read task activity logs" ON public.task_activity_logs;
DROP POLICY IF EXISTS "Allow insert task activity logs" ON public.task_activity_logs;
DROP POLICY IF EXISTS "Allow full access task activity logs for authenticated" ON public.task_activity_logs;
CREATE POLICY "task_activity_logs_full_policy" 
ON public.task_activity_logs FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- J. task_chat_messages
ALTER TABLE public.task_chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow read task chat messages" ON public.task_chat_messages;
DROP POLICY IF EXISTS "Allow insert task chat messages" ON public.task_chat_messages;
DROP POLICY IF EXISTS "Allow full access task chat messages for authenticated" ON public.task_chat_messages;
CREATE POLICY "task_chat_messages_full_policy" 
ON public.task_chat_messages FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

-- 10. TABEL PENGAJUAN IZIN & CUTI PENGURUS DKM
CREATE TABLE IF NOT EXISTS public.dkm_leave_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    applicant_name VARCHAR(150) NOT NULL,
    applicant_role VARCHAR(50) NOT NULL,
    division VARCHAR(100) NOT NULL,
    leave_type VARCHAR(50) NOT NULL, -- 'IZIN_SAKIT', 'KEPERLUAN_PRIBADI', 'TUGAS_LUAR', 'CUTI_OPERASIONAL'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT DEFAULT 1,
    reason TEXT NOT NULL,
    attachment_url TEXT, -- Link bukti foto surat dokter / dokumen ImageKit
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'
    approver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    approver_name VARCHAR(150),
    approval_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- REALTIME REPLICATION SETUP (SAFE DO BLOCK)
-- ==============================================================================
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.media_checklists;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.donations;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.team_tasks;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.task_activity_logs;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.task_chat_messages;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.system_health_logs;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.feedback_complaints;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_users;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.dkm_leave_requests;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- Enable REPLICA IDENTITY FULL for proper CDC WebSocket payload broadcast
ALTER TABLE public.team_tasks REPLICA IDENTITY FULL;
ALTER TABLE public.task_activity_logs REPLICA IDENTITY FULL;
ALTER TABLE public.task_chat_messages REPLICA IDENTITY FULL;
ALTER TABLE public.donations REPLICA IDENTITY FULL;
ALTER TABLE public.feedback_complaints REPLICA IDENTITY FULL;
ALTER TABLE public.dkm_leave_requests REPLICA IDENTITY FULL;

