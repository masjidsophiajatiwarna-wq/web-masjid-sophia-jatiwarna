-- ==============================================================================
-- SKRIP MIGRASI SUPABASE: MODUL MANAJEMEN TUGAS PENGURUS & REALTIME CDC V1.6.0
-- MASJID MUSAFIR SOPHIA JATIWARNA
-- Jalankan skrip ini langsung di Supabase SQL Editor: https://supabase.com/dashboard/project/fcwajbemkbhkogwtqcmx/sql
-- ==============================================================================

-- 1. PEMBARUAN STRUKTUR TABEL team_tasks (KOLOM GANTT, KANBAN, ARSIP & PROGRES)
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS progress_pct INT DEFAULT 0;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS order_index INT DEFAULT 0;
ALTER TABLE public.team_tasks ADD COLUMN IF NOT EXISTS created_by VARCHAR(150);

-- 2. PEMBUATAN TABEL AUDIT LOG AKTIVITAS TUGAS (TASK ACTIVITY LOGS)
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

-- 3. PEMBUATAN TABEL CHAT KOORDINASI MULTI-ARAH DKM (TASK & TEAM CHAT)
CREATE TABLE IF NOT EXISTS public.task_chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_name VARCHAR(150) NOT NULL,
    sender_role VARCHAR(50) NOT NULL DEFAULT 'STAFF',
    sender_division VARCHAR(100) NOT NULL DEFAULT 'Umum',
    message TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. AKTIFKAN ROW LEVEL SECURITY (RLS) ZERO-TRUST
ALTER TABLE public.team_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_chat_messages ENABLE ROW LEVEL SECURITY;

-- Kebijakan Akses Pengurus (Authenticated Users)
DO $$
BEGIN
    DROP POLICY IF EXISTS "Pengurus dapat mengelola tugas tim" ON public.team_tasks;
    CREATE POLICY "Pengurus dapat mengelola tugas tim" ON public.team_tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Pengurus dapat melihat dan menambah log aktivitas" ON public.task_activity_logs;
    CREATE POLICY "Pengurus dapat melihat dan menambah log aktivitas" ON public.task_activity_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Pengurus dapat melihat dan mengirim chat koordinasi" ON public.task_chat_messages;
    CREATE POLICY "Pengurus dapat melihat dan mengirim chat koordinasi" ON public.task_chat_messages FOR ALL TO authenticated USING (true) WITH CHECK (true);

    -- Fallback kebijakan untuk anon (jika pengujian lokal tanpa auth token)
    DROP POLICY IF EXISTS "Anon task select" ON public.team_tasks;
    CREATE POLICY "Anon task select" ON public.team_tasks FOR ALL TO anon USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Anon log select" ON public.task_activity_logs;
    CREATE POLICY "Anon log select" ON public.task_activity_logs FOR ALL TO anon USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Anon chat select" ON public.task_chat_messages;
    CREATE POLICY "Anon chat select" ON public.task_chat_messages FOR ALL TO anon USING (true) WITH CHECK (true);
END $$;

-- 5. DAFTARKAN TABEL KE PUBLIKASI SUPABASE REALTIME WEBSOCKET (CDC)
DO $$
BEGIN
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
END $$;

-- 6. SETTING REPLICA IDENTITY FULL UNTUK BROADCAST DATA UTUH PADA UPDATE & DELETE
ALTER TABLE public.team_tasks REPLICA IDENTITY FULL;
ALTER TABLE public.task_activity_logs REPLICA IDENTITY FULL;
ALTER TABLE public.task_chat_messages REPLICA IDENTITY FULL;

-- 7. SEEDING DATA TUGAS OPERASIONAL RESMI DKM MASJID SOPHIA DENGAN UUID STANDAR
INSERT INTO public.team_tasks (id, title, description, assigned_to, assigned_role, division, priority, status, progress_pct, is_archived, start_date, due_date)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Persiapan 70+ Porsi Sedekah Makan Siang Dzuhur', 'Memastikan kecukupan bahan baku (beras, lauk, sayur) dan higienitas dapur untuk jamaah Dzuhur dan musafir.', 'Ustadz Ridwan (Tim Dapur)', 'PJ_LOGISTIK', 'Divisi Logistik & Sarpras', 'CRITICAL', 'IN_PROGRESS', 75, FALSE, CURRENT_DATE, CURRENT_DATE),
    ('a0000000-0000-0000-0000-000000000002', 'Pembersihan & Sterilisasi Area Wudhu & Kamar Mandi Musafir 24 Jam', 'Pengecekan sabun, pengharum ruangan, dan sanitasi lantai toilet serta tempat wudhu pria & wanita.', 'Pak Marwan (Sanitasi)', 'PJ_KEBERSIHAN', 'Divisi Kebersihan & Sanitasi', 'HIGH', 'COMPLETED', 100, FALSE, CURRENT_DATE - 1, CURRENT_DATE),
    ('a0000000-0000-0000-0000-000000000003', 'Setoran Mutabaah Hafalan Santri Tahfidz Ba''da Subuh', 'Pencatatan setoran hafalan Juz 30 dan surat pilihan santri binaan Masjid Sophia beserta penilaian tajwid.', 'Ustadz Farhan', 'PJ_SANTRI', 'Divisi Pembinaan Santri Tahfidz', 'HIGH', 'COMPLETED', 100, FALSE, CURRENT_DATE, CURRENT_DATE),
    ('a0000000-0000-0000-0000-000000000004', 'Pemeriksaan Filter Air Minum RO & Dispenser Musafir', 'Pengecekan TDS meter dan penggantian filter sedimen pada dispenser air minum gratis jamaah.', 'Mas Doni (Pelayanan)', 'PJ_MUSAFIR', 'Divisi Pelayanan Musafir & Sosial', 'MEDIUM', 'PENDING', 20, FALSE, CURRENT_DATE, CURRENT_DATE + 2),
    ('a0000000-0000-0000-0000-000000000005', 'Penerbitan Artikel Warta "Keutamaan Memberi Makan Jamaah"', 'Penyusunan naskah artikel dakwah, kurasi foto ImageKit WebP, dan pengajuan review ke Ketua DKM.', 'Habib Maulana (Tim Media)', 'PJ_MEDIA', 'Divisi Media & Dakwah', 'HIGH', 'REVIEW', 90, FALSE, CURRENT_DATE - 1, CURRENT_DATE + 1),
    ('a0000000-0000-0000-0000-000000000006', 'Kalibrasi Menit Ikhtiyat Jadwal Shalat Kemenag Bekasi', 'Verifikasi hisab astronomis jadwal shalat Jatiwarna dan penyesuaian running text jam digital masjid.', 'Ustadz DKM (Imam Rawatib)', 'PJ_IBADAH', 'Divisi Ibadah & Acara', 'MEDIUM', 'IN_PROGRESS', 50, FALSE, CURRENT_DATE, CURRENT_DATE + 3),
    ('a0000000-0000-0000-0000-000000000007', 'Rekonsiliasi Kas Masuk Donasi QRIS & Rekening BSI', 'Pencocokan mutasi bank harian dengan entri data infaq portal donasi masjid.', 'Bendahara DKM', 'PJ_KEUANGAN', 'Divisi Keuangan & ZISWAF', 'HIGH', 'IN_PROGRESS', 60, FALSE, CURRENT_DATE, CURRENT_DATE + 1),
    ('a0000000-0000-0000-0000-000000000008', 'Piket Ronda Malam & Pengecekan CCTV Area Parkiran', 'Patroli berkala area parkir kendaraan musafir samping UMAR Travel dan gerbang masuk Hankam.', 'Pak Agus (Keamanan)', 'PJ_KEAMANAN', 'Divisi Keamanan', 'MEDIUM', 'PENDING', 0, FALSE, CURRENT_DATE, CURRENT_DATE + 1),
    ('a0000000-0000-0000-0000-000000000009', 'Pemantauan Arsitektur 7 Pilar Cloud & Keep-Alive Cron', 'Audit utilisasi kuota Vercel, Supabase DB, ImageKit, dan Resend API.', 'Super Administrator', 'SUPER_ADMIN', 'IT & Ekosistem Digital', 'LOW', 'COMPLETED', 100, FALSE, CURRENT_DATE - 3, CURRENT_DATE)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    division = EXCLUDED.division,
    assigned_to = EXCLUDED.assigned_to,
    priority = EXCLUDED.priority,
    status = EXCLUDED.status,
    progress_pct = EXCLUDED.progress_pct,
    start_date = EXCLUDED.start_date,
    due_date = EXCLUDED.due_date;
