-- ==============================================================================
-- MIGRATION MILESTONE 1: SCHEMA SYNC & REALTIME CDC VERIFICATION
-- MASJID MUSAFIR SOPHIA JATIWARNA
-- Target: Supabase PostgreSQL (execute_sql / Migration Runner)
-- ==============================================================================

-- 1. Ensure arabic_quote column exists on public.homepage_media
ALTER TABLE public.homepage_media 
ADD COLUMN IF NOT EXISTS arabic_quote TEXT;

-- 2. Populate / ensure Quranic & Hadith text on BANNER_HERO slides
UPDATE public.homepage_media 
SET arabic_quote = 'إِنَّمَا يَعْمُرُ مَسَاجِدَ اللَّهِ مَنْ آمَنَ بِاللَّهِ وَالْيَوْمِ الْآخِرِ وَأَقَامَ الصَّلَاةَ وَآتَى الزَّكَاةَ'
WHERE kategori = 'BANNER_HERO' AND order_index = 1 AND (arabic_quote IS NULL OR arabic_quote = '');

UPDATE public.homepage_media 
SET arabic_quote = 'وَأَطْعِمُوا الطَّعَامَ وَصِلُوا الْأَرْحَامَ وَصَلُّوا بِاللَّيْلِ وَالنَّاسُ نِيَامٌ تَدْخُلُوا الْجَنَّةَ بِسَلَامٍ'
WHERE kategori = 'BANNER_HERO' AND order_index = 2 AND (arabic_quote IS NULL OR arabic_quote = '');

UPDATE public.homepage_media 
SET arabic_quote = 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ'
WHERE kategori = 'BANNER_HERO' AND order_index = 3 AND (arabic_quote IS NULL OR arabic_quote = '');

UPDATE public.homepage_media 
SET arabic_quote = 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ'
WHERE kategori = 'BANNER_HERO' AND order_index = 4 AND (arabic_quote IS NULL OR arabic_quote = '');

-- 3. Correct ImageKit cover image URL for Santri Tahfidz article in artikel_berita
UPDATE public.artikel_berita
SET thumbnail_url = 'https://ik.imagekit.io/masjidsophia/masjid-sophia/santri/Halaqah_Al-Quran_Bersama_Ustadz_01.webp'
WHERE slug = 'mutabaah-hafalan-santri-tahfidz-masjid-sophia'
   OR thumbnail_url LIKE '%Halaqah_Al_Quran%';

-- 4. Ensure REPLICA IDENTITY FULL on all 6 primary dynamic tables
ALTER TABLE public.homepage_media REPLICA IDENTITY FULL;
ALTER TABLE public.artikel_berita REPLICA IDENTITY FULL;
ALTER TABLE public.jadwal_shalat_petugas REPLICA IDENTITY FULL;
ALTER TABLE public.kajian_acara_ibadah REPLICA IDENTITY FULL;
ALTER TABLE public.donations REPLICA IDENTITY FULL;
ALTER TABLE public.feedback_complaints REPLICA IDENTITY FULL;

-- 5. Idempotent registration into supabase_realtime publication
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.homepage_media;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.artikel_berita;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.jadwal_shalat_petugas;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.kajian_acara_ibadah;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.donations;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.feedback_complaints;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;
