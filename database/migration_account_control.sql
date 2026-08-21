-- ==============================================================================
-- MIGRASI MANDIRI: MODUL ACCOUNT & ACCESS CONTROL MASJID SOPHIA JATIWARNA
-- Menambahkan kolom permissions, avatar_url, session_version pada public.admin_users
-- ==============================================================================

-- 1. Tambahkan kolom avatar_url, permissions JSONB, session_version, dan updated_at
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS session_version INT DEFAULT 1;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Berikan default permissions JSONB untuk 11 akun yang sudah terdaftar
UPDATE public.admin_users 
SET permissions = jsonb_build_object(
    'tasks', 'WRITE',
    'chat', 'WRITE',
    'donations', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_KEUANGAN') THEN 'WRITE' ELSE 'NONE' END,
    'articles', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_MEDIA', 'PJ_IBADAH') THEN 'WRITE' ELSE 'NONE' END,
    'homepage', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_MEDIA') THEN 'WRITE' ELSE 'NONE' END,
    'logistics', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_LOGISTIK') THEN 'WRITE' ELSE 'NONE' END,
    'santri', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_SANTRI') THEN 'WRITE' ELSE 'NONE' END,
    'musafir', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_MUSAFIR') THEN 'WRITE' ELSE 'NONE' END,
    'prayer_schedule', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_IBADAH') THEN 'WRITE' ELSE 'NONE' END,
    'finance', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_KEUANGAN') THEN 'WRITE' ELSE 'REQUEST' END,
    'security', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_KEAMANAN') THEN 'WRITE' ELSE 'NONE' END,
    'cleaning', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM', 'PJ_KEBERSIHAN') THEN 'WRITE' ELSE 'NONE' END,
    'leave', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM') THEN 'WRITE' ELSE 'REQUEST' END,
    'accounts', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER', 'KETUA_DKM') THEN 'WRITE' ELSE 'NONE' END,
    'cloud_monitor', CASE WHEN role IN ('SUPER_ADMIN', 'SUPER_USER') THEN 'WRITE' WHEN role = 'KETUA_DKM' THEN 'READ' ELSE 'NONE' END
)
WHERE permissions IS NULL OR permissions = '{}'::jsonb;

-- 3. Fungsi Helper untuk Superadmin Force End Session (Paksa Logout)
CREATE OR REPLACE FUNCTION public.force_end_user_session(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.admin_users
    SET session_version = COALESCE(session_version, 1) + 1,
        updated_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Pastikan tabel admin_users masuk ke Realtime WebSocket CDC
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_users;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

SELECT 'Migrasi Account Control berhasil! Kolom avatar_url, permissions, dan session_version sudah aktif.' AS status;
