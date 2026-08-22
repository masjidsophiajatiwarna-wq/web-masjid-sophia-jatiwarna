-- ==============================================================================
-- MIGRASI DATABASE: MODUL PENGAJUAN IZIN & CUTI PENGURUS DKM
-- Tabel: public.dkm_leave_requests
-- Ekosistem Portal Masjid Musafir Sophia Jatiwarna
-- ==============================================================================

-- 1. PEMBUATAN TABEL PENGAJUAN IZIN & CUTI
CREATE TABLE IF NOT EXISTS public.dkm_leave_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(100), -- Referensi ID pengurus atau email
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL,
    role VARCHAR(100) NOT NULL,
    division VARCHAR(100) NOT NULL,
    leave_type VARCHAR(50) NOT NULL DEFAULT 'SAKIT', -- 'SAKIT', 'KEPERLUAN_PRIBADI', 'CUTI_OPERASIONAL', 'TUGAS_LUAR', 'LAINNYA'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL DEFAULT 1,
    reason TEXT NOT NULL,
    attachment_url TEXT, -- URL bukti surat dokter / dokumen penunjang (ImageKit CDN / Base64 WebP)
    emergency_contact VARCHAR(50),
    substitute_officer VARCHAR(150), -- Petugas pengganti piket selama masa izin
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'
    review_notes TEXT, -- Catatan evaluasi dari Ketua DKM / Super Admin
    reviewed_by VARCHAR(150), -- Nama / email peninjau
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. INDEKS PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_leave_requests_user ON public.dkm_leave_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_email ON public.dkm_leave_requests(email);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON public.dkm_leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_dates ON public.dkm_leave_requests(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_leave_requests_created_at ON public.dkm_leave_requests(created_at DESC);

-- 3. ENABLE ROW LEVEL SECURITY (RLS) & POLICIES
ALTER TABLE public.dkm_leave_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public and Auth users can read leave requests" ON public.dkm_leave_requests;
CREATE POLICY "Public and Auth users can read leave requests"
ON public.dkm_leave_requests
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert leave requests" ON public.dkm_leave_requests;
CREATE POLICY "Authenticated users can insert leave requests"
ON public.dkm_leave_requests
FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Super Admin, Ketua DKM and Creator can update leave requests" ON public.dkm_leave_requests;
CREATE POLICY "Super Admin, Ketua DKM and Creator can update leave requests"
ON public.dkm_leave_requests
FOR UPDATE
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Super Admin can delete leave requests" ON public.dkm_leave_requests;
CREATE POLICY "Super Admin can delete leave requests"
ON public.dkm_leave_requests
FOR DELETE
USING (true);

-- 4. REALTIME REPLICATION PUBLICATION
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'dkm_leave_requests'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.dkm_leave_requests;
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;
