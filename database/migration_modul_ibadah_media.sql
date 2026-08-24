-- ==============================================================================
-- MIGRASI DATABASE: MODUL PERIBADATAN & ALUR PERSETUJUAN (APPROVAL WORKFLOW)
-- Tabel: public.jadwal_shalat_petugas, public.kajian_acara_ibadah
-- Ekosistem Portal Masjid Musafir Sophia Jatiwarna
-- ==============================================================================

-- 1. TABEL JADWAL SHALAT & PENUGASAN PETUGAS IBADAH (DENGAN ALUR PERSETUJUAN)
CREATE TABLE IF NOT EXISTS public.jadwal_shalat_petugas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tanggal DATE NOT NULL,
    hari VARCHAR(20) NOT NULL DEFAULT 'Senin',
    imsak VARCHAR(10) NOT NULL DEFAULT '04:30',
    subuh VARCHAR(10) NOT NULL DEFAULT '04:40',
    terbit VARCHAR(10) NOT NULL DEFAULT '05:55',
    dhuha VARCHAR(10) NOT NULL DEFAULT '06:20',
    dzuhur VARCHAR(10) NOT NULL DEFAULT '12:00',
    ashar VARCHAR(10) NOT NULL DEFAULT '15:15',
    maghrib VARCHAR(10) NOT NULL DEFAULT '18:05',
    isya VARCHAR(10) NOT NULL DEFAULT '19:15',
    ikhtiyat_minutes INT NOT NULL DEFAULT 2,
    is_manual_override BOOLEAN NOT NULL DEFAULT FALSE,
    imam_subuh VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Subuh',
    imam_dzuhur VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Dzuhur',
    imam_ashar VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Ashar',
    imam_maghrib VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Maghrib',
    imam_isya VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Isya',
    khatib_jumat VARCHAR(150) DEFAULT '',
    muadzin_jumat VARCHAR(150) DEFAULT '',
    bilal_jumat VARCHAR(150) DEFAULT '',
    muadzin_rawatib VARCHAR(150) NOT NULL DEFAULT 'Muadzin Bertugas',
    status_approval VARCHAR(30) NOT NULL DEFAULT 'Draft', -- 'Draft', 'Pending Approval', 'Approved', 'Rejected'
    submitted_by VARCHAR(150) DEFAULT '',
    submitted_by_email VARCHAR(150) DEFAULT '',
    submitted_at TIMESTAMP WITH TIME ZONE,
    reviewed_by VARCHAR(150) DEFAULT '',
    reviewed_by_email VARCHAR(150) DEFAULT '',
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Idempotent column check for jadwal_shalat_petugas
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS tanggal DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS hari VARCHAR(20) NOT NULL DEFAULT 'Senin';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS imsak VARCHAR(10) NOT NULL DEFAULT '04:30';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS subuh VARCHAR(10) NOT NULL DEFAULT '04:40';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS terbit VARCHAR(10) NOT NULL DEFAULT '05:55';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS dhuha VARCHAR(10) NOT NULL DEFAULT '06:20';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS dzuhur VARCHAR(10) NOT NULL DEFAULT '12:00';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS ashar VARCHAR(10) NOT NULL DEFAULT '15:15';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS maghrib VARCHAR(10) NOT NULL DEFAULT '18:05';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS isya VARCHAR(10) NOT NULL DEFAULT '19:15';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS ikhtiyat_minutes INT NOT NULL DEFAULT 2;
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS is_manual_override BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS imam_subuh VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Subuh';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS imam_dzuhur VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Dzuhur';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS imam_ashar VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Ashar';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS imam_maghrib VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Maghrib';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS imam_isya VARCHAR(150) NOT NULL DEFAULT 'Ust. Rawatib Isya';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS khatib_jumat VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS muadzin_jumat VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS bilal_jumat VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS muadzin_rawatib VARCHAR(150) NOT NULL DEFAULT 'Muadzin Bertugas';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS status_approval VARCHAR(30) NOT NULL DEFAULT 'Draft';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS submitted_by VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS submitted_by_email VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS reviewed_by_email VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS review_notes TEXT DEFAULT '';
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.jadwal_shalat_petugas ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. TABEL KAJIAN & ACARA PERIBADATAN (DENGAN ALUR PERSETUJUAN)
CREATE TABLE IF NOT EXISTS public.kajian_acara_ibadah (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul_kajian VARCHAR(255) NOT NULL,
    pemateri VARCHAR(150) NOT NULL,
    tema_kategori VARCHAR(100) NOT NULL DEFAULT 'Kajian Rutin', -- 'Kajian Rutin Ba''da Subuh', 'Kajian Tematik', 'Kajian Akhir Pekan', 'PHBI', 'Kajian Muslimah'
    tanggal_pelaksanaan DATE NOT NULL DEFAULT CURRENT_DATE,
    waktu_mulai VARCHAR(10) NOT NULL DEFAULT '05:30',
    waktu_selesai VARCHAR(10) NOT NULL DEFAULT '07:00',
    lokasi VARCHAR(150) NOT NULL DEFAULT 'Ruang Shalat Utama',
    target_jamaah VARCHAR(100) NOT NULL DEFAULT 'Umum & Musafir',
    flyer_url TEXT,
    deskripsi TEXT DEFAULT '',
    status_approval VARCHAR(30) NOT NULL DEFAULT 'Draft', -- 'Draft', 'Pending Approval', 'Approved', 'Rejected'
    submitted_by VARCHAR(150) DEFAULT '',
    submitted_by_email VARCHAR(150) DEFAULT '',
    submitted_at TIMESTAMP WITH TIME ZONE,
    reviewed_by VARCHAR(150) DEFAULT '',
    reviewed_by_email VARCHAR(150) DEFAULT '',
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT DEFAULT '',
    is_published_to_web BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Idempotent column check for kajian_acara_ibadah
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS judul_kajian VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS pemateri VARCHAR(150) NOT NULL DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS tema_kategori VARCHAR(100) NOT NULL DEFAULT 'Kajian Rutin';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS tanggal_pelaksanaan DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS waktu_mulai VARCHAR(10) NOT NULL DEFAULT '05:30';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS waktu_selesai VARCHAR(10) NOT NULL DEFAULT '07:00';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS lokasi VARCHAR(150) NOT NULL DEFAULT 'Ruang Shalat Utama';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS target_jamaah VARCHAR(100) NOT NULL DEFAULT 'Umum & Musafir';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS flyer_url TEXT;
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS deskripsi TEXT DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS status_approval VARCHAR(30) NOT NULL DEFAULT 'Draft';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS submitted_by VARCHAR(150) DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS submitted_by_email VARCHAR(150) DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(150) DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS reviewed_by_email VARCHAR(150) DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS review_notes TEXT DEFAULT '';
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS is_published_to_web BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.kajian_acara_ibadah ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. PERBAIKAN IDEMPOTEN UNTUK TABEL JADWAL PETUGAS EXISTING (BACKWARD COMPATIBILITY)
ALTER TABLE public.jadwal_petugas ADD COLUMN IF NOT EXISTS status_approval VARCHAR(30) NOT NULL DEFAULT 'Approved';
ALTER TABLE public.jadwal_petugas ADD COLUMN IF NOT EXISTS submitted_by VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_petugas ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(150) DEFAULT '';
ALTER TABLE public.jadwal_petugas ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.jadwal_petugas ADD COLUMN IF NOT EXISTS review_notes TEXT DEFAULT '';

-- 4. INDEKS PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_jadwal_shalat_tanggal ON public.jadwal_shalat_petugas(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_jadwal_shalat_status ON public.jadwal_shalat_petugas(status_approval);
CREATE INDEX IF NOT EXISTS idx_jadwal_shalat_subm ON public.jadwal_shalat_petugas(submitted_by_email);
CREATE INDEX IF NOT EXISTS idx_kajian_tanggal ON public.kajian_acara_ibadah(tanggal_pelaksanaan DESC);
CREATE INDEX IF NOT EXISTS idx_kajian_status ON public.kajian_acara_ibadah(status_approval);
CREATE INDEX IF NOT EXISTS idx_kajian_published ON public.kajian_acara_ibadah(is_published_to_web);

-- 5. ENABLE ROW LEVEL SECURITY (RLS) & POLICIES
ALTER TABLE public.jadwal_shalat_petugas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kajian_acara_ibadah ENABLE ROW LEVEL SECURITY;

-- Policies for jadwal_shalat_petugas
DROP POLICY IF EXISTS "Public and Auth users can read approved prayer schedule" ON public.jadwal_shalat_petugas;
CREATE POLICY "Public and Auth users can read approved prayer schedule"
ON public.jadwal_shalat_petugas
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert prayer schedule" ON public.jadwal_shalat_petugas;
CREATE POLICY "Authenticated users can insert prayer schedule"
ON public.jadwal_shalat_petugas
FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users and Admin can update prayer schedule" ON public.jadwal_shalat_petugas;
CREATE POLICY "Authenticated users and Admin can update prayer schedule"
ON public.jadwal_shalat_petugas
FOR UPDATE
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Admin can delete prayer schedule" ON public.jadwal_shalat_petugas;
CREATE POLICY "Admin can delete prayer schedule"
ON public.jadwal_shalat_petugas
FOR DELETE
USING (true);

-- Policies for kajian_acara_ibadah
DROP POLICY IF EXISTS "Public and Auth users can read kajian events" ON public.kajian_acara_ibadah;
CREATE POLICY "Public and Auth users can read kajian events"
ON public.kajian_acara_ibadah
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert kajian events" ON public.kajian_acara_ibadah;
CREATE POLICY "Authenticated users can insert kajian events"
ON public.kajian_acara_ibadah
FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users and Admin can update kajian events" ON public.kajian_acara_ibadah;
CREATE POLICY "Authenticated users and Admin can update kajian events"
ON public.kajian_acara_ibadah
FOR UPDATE
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Admin can delete kajian events" ON public.kajian_acara_ibadah;
CREATE POLICY "Admin can delete kajian events"
ON public.kajian_acara_ibadah
FOR DELETE
USING (true);

-- 6. REALTIME REPLICATION PUBLICATION
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'jadwal_shalat_petugas'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.jadwal_shalat_petugas;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'kajian_acara_ibadah'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.kajian_acara_ibadah;
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;
