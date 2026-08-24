-- ==============================================================================
-- MIGRASI SINKRONISASI EMAIL OTOMATIS: AUTH.USERS -> PUBLIC.ADMIN_USERS
-- Masjid Musafir Sophia Jatiwarna
-- ==============================================================================

-- 1. Buat fungsi trigger untuk mendeteksi perubahan email pada auth.users
CREATE OR REPLACE FUNCTION public.handle_auth_user_email_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email IS DISTINCT FROM OLD.email THEN
        UPDATE public.admin_users
        SET email = LOWER(TRIM(NEW.email)),
            updated_at = NOW()
        WHERE id = NEW.id OR LOWER(TRIM(email)) = LOWER(TRIM(OLD.email));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Pasang trigger pada tabel auth.users
DROP TRIGGER IF EXISTS on_auth_user_email_updated ON auth.users;
CREATE TRIGGER on_auth_user_email_updated
    AFTER UPDATE OF email ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_auth_user_email_update();

-- 3. Prosedur Pembantu: Perbarui Email Pengurus secara Langsung & Aman
CREATE OR REPLACE FUNCTION public.update_admin_user_email(p_user_id UUID, p_new_email VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    v_clean_email VARCHAR;
BEGIN
    v_clean_email := LOWER(TRIM(p_new_email));

    -- A. Update di auth.users
    UPDATE auth.users
    SET email = v_clean_email,
        email_confirmed_at = NOW(),
        updated_at = NOW()
    WHERE id = p_user_id;

    -- B. Update di auth.identities
    UPDATE auth.identities
    SET identity_data = jsonb_set(identity_data, '{email}', to_jsonb(v_clean_email)),
        provider_id = v_clean_email,
        updated_at = NOW()
    WHERE user_id = p_user_id AND provider = 'email';

    -- C. Update di public.admin_users
    UPDATE public.admin_users
    SET email = v_clean_email,
        updated_at = NOW()
    WHERE id = p_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.update_admin_user_email(UUID, VARCHAR) TO anon, authenticated, service_role;

-- 4. Verifikasi & Contoh Eksekusi Langsung Jika Ingin Mengubah Email Super User:
-- SELECT public.update_admin_user_email('6a937ea3-1372-4eb9-924b-026cb326cb12'::uuid, 'ajaabe50@gmail.com');

SELECT 'Trigger dan Prosedur Sinkronisasi Email Auth ke Admin Users Berhasil Dipasang!' AS status;
