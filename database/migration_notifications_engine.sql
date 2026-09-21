-- ==============================================================================
-- MIGRASI DATABASE: NOTIFICATION CENTER & REALTIME DEEP-LINKING ENGINE
-- Ekosistem Masjid Musafir Sophia Jatiwarna (Admin Dashboard Suite)
-- Versi: 1.0 (2026-09-21)
-- ==============================================================================

-- 1. PEMBUATAN TABEL NOTIFIKASI APLIKASI
CREATE TABLE IF NOT EXISTS public.app_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    recipient_role VARCHAR(50), -- 'SUPER_ADMIN', 'KETUA_DKM', 'PJ_KEUANGAN', 'ALL', dll.
    recipient_email VARCHAR(150), -- Email spesifik penerima jika ada, atau NULL jika berbasis role
    category VARCHAR(50) NOT NULL, -- 'BUDGET', 'TASK', 'CHAT', 'FEEDBACK', 'SYSTEM'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    target_tab VARCHAR(50) NOT NULL, -- 'tab-finance', 'tab-tasks', 'tab-feedback', dll.
    target_subview VARCHAR(50), -- 'budget', 'jurnal', dll.
    reference_id VARCHAR(100), -- ID dari transaksi/tugas/pesan yang bersangkutan
    is_read BOOLEAN DEFAULT FALSE,
    created_by_name VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. INDEKS PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_app_notifications_recipient_role ON public.app_notifications(recipient_role);
CREATE INDEX IF NOT EXISTS idx_app_notifications_recipient_email ON public.app_notifications(recipient_email);
CREATE INDEX IF NOT EXISTS idx_app_notifications_is_read ON public.app_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_app_notifications_created_at ON public.app_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_notifications_reference_id ON public.app_notifications(reference_id);

-- 3. HAK AKSES & KEAMANAN ROW LEVEL SECURITY (RLS)
ALTER TABLE public.app_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access on app_notifications" ON public.app_notifications;
CREATE POLICY "Public Read Access on app_notifications" ON public.app_notifications
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Insert Access on app_notifications" ON public.app_notifications;
CREATE POLICY "Public Insert Access on app_notifications" ON public.app_notifications
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public Update Access on app_notifications" ON public.app_notifications;
CREATE POLICY "Public Update Access on app_notifications" ON public.app_notifications
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public Delete Access on app_notifications" ON public.app_notifications;
CREATE POLICY "Public Delete Access on app_notifications" ON public.app_notifications
    FOR DELETE USING (true);

-- 4. INTEGRASI SUPABASE REALTIME CDC WEBSOCKET
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'app_notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.app_notifications;
    END IF;
END $$;

-- 5. FUNGSI & TRIGGER AUTO-PURGE (MAKSIMAL 50 NOTIFIKASI & RETENSI 7 HARI)
-- Menjaga kuota Supabase free tier tetap hemat, efisien, dan bersih otomatis
CREATE OR REPLACE FUNCTION public.purge_old_notifications()
RETURNS TRIGGER AS $$
BEGIN
    -- Hapus notifikasi yang telah melampaui masa simpan 7 hari
    DELETE FROM public.app_notifications
    WHERE created_at < (NOW() - INTERVAL '7 days');

    -- Jika total notifikasi melebihi 50 baris, hapus notifikasi tertua (FIFO)
    DELETE FROM public.app_notifications
    WHERE id NOT IN (
        SELECT id FROM public.app_notifications
        ORDER BY created_at DESC
        LIMIT 50
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_purge_notifications ON public.app_notifications;
CREATE TRIGGER trg_auto_purge_notifications
    AFTER INSERT ON public.app_notifications
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.purge_old_notifications();

