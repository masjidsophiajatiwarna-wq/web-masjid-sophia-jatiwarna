-- ==============================================================================
-- MIGRASI PERBAIKAN SKEMA: PENYESUAIAN HOMEPAGE_MEDIA & MASTER CONFIG
-- Masjid Musafir Sophia Jatiwarna (09/09/2026)
-- ==============================================================================

-- 1. Perluas tipe kolom action_link pada homepage_media menjadi TEXT
-- Mencegah error HTTP 400 'value too long for type character varying(255)' saat menyimpan JSON konfigurasi
ALTER TABLE public.homepage_media 
    ALTER COLUMN action_link TYPE TEXT;

-- 2. Tambahkan kolom meta_json (JSONB) jika belum tersedia untuk penyimpanan payload terstruktur
ALTER TABLE public.homepage_media 
    ADD COLUMN IF NOT EXISTS meta_json JSONB DEFAULT '{}'::jsonb;

-- 3. Pastikan record konfigurasi master HOMEPAGE_CONFIG_MASTER tersedia dan valid
INSERT INTO public.homepage_media (
    id,
    judul,
    subjudul,
    kategori,
    media_url,
    media_type,
    action_link,
    action_label,
    order_index,
    is_active,
    status_review,
    reviewer_name,
    meta_json
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'HOMEPAGE_CONFIG_MASTER',
    'Konfigurasi Visual Builder Beranda Masjid Sophia',
    'HOMEPAGE_CONFIG',
    'config',
    'CONFIG_JSON',
    '#',
    'Lihat Selengkapnya',
    0,
    true,
    'APPROVED',
    'Super Administrator',
    '{"heroTitle": "Masjid Sophia Jatiwarna", "sections": {"prayer": true, "officers": true, "philanthropy": true, "musafir": true, "news": true}}'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    action_link = EXCLUDED.action_link,
    updated_at = NOW();

-- 4. Pastikan publikasi realtime memuat tabel-tabel utama
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.homepage_media;
        EXCEPTION WHEN duplicate_object THEN
            -- Table already in publication
        END;
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.kajian_acara_ibadah;
        EXCEPTION WHEN duplicate_object THEN
            -- Table already in publication
        END;
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.donations;
        EXCEPTION WHEN duplicate_object THEN
            -- Table already in publication
        END;
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.financial_journals;
        EXCEPTION WHEN duplicate_object THEN
            -- Table already in publication
        END;
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.security_reports;
        EXCEPTION WHEN duplicate_object THEN
            -- Table already in publication
        END;
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.cleaning_reports;
        EXCEPTION WHEN duplicate_object THEN
            -- Table already in publication
        END;
    END IF;
END $$;
