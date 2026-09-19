-- ==============================================================================
-- Migration Script: Tambah kolom admin_notes pada tabel donations
-- Dijalankan pada Supabase SQL Editor
-- ==============================================================================

ALTER TABLE public.donations
ADD COLUMN IF NOT EXISTS admin_notes TEXT;

COMMENT ON COLUMN public.donations.admin_notes IS 'Catatan penolakan atau keterangan tambahan dari pengurus DKM';
