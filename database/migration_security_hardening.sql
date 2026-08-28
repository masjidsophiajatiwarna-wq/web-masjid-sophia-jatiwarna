-- ==============================================================================
-- MIGRASI KEAMANAN: DATABASE HARDENING & SEARCH_PATH PROTECTION
-- Supabase Project ID: fcwajbemkbhkogwtqcmx (Masjid Musafir Sophia Jatiwarna)
-- ==============================================================================

-- 1. Hardening search_path & izin eksekusi pada fungsi force_end_user_session
ALTER FUNCTION public.force_end_user_session(p_user_id uuid) SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.force_end_user_session(p_user_id uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.force_end_user_session(p_user_id uuid) TO authenticated, service_role;

-- 2. Hardening search_path & izin eksekusi pada fungsi trigger handle_auth_user_email_update
ALTER FUNCTION public.handle_auth_user_email_update() SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.handle_auth_user_email_update() FROM anon, public, authenticated;

-- 3. Hardening search_path & izin eksekusi pada fungsi create_dkm_user
ALTER FUNCTION public.create_dkm_user(
    p_email character varying, 
    p_password character varying, 
    p_full_name character varying, 
    p_role character varying, 
    p_division character varying, 
    p_phone character varying
) SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.create_dkm_user(
    p_email character varying, 
    p_password character varying, 
    p_full_name character varying, 
    p_role character varying, 
    p_division character varying, 
    p_phone character varying
) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.create_dkm_user(
    p_email character varying, 
    p_password character varying, 
    p_full_name character varying, 
    p_role character varying, 
    p_division character varying, 
    p_phone character varying
) TO authenticated, service_role;

-- 4. Hardening fungsi update_admin_user_email jika tersedia di database
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc p 
        JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'public' AND p.proname = 'update_admin_user_email'
    ) THEN
        EXECUTE 'ALTER FUNCTION public.update_admin_user_email(uuid, character varying) SET search_path = public;';
        EXECUTE 'REVOKE EXECUTE ON FUNCTION public.update_admin_user_email(uuid, character varying) FROM anon, public;';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.update_admin_user_email(uuid, character varying) TO authenticated, service_role;';
    END IF;
END $$;

SELECT 'Database Security Hardening Berhasil Diterapkan di Supabase fcwajbemkbhkogwtqcmx!' AS status;
