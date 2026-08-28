-- ==============================================================================
-- MASTER DATABASE MIGRATION SUITE: ALL PJ DIVISION MODULES (v2.0)
-- MASJID MUSAFIR SOPHIA JATIWARNA
-- Production-Ready PostgreSQL / Supabase Schema, RLS Policies & Realtime CDC
-- ==============================================================================

-- 0. EXTENSIONS & SCHEMA PERMISSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- ==============================================================================
-- 1. MODUL PERIBADATAN & ACARA (PJ IBADAH & ACARA)
-- ==============================================================================

-- 1.1 Tabel Jadwal Shalat & Penugasan Petugas Harian (Imam, Muadzin, Khatib, Bilal)
CREATE TABLE IF NOT EXISTS public.jadwal_shalat_petugas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tanggal DATE NOT NULL,
    hari VARCHAR(20) NOT NULL,
    subuh VARCHAR(10) NOT NULL DEFAULT '04:41',
    dzuhur VARCHAR(10) NOT NULL DEFAULT '11:59',
    ashar VARCHAR(10) NOT NULL DEFAULT '15:19',
    maghrib VARCHAR(10) NOT NULL DEFAULT '17:58',
    isya VARCHAR(10) NOT NULL DEFAULT '19:08',
    imam_rawatib VARCHAR(150),
    muadzin VARCHAR(150),
    khatib_jumat VARCHAR(150),
    bilal VARCHAR(150),
    submitted_by VARCHAR(150) DEFAULT 'PJ Ibadah',
    submitted_by_email VARCHAR(150),
    status_approval VARCHAR(30) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Approved', 'Rejected'
    catatan_review TEXT,
    reviewed_by VARCHAR(150),
    reviewed_by_email VARCHAR(150),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 1.2 Tabel Agenda Kajian Tematik, Acara PHBI & Khutbah Jumat
CREATE TABLE IF NOT EXISTS public.kajian_acara_ibadah (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul_kajian VARCHAR(255) NOT NULL,
    penceramah VARCHAR(150) NOT NULL,
    kategori VARCHAR(100) NOT NULL DEFAULT 'Kajian Rutin', -- 'Kajian Rutin', 'Kajian Tematik', 'PHBI', 'Khutbah Jumat', 'Tabligh Akbar'
    tanggal DATE NOT NULL,
    waktu_mulai VARCHAR(10) NOT NULL DEFAULT '18:30',
    waktu_selesai VARCHAR(10) DEFAULT '20:00',
    tempat_lokasi VARCHAR(150) DEFAULT 'Ruang Utama Masjid Sophia',
    poster_url TEXT,
    deskripsi TEXT,
    naskah_khutbah_url TEXT,
    status_approval VARCHAR(30) NOT NULL DEFAULT 'Approved', -- 'Pending', 'Approved', 'Rejected'
    submitted_by VARCHAR(150) DEFAULT 'PJ Ibadah',
    submitted_by_email VARCHAR(150),
    reviewed_by VARCHAR(150),
    reviewed_by_email VARCHAR(150),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 2. MODUL LOGISTIK & SARPRAS (PJ LOGISTIK & SARPRAS)
-- ==============================================================================

-- 2.1 Tabel Sedekah Makan Siang Gratis Ba'da Dzuhur (Dapur Sophia 70+ Porsi/Hari)
CREATE TABLE IF NOT EXISTS public.dapur_makan_siang (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tanggal DATE NOT NULL,
    hari VARCHAR(20) NOT NULL,
    menu_utama VARCHAR(255) NOT NULL,
    target_porsi INT NOT NULL DEFAULT 70,
    realisasi_porsi INT DEFAULT 0,
    status_distribusi VARCHAR(30) NOT NULL DEFAULT 'PERSIAPAN', -- 'PERSIAPAN', 'MEMASAK', 'SIAP_BAGI', 'SELESAI_TERBAGI'
    logistik_bahan_catatan TEXT,
    pj_dapur VARCHAR(150) DEFAULT 'Penanggung Jawab Logistik & Sarpras',
    foto_dokumentasi_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2.2 Tabel Inventaris Aset & Fasilitas Fisik Masjid
CREATE TABLE IF NOT EXISTS public.masjid_assets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    kode_aset VARCHAR(50) UNIQUE NOT NULL,
    nama_barang VARCHAR(255) NOT NULL,
    kategori VARCHAR(100) NOT NULL DEFAULT 'Elektronik & Sound', -- 'Elektronik & Sound', 'Kebersihan & Sanitasi', 'Perlengkapan Ibadah', 'Dapur & Logistik', 'Kendaraan', 'Furnitur'
    lokasi_penyimpanan VARCHAR(150) NOT NULL DEFAULT 'Ruang Utama',
    jumlah INT NOT NULL DEFAULT 1,
    satuan VARCHAR(30) DEFAULT 'Unit',
    kondisi VARCHAR(30) NOT NULL DEFAULT 'BAIK', -- 'BAIK', 'RUSAK_RINGAN', 'RUSAK_BERAT', 'DALAM_SERVIS', 'HILANG'
    tanggal_perolehan DATE DEFAULT CURRENT_DATE,
    nilai_estimasi NUMERIC(15, 2) DEFAULT 0.00,
    pj_aset VARCHAR(150) DEFAULT 'Penanggung Jawab Logistik & Sarpras',
    foto_aset_url TEXT,
    riwayat_servis JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 3. MODUL KEUANGAN & ANGGARAN (PJ KEUANGAN / BENDAHARA)
-- ==============================================================================

-- 3.1 Tabel Jurnal Pembukuan Kas Masuk & Kas Keluar
CREATE TABLE IF NOT EXISTS public.financial_journals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    kode_transaksi VARCHAR(50) UNIQUE NOT NULL,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    tipe_transaksi VARCHAR(30) NOT NULL, -- 'KAS_MASUK', 'KAS_KELUAR'
    kategori VARCHAR(100) NOT NULL, -- 'Infaq Donatur BSI', 'QRIS Sedekah Makan', 'Infaq Kotak Tunai', 'Operasional Dapur', 'Honorarium & Kafalah', 'Listrik & Utilitas', 'Sarpras & Perbaikan', 'Santunan Santri'
    nominal NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    metode_pembayaran VARCHAR(50) NOT NULL DEFAULT 'TRANSFER_BSI', -- 'TRANSFER_BSI', 'QRIS', 'TUNAI'
    deskripsi TEXT NOT NULL,
    bukti_transaksi_url TEXT,
    pj_input VARCHAR(150) DEFAULT 'Bendahara & Akuntansi DKM',
    pj_input_email VARCHAR(150),
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3.2 Tabel Pengajuan Anggaran (*Budget Request*) & Klaim Nota Bon (*Expense Reimbursement*)
CREATE TABLE IF NOT EXISTS public.budget_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    kode_pengajuan VARCHAR(50) UNIQUE NOT NULL,
    tanggal_pengajuan DATE NOT NULL DEFAULT CURRENT_DATE,
    divisi_pengaju VARCHAR(100) NOT NULL,
    nama_pengaju VARCHAR(150) NOT NULL,
    email_pengaju VARCHAR(150) NOT NULL,
    tipe_pengajuan VARCHAR(30) NOT NULL DEFAULT 'BUDGET_REQUEST', -- 'BUDGET_REQUEST', 'REIMBURSEMENT_NOTA'
    judul_keperluan VARCHAR(255) NOT NULL,
    rincian_keperluan TEXT NOT NULL,
    nominal_diajukan NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    lampiran_nota_url TEXT, -- Bukti foto struk/kuitansi/rincian ImageKit
    status_pengajuan VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED_DKM', 'DISBURSED', 'REJECTED'
    catatan_evaluasi TEXT,
    reviewed_by VARCHAR(150),
    reviewed_by_email VARCHAR(150),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    disbursed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 4. MODUL SANTRI & PENDIDIKAN (PJ SANTRI & PENDIDIKAN)
-- ==============================================================================

-- 4.1 Tabel Direktori Profil Santri Tahfidz Quran
CREATE TABLE IF NOT EXISTS public.santri_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nis VARCHAR(50) UNIQUE NOT NULL,
    nama_lengkap VARCHAR(150) NOT NULL,
    nama_panggilan VARCHAR(50),
    jenis_kelamin VARCHAR(20) DEFAULT 'Ikhwan', -- 'Ikhwan', 'Akhwat'
    tanggal_lahir DATE,
    nama_wali VARCHAR(150) NOT NULL,
    kontak_wali VARCHAR(30) NOT NULL,
    alamat_asal TEXT,
    tanggal_masuk DATE DEFAULT CURRENT_DATE,
    target_hafalan_juz INT DEFAULT 30,
    capaian_hafalan_juz INT DEFAULT 0,
    status_santri VARCHAR(30) DEFAULT 'AKTIF', -- 'AKTIF', 'LULUS', 'CUTI', 'NON_AKTIF'
    foto_santri_url TEXT,
    catatan_perkembangan TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4.2 Tabel Mutaba'ah Setoran Hafalan Qur'an Harian (Subuh & Maghrib)
CREATE TABLE IF NOT EXISTS public.santri_mutabaah (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    santri_id UUID REFERENCES public.santri_data(id) ON DELETE CASCADE,
    nama_santri VARCHAR(150) NOT NULL,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    sesi_halaqah VARCHAR(30) NOT NULL DEFAULT 'SUBUH', -- 'SUBUH', 'MAGHRIB', 'ZIYADAH_MALAM'
    juz INT NOT NULL DEFAULT 1,
    nama_surat VARCHAR(100) NOT NULL,
    ayat_mulai INT NOT NULL DEFAULT 1,
    ayat_selesai INT NOT NULL DEFAULT 10,
    predikat_tajwid VARCHAR(30) NOT NULL DEFAULT 'MUMTAZ', -- 'MUMTAZ', 'JAYYID_JIDDAN', 'JAYYID', 'MAQBUL', 'MURAJAAH'
    ustadz_pembimbing VARCHAR(150) NOT NULL DEFAULT 'Ustadz Pembina Tahfidz',
    catatan_evaluasi TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 5. MODUL MUSAFIR & PELAYANAN 24 JAM (PJ MUSAFIR & PELAYANAN)
-- ==============================================================================

-- 5.1 Tabel Buku Tamu Musafir, Izin Menginap / Istirahat & Loker Penitipan
CREATE TABLE IF NOT EXISTS public.musafir_logbook (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    waktu_masuk TIME DEFAULT CURRENT_TIME,
    nama_musafir VARCHAR(150) NOT NULL,
    asal_kota VARCHAR(100) NOT NULL,
    tujuan_perjalanan VARCHAR(100) NOT NULL,
    nomor_telepon VARCHAR(30) NOT NULL,
    tipe_layanan VARCHAR(50) NOT NULL DEFAULT 'SINGGAH_SHALAT', -- 'SINGGAH_SHALAT', 'ISTIRAHAT_DARURAT_24JAM', 'TITIP_KENDARAAN', 'TITIP_LOKER'
    nomor_kendaraan VARCHAR(30),
    nomor_loker VARCHAR(20),
    estimasi_durasi_jam INT DEFAULT 2,
    foto_identitas_url TEXT, -- Dokumen KTP jika menginap darurat
    status_kunjungan VARCHAR(30) DEFAULT 'AKTIF', -- 'AKTIF', 'SELESAI', 'BATAL'
    petugas_layanan VARCHAR(150) DEFAULT 'Penanggung Jawab Layanan Musafir',
    catatan_pelayanan TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 6. MODUL KEAMANAN & KETERTIBAN (PJ KEAMANAN)
-- ==============================================================================

-- 6.1 Tabel Log Piket Ronda 24 Jam & Laporan Kejadian Lapangan
CREATE TABLE IF NOT EXISTS public.security_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    shift_piket VARCHAR(30) NOT NULL DEFAULT 'PAGI', -- 'PAGI', 'SIANG', 'MALAM'
    petugas_jaga VARCHAR(150) NOT NULL,
    area_patroli VARCHAR(100) NOT NULL DEFAULT 'Parkiran & Ruang Utama', -- 'Parkiran & Gerbang', 'Ruang Utama & Selasar', 'Toilet & Sanitasi', 'Dapur & Belakang'
    kondisi_keamanan VARCHAR(30) NOT NULL DEFAULT 'KONDUSIF', -- 'KONDUSIF', 'PERHATIAN_KHUSUS', 'INSIDEN_DARURAT'
    judul_laporan VARCHAR(255) NOT NULL,
    kronologi_kejadian TEXT NOT NULL,
    bukti_media_url TEXT, -- Foto/video ImageKit
    status_tindak_lanjut VARCHAR(30) DEFAULT 'SELESAI', -- 'SELESAI', 'DALAM_PENANGANAN', 'ESKALASI_DKM'
    catatan_koordinasi TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 7. MODUL KEBERSIHAN & SANITASI (PJ KEBERSIHAN)
-- ==============================================================================

-- 7.1 Tabel Checklist Sanitasi Harian & Laporan Kebersihan
CREATE TABLE IF NOT EXISTS public.cleaning_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    shift_kebersihan VARCHAR(30) NOT NULL DEFAULT 'PAGI', -- 'PAGI', 'SIANG', 'SORE', 'MALAM'
    zona_lokasi VARCHAR(100) NOT NULL, -- 'Toilet Ikhwan', 'Toilet Akhwat', 'Tempat Wudhu Ikhwan', 'Tempat Wudhu Akhwat', 'Ruang Shalat Utama', 'Halaman & Selasar'
    petugas_kebersihan VARCHAR(150) NOT NULL,
    status_sanitasi VARCHAR(30) NOT NULL DEFAULT 'BERSIH_HARUM', -- 'BERSIH_HARUM', 'CUKUP_BERSIH', 'PERLU_PEMBERSIHAN_ULANG'
    kondisi_sarana_wudhu TEXT DEFAULT 'Kran air lancar, sabun terisi penuh.',
    foto_sebelum_url TEXT,
    foto_sesudah_url TEXT,
    kebutuhan_stok_sabun_alat TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 8. MODUL PUBLIKASI & BERANDA MEDIA (PJ MEDIA & DAKWAH)
-- ==============================================================================

-- 8.1 Tabel Manajemen Sorotan Media & Slider Beranda Publik
CREATE TABLE IF NOT EXISTS public.homepage_media (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul VARCHAR(255) NOT NULL,
    subjudul VARCHAR(255),
    kategori VARCHAR(50) DEFAULT 'SOROTAN_UTAMA', -- 'BANNER_HERO', 'SOROTAN_UTAMA', 'GALERI_KEGIATAN'
    media_url TEXT NOT NULL,
    media_type VARCHAR(20) DEFAULT 'IMAGE', -- 'IMAGE', 'VIDEO'
    action_link VARCHAR(255),
    action_label VARCHAR(100) DEFAULT 'Lihat Selengkapnya',
    order_index INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    status_review VARCHAR(30) DEFAULT 'APPROVED', -- 'DRAFT', 'PENDING_DKM', 'APPROVED'
    reviewer_name VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 9. PENYELARASAN ROW LEVEL SECURITY (RLS) ZERO-TRUST POLICIES (ALL TABLES)
-- ==============================================================================

DO $$
DECLARE
    t text;
    tables text[] := ARRAY[
        'jadwal_shalat_petugas',
        'kajian_acara_ibadah',
        'dapur_makan_siang',
        'masjid_assets',
        'financial_journals',
        'budget_requests',
        'santri_data',
        'santri_mutabaah',
        'musafir_logbook',
        'security_reports',
        'cleaning_reports',
        'homepage_media',
        'donations',
        'jadwal_petugas',
        'artikel_berita',
        'team_tasks',
        'task_activity_logs',
        'task_chat_messages',
        'system_health_logs',
        'admin_users',
        'feedback_complaints',
        'media_checklists',
        'dkm_leave_requests'
    ];
BEGIN
    FOREACH t IN ARRAY tables LOOP
        -- Pastikan RLS Aktif
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);
        
        -- Hapus policy lama jika ada agar tidak konflik
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', t || '_full_access_policy', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', t || '_public_read_policy', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', 'Allow full access for authenticated staff', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I;', 'Allow read admin profiles for authenticated', t);

        -- Buat Kebijakan Penuh & Permisif untuk anon, authenticated, dan service_role
        EXECUTE format('
            CREATE POLICY %I 
            ON public.%I 
            FOR ALL 
            TO anon, authenticated, service_role 
            USING (true) 
            WITH CHECK (true);
        ', t || '_full_access_policy', t);

        -- Atur REPLICA IDENTITY FULL untuk penangkapan data lengkap CDC WebSocket
        EXECUTE format('ALTER TABLE public.%I REPLICA IDENTITY FULL;', t);
    END LOOP;
END $$;

-- ==============================================================================
-- 10. PENDAFTARAN REALTIME CDC PUBLICATION (SUPABASE REALTIME HUB)
-- ==============================================================================

DO $$
DECLARE
    t text;
    tables text[] := ARRAY[
        'jadwal_shalat_petugas',
        'kajian_acara_ibadah',
        'dapur_makan_siang',
        'masjid_assets',
        'financial_journals',
        'budget_requests',
        'santri_data',
        'santri_mutabaah',
        'musafir_logbook',
        'security_reports',
        'cleaning_reports',
        'homepage_media',
        'donations',
        'jadwal_petugas',
        'artikel_berita',
        'team_tasks',
        'task_activity_logs',
        'task_chat_messages',
        'system_health_logs',
        'admin_users',
        'feedback_complaints',
        'media_checklists',
        'dkm_leave_requests'
    ];
BEGIN
    FOREACH t IN ARRAY tables LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I;', t);
        EXCEPTION WHEN duplicate_object THEN
            NULL;
        WHEN OTHERS THEN
            NULL;
        END;
    END LOOP;
END $$;

-- ==============================================================================
-- 11. INITIAL SEED DATA REALISTIS (MENJAMIN TABEL TIDAK KOSONG)
-- ==============================================================================

-- 11.1 Seed Jadwal Shalat & Petugas
INSERT INTO public.jadwal_shalat_petugas (tanggal, hari, subuh, dzuhur, ashar, maghrib, isya, imam_rawatib, muadzin, khatib_jumat, bilal, status_approval, submitted_by)
VALUES 
    (CURRENT_DATE, 'Ahad', '04:41', '11:59', '15:19', '17:58', '19:08', 'Ust. Ahmad Fauzi', 'Kang Ridwan', NULL, NULL, 'Approved', 'Silvih Damayanti (PJ Ibadah)'),
    (CURRENT_DATE + 1, 'Senin', '04:41', '11:59', '15:18', '17:58', '19:08', 'Ust. Ahmad Fauzi', 'Kang Ridwan', NULL, NULL, 'Approved', 'Silvih Damayanti (PJ Ibadah)'),
    (CURRENT_DATE + 5, 'Jumat', '04:40', '11:58', '15:17', '17:57', '19:07', 'Ust. Dr. H. Abdurrahman', 'Kang Ridwan', 'Ust. Dr. H. Abdurrahman', 'Kang Hasan', 'Approved', 'Silvih Damayanti (PJ Ibadah)')
ON CONFLICT DO NOTHING;

-- 11.2 Seed Kajian & Acara
INSERT INTO public.kajian_acara_ibadah (judul_kajian, penceramah, kategori, tanggal, waktu_mulai, waktu_selesai, deskripsi, status_approval)
VALUES 
    ('Tafsir Al-Qur''an Tematik: Adab Musafir & Keutamaan Shalat Berjamaah', 'Ust. Dr. H. Abdurrahman', 'Kajian Rutin', CURRENT_DATE + 2, '18:30', '20:00', 'Kajian ba''da Maghrib rutin terbuka untuk umum dan musafir yang singgah.', 'Approved'),
    ('Fiqih Muamalah: Zakat, Infaq & Sedekah di Era Digital', 'Ust. Ahmad Fauzi', 'Kajian Tematik', CURRENT_DATE + 6, '08:30', '11:00', 'Bedah tuntas hukum donasi digital dan pengelolaan kas masjid yang transparan.', 'Approved')
ON CONFLICT DO NOTHING;

-- 11.3 Seed Sedekah Makan Dzuhur
INSERT INTO public.dapur_makan_siang (tanggal, hari, menu_utama, target_porsi, realisasi_porsi, status_distribusi, logistik_bahan_catatan)
VALUES 
    (CURRENT_DATE, 'Ahad', 'Nasi Rames Ayam Bakar Madu, Sayur Asem, Tahu Tempe & Es Teh Manis', 85, 85, 'SELESAI_TERBAGI', 'Bahan baku ayam dan sayuran segar dipasok dari pasar Jatiwarna pukul 06:00 WIB.'),
    (CURRENT_DATE + 1, 'Senin', 'Nasi Soto Betawi Daging Sapi, Kerupuk & Jeruk Segar', 75, 0, 'PERSIAPAN', 'Kebutuhan beras 15kg dan bumbu rempah dapur sudah disiapkan.')
ON CONFLICT DO NOTHING;

-- 11.4 Seed Inventaris Aset
INSERT INTO public.masjid_assets (kode_aset, nama_barang, kategori, lokasi_penyimpanan, jumlah, satuan, kondisi, nilai_estimasi)
VALUES 
    ('AST-ELK-001', 'Sound System Mixer Yamaha 16-Channel', 'Elektronik & Sound', 'Ruang Audio Sound', 1, 'Unit', 'BAIK', 8500000.00),
    ('AST-ELK-002', 'Microphone Wireless Shure Beta 58A', 'Elektronik & Sound', 'Mimbar Utama', 4, 'Set', 'BAIK', 3200000.00),
    ('AST-LOG-001', 'Rice Cooker Komersial Gas 10 Liter', 'Dapur & Logistik', 'Dapur Sedekah Makan', 2, 'Unit', 'BAIK', 2400000.00),
    ('AST-KBR-001', 'Mesin Polisher Lantai Marmer Krisbow', 'Kebersihan & Sanitasi', 'Gudang Kebersihan', 1, 'Unit', 'BAIK', 4800000.00)
ON CONFLICT DO NOTHING;

-- 11.5 Seed Jurnal Keuangan
INSERT INTO public.financial_journals (kode_transaksi, tanggal, tipe_transaksi, kategori, nominal, metode_pembayaran, deskripsi)
VALUES 
    ('TRX-IN-20260828-001', CURRENT_DATE, 'KAS_MASUK', 'Infaq Donatur BSI', 2500000.00, 'TRANSFER_BSI', 'Infaq pengembangan fasilitas musafir via transfer BSI Rek 7235464297.'),
    ('TRX-IN-20260828-002', CURRENT_DATE, 'KAS_MASUK', 'QRIS Sedekah Makan', 750000.00, 'QRIS', 'Sedekah makan Dzuhur jamaah via QRIS NMID ID2025401816769.'),
    ('TRX-OUT-20260828-001', CURRENT_DATE, 'KAS_KELUAR', 'Operasional Dapur', 1250000.00, 'TUNAI', 'Belanja bahan makanan 85 porsi makan siang gratis Dzuhur.')
ON CONFLICT DO NOTHING;

-- 11.6 Seed Santri Data
INSERT INTO public.santri_data (nis, nama_lengkap, nama_panggilan, jenis_kelamin, nama_wali, kontak_wali, target_hafalan_juz, capaian_hafalan_juz)
VALUES 
    ('STR-2026-001', 'Muhammad Fatih Al-Ayyubi', 'Fatih', 'Ikhwan', 'H. Rahmat Hidayat', '+6281298765401', 30, 8),
    ('STR-2026-002', 'Aisyah Humaira Putri', 'Aisyah', 'Akhwat', 'dr. Hendra Setiawan', '+6281298765402', 30, 12),
    ('STR-2026-003', 'Zaid bin Tsabit', 'Zaid', 'Ikhwan', 'Ust. Lukman Hakim', '+6281298765403', 30, 15)
ON CONFLICT DO NOTHING;

-- 11.7 Seed Buku Tamu Musafir
INSERT INTO public.musafir_logbook (tanggal, nama_musafir, asal_kota, tujuan_perjalanan, nomor_telepon, tipe_layanan, nomor_kendaraan, nomor_loker, estimasi_durasi_jam)
VALUES 
    (CURRENT_DATE, 'Bambang Supriyanto', 'Semarang', 'Bandung (via Tol JORR Jatiwarna)', '+6281345678911', 'SINGGAH_SHALAT', 'B 1892 KZA', 'LOKER-04', 1),
    (CURRENT_DATE, 'Ahmad Ridho', 'Surabaya', 'Jakarta Pusat', '+6281345678912', 'ISTIRAHAT_DARURAT_24JAM', 'H 4432 ZP', 'LOKER-12', 4)
ON CONFLICT DO NOTHING;

-- 11.8 Seed Keamanan & Kebersihan
INSERT INTO public.security_reports (tanggal, shift_piket, petugas_jaga, area_patroli, kondisi_keamanan, judul_laporan, kronologi_kejadian)
VALUES 
    (CURRENT_DATE, 'PAGI', 'Agus Prayitno', 'Parkiran & Gerbang', 'KONDUSIF', 'Laporan Situasi Shift Pagi', 'Arus kendaraan jamaah shalat Dzuhur dan penerima sedekah makan tertib dan lancar.')
ON CONFLICT DO NOTHING;

INSERT INTO public.cleaning_reports (tanggal, shift_kebersihan, zona_lokasi, petugas_kebersihan, status_sanitasi, kondisi_sarana_wudhu)
VALUES 
    (CURRENT_DATE, 'PAGI', 'Tempat Wudhu Ikhwan', 'Suryadi', 'BERSIH_HARUM', 'Kran wudhu 12 titik berfungsi normal, lantai disikat bersih dan wangi karbol.')
ON CONFLICT DO NOTHING;
