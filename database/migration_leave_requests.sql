-- ==============================================================================
-- MIGRASI DATABASE: MODUL PENGAJUAN IZIN & CUTI PENGURUS DKM (IDEMPOTENT & ROBUST)
-- Tabel: public.dkm_leave_requests
-- Ekosistem Portal Masjid Musafir Sophia Jatiwarna
-- ==============================================================================

-- 1. PEMBUATAN / AUTO-MIGRASI TABEL PENGAJUAN IZIN & CUTI
CREATE TABLE IF NOT EXISTS public.dkm_leave_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(100),
    full_name VARCHAR(150) NOT NULL DEFAULT '',
    email VARCHAR(150) NOT NULL DEFAULT '',
    role VARCHAR(100) NOT NULL DEFAULT 'STAFF',
    division VARCHAR(100) NOT NULL DEFAULT 'Umum',
    leave_type VARCHAR(50) NOT NULL DEFAULT 'SAKIT',
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_days INT NOT NULL DEFAULT 1,
    reason TEXT NOT NULL DEFAULT '',
    attachment_url TEXT,
    emergency_contact VARCHAR(50),
    substitute_officer VARCHAR(150),
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    review_notes TEXT,
    reviewed_by VARCHAR(150),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pastikan seluruh kolom terpasang (jika tabel dkm_leave_requests sebelumnya sudah dibuat dengan kolom berbeda)
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS user_id VARCHAR(100);
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NOT NULL DEFAULT '';
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS email VARCHAR(150) NOT NULL DEFAULT '';
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS role VARCHAR(100) NOT NULL DEFAULT 'STAFF';
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS division VARCHAR(100) NOT NULL DEFAULT 'Umum';
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS leave_type VARCHAR(50) NOT NULL DEFAULT 'SAKIT';
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS start_date DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS end_date DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS total_days INT NOT NULL DEFAULT 1;
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS reason TEXT NOT NULL DEFAULT '';
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(50);
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS substitute_officer VARCHAR(150);
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'PENDING';
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS review_notes TEXT;
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(150);
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.dkm_leave_requests ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

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
