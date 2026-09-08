-- ==============================================================================
-- MIGRASI SISTEM UNGGAH & HAPUS BERKAS IMAGEKIT.IO CDN VIA SUPABASE RPC
-- Proyek: Web Portal Masjid Musafir Sophia Jatiwarna
-- ==============================================================================

-- 1. Pastikan Ekstensi Kriptografi & Jaringan Aktif
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Tabel Penyimpanan Kredensial Sensitif (app_secrets)
-- Proteksi Ketat: Matikan RLS, Cabut Hak Akses dari anon, authenticated, dan public.
-- Hanya role postgres dan service_role yang memiliki akses langsung.
CREATE TABLE IF NOT EXISTS public.app_secrets (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.app_secrets DISABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.app_secrets FROM anon, authenticated, public;
GRANT ALL ON public.app_secrets TO postgres, service_role;

-- 3. Simpan Kredensial ImageKit ke app_secrets
INSERT INTO public.app_secrets (key, value, description)
VALUES 
    (
        'IMAGEKIT_PRIVATE_KEY', 
        'YOUR_IMAGEKIT_PRIVATE_KEY', 
        'ImageKit Private Key untuk otentikasi HMAC-SHA1 upload dan Basic Auth delete'
    ),
    (
        'IMAGEKIT_URL_ENDPOINT',
        'https://ik.imagekit.io/masjidsophia',
        'ImageKit CDN URL Endpoint Masjid Sophia'
    ),
    (
        'IMAGEKIT_PUBLIC_KEY',
        'public_masjidsophia',
        'ImageKit Public Key (dapat disesuaikan melalui Developer Options ImageKit)'
    )
ON CONFLICT (key) DO UPDATE 
SET value = EXCLUDED.value, description = EXCLUDED.description, updated_at = now();

-- 4. Tabel Log & Pustaka Media Terpusat (media_library)
CREATE TABLE IF NOT EXISTS public.media_library (
    id TEXT PRIMARY KEY,
    file_name TEXT NOT NULL,
    public_url TEXT NOT NULL,
    file_size_kb NUMERIC,
    file_type TEXT DEFAULT 'image/webp',
    dimensions TEXT,
    folder TEXT DEFAULT '/masjid-sophia',
    uploaded_at TIMESTAMPTZ DEFAULT now(),
    imagekit_file_id TEXT DEFAULT NULL,
    uploaded_by TEXT DEFAULT 'Pengurus DKM'
);

ALTER TABLE public.media_library ENABLE ROW LEVEL SECURITY;

-- Kebijakan Akses: Publik dapat melihat, user terotentikasi dapat menambah dan menghapus
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'media_library' AND policyname = 'Public read media_library'
    ) THEN
        CREATE POLICY "Public read media_library" ON public.media_library FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'media_library' AND policyname = 'Auth insert media_library'
    ) THEN
        CREATE POLICY "Auth insert media_library" ON public.media_library FOR INSERT WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'media_library' AND policyname = 'Auth update media_library'
    ) THEN
        CREATE POLICY "Auth update media_library" ON public.media_library FOR UPDATE USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'media_library' AND policyname = 'Auth delete media_library'
    ) THEN
        CREATE POLICY "Auth delete media_library" ON public.media_library FOR DELETE USING (true);
    END IF;
END $$;

-- Pastikan tabel homepage_media memiliki kolom imagekit_file_id jika belum ada
ALTER TABLE public.homepage_media ADD COLUMN IF NOT EXISTS imagekit_file_id TEXT DEFAULT NULL;

-- 5. Fungsi RPC: Pembuat Signature Upload ImageKit (get_imagekit_auth)
-- Berjalan dengan hak akses SECURITY DEFINER (sebagai user postgres di server)
CREATE OR REPLACE FUNCTION public.get_imagekit_auth()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_private_key TEXT;
    v_public_key TEXT;
    v_url_endpoint TEXT;
    v_token TEXT;
    v_expire BIGINT;
    v_signature TEXT;
BEGIN
    SELECT value INTO v_private_key 
    FROM public.app_secrets 
    WHERE key = 'IMAGEKIT_PRIVATE_KEY';
    
    IF v_private_key IS NULL OR v_private_key = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'IMAGEKIT_PRIVATE_KEY belum disetel di tabel app_secrets.'
        );
    END IF;

    SELECT value INTO v_public_key 
    FROM public.app_secrets 
    WHERE key = 'IMAGEKIT_PUBLIC_KEY';

    SELECT value INTO v_url_endpoint 
    FROM public.app_secrets 
    WHERE key = 'IMAGEKIT_URL_ENDPOINT';

    -- Token unik (UUID v4) dan waktu kedaluwarsa 30 menit ke depan
    v_token := gen_random_uuid()::text;
    v_expire := extract(epoch from (now() + interval '30 minutes'))::bigint;

    -- Signature: HMAC-SHA1(token + expire, privateKey) dalam format hexadecimal
    v_signature := encode(
        hmac(
            (v_token || v_expire::text)::bytea,
            v_private_key::bytea,
            'sha1'
        ),
        'hex'
    );

    RETURN json_build_object(
        'success', true,
        'token', v_token,
        'expire', v_expire,
        'signature', v_signature,
        'publicKey', COALESCE(v_public_key, ''),
        'urlEndpoint', COALESCE(v_url_endpoint, 'https://ik.imagekit.io/masjidsophia')
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_imagekit_auth() TO anon, authenticated;

-- 6. Fungsi RPC: Penghapus Berkas Fisik di ImageKit (delete_imagekit_file)
-- Berjalan dengan hak akses SECURITY DEFINER dan memanggil API ImageKit via pg_net
CREATE OR REPLACE FUNCTION public.delete_imagekit_file(p_file_id TEXT)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, net
AS $$
DECLARE
    v_private_key TEXT;
    v_auth_header TEXT;
    v_request_id BIGINT;
BEGIN
    IF p_file_id IS NULL OR p_file_id = '' THEN
        RETURN json_build_object('success', false, 'error', 'File ID tidak boleh kosong.');
    END IF;

    SELECT value INTO v_private_key 
    FROM public.app_secrets 
    WHERE key = 'IMAGEKIT_PRIVATE_KEY';
    
    IF v_private_key IS NULL OR v_private_key = '' THEN
        RETURN json_build_object('success', false, 'error', 'IMAGEKIT_PRIVATE_KEY belum disetel di app_secrets.');
    END IF;

    -- Basic Auth: Base64(privateKey + ':')
    v_auth_header := 'Basic ' || encode(convert_to(v_private_key || ':', 'UTF8'), 'base64');

    -- Request HTTP DELETE asinkron via ekstensi pg_net
    BEGIN
        SELECT net.http_delete(
            url := 'https://api.imagekit.io/v1/files/' || p_file_id,
            headers := jsonb_build_object(
                'Authorization', v_auth_header,
                'Content-Type', 'application/json'
            )
        ) INTO v_request_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Gagal mengirim permintaan hapus pg_net: ' || SQLERRM
        );
    END;

    -- Hapus dari media_library jika ada
    DELETE FROM public.media_library WHERE imagekit_file_id = p_file_id;

    RETURN json_build_object(
        'success', true,
        'message', 'Permintaan hapus berkas fisik telah dikirim ke ImageKit.',
        'request_id', v_request_id,
        'file_id', p_file_id
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_imagekit_file(TEXT) TO anon, authenticated;
