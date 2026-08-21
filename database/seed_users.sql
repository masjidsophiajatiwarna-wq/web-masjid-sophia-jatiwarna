-- ==============================================================================
-- SEED USER ACCOUNTS: 11 AKUN PENGURUS DKM & TESTING MASJID SOPHIA JATIWARNA
-- Target: Supabase Auth (auth.users) & Profil Pengurus (public.admin_users)
-- ==============================================================================

-- 1. Pastikan ekstensi pgcrypto aktif untuk enkripsi password bcrypt
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Pastikan kolom division ada pada tabel admin_users
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS division VARCHAR(100);

-- 3. Fungsi Helper untuk membuat/memperbarui akun Supabase Auth secara aman
CREATE OR REPLACE FUNCTION public.create_dkm_user(
    p_email VARCHAR,
    p_password VARCHAR,
    p_full_name VARCHAR,
    p_role VARCHAR,
    p_division VARCHAR,
    p_phone VARCHAR DEFAULT '+6281234567890'
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_encrypted_pw TEXT;
BEGIN
    v_encrypted_pw := crypt(p_password, gen_salt('bf', 10));

    -- Cek apakah user sudah ada di auth.users
    SELECT id INTO v_user_id FROM auth.users WHERE email = p_email;

    IF v_user_id IS NULL THEN
        -- Buat user baru di auth.users dengan email terverifikasi langsung
        v_user_id := gen_random_uuid();
        
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        ) VALUES (
            '00000000-00-00-00-000000000000',
            v_user_id,
            'authenticated',
            'authenticated',
            p_email,
            v_encrypted_pw,
            NOW(),
            jsonb_build_object('provider', 'email', 'providers', array['email']),
            jsonb_build_object(
                'full_name', p_full_name,
                'role', p_role,
                'division', p_division,
                'phone_number', p_phone
            ),
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        );
    ELSE
        -- Update password dan metadata jika user sudah ada
        UPDATE auth.users
        SET encrypted_password = v_encrypted_pw,
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            raw_user_meta_data = jsonb_build_object(
                'full_name', p_full_name,
                'role', p_role,
                'division', p_division,
                'phone_number', p_phone
            ),
            updated_at = NOW()
        WHERE id = v_user_id;
    END IF;

    -- Sinkronisasi ke tabel public.admin_users
    INSERT INTO public.admin_users (
        id,
        email,
        full_name,
        role,
        division,
        phone_number,
        is_active,
        created_at
    ) VALUES (
        v_user_id,
        p_email,
        p_full_name,
        p_role,
        p_division,
        p_phone,
        TRUE,
        NOW()
    )
    ON CONFLICT (email) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        division = EXCLUDED.division,
        phone_number = EXCLUDED.phone_number,
        is_active = TRUE;

    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- 4. EKSEKUSI PEMBUATAN 11 AKUN RESMI PENGURUS & TESTING
-- Password Default Awal: SophiaJatiwarna2026!
-- ==============================================================================

DO $$
BEGIN
    -- 1. SUPER ADMIN (Administrator Sistem & Developer)
    PERFORM public.create_dkm_user(
        'superadmin@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Super Administrator Sophia',
        'SUPER_ADMIN',
        'IT & Ekosistem Digital',
        '+6281234567890'
    );

    -- 2. SUPER USER (Akun Khusus Testing & Validasi Penuh)
    PERFORM public.create_dkm_user(
        'superuser@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Super User Testing Sophia',
        'SUPER_USER',
        'Quality Assurance & Audit',
        '+6281234567891'
    );

    -- 3. KETUA DKM (Pimpinan Tertinggi DKM)
    PERFORM public.create_dkm_user(
        'dkm@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Ketua DKM Masjid Sophia',
        'KETUA_DKM',
        'Pimpinan DKM',
        '+6281234567892'
    );

    -- 4. PJ MEDIA & DAKWAH
    PERFORM public.create_dkm_user(
        'media@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Penanggung Jawab Media & Dakwah',
        'PJ_MEDIA',
        'Media & Dakwah',
        '+6281234567893'
    );

    -- 5. PJ LOGISTIK & SARPRAS (Dapur Makan Siang & Aset)
    PERFORM public.create_dkm_user(
        'logistik@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Penanggung Jawab Logistik & Sarpras',
        'PJ_LOGISTIK',
        'Logistik & Sarpras',
        '+6281234567894'
    );

    -- 6. PJ SANTRI & PENDIDIKAN (Tahfidz Al-Qur''an)
    PERFORM public.create_dkm_user(
        'santri@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Penanggung Jawab Santri Tahfidz',
        'PJ_SANTRI',
        'Santri & Tahfidz',
        '+6281234567895'
    );

    -- 7. PJ MUSAFIR & PELAYANAN (Layanan 24 Jam & Buku Tamu)
    PERFORM public.create_dkm_user(
        'musafir@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Penanggung Jawab Layanan Musafir',
        'PJ_MUSAFIR',
        'Pelayanan Musafir',
        '+6281234567896'
    );

    -- 8. PJ IBADAH & ACARA (Jadwal Shalat & Petugas)
    PERFORM public.create_dkm_user(
        'ibadah@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Penanggung Jawab Peribadatan & Acara',
        'PJ_IBADAH',
        'Peribadatan & Acara',
        '+6281234567897'
    );

    -- 9. PJ KEUANGAN (Bendahara & Akuntansi)
    PERFORM public.create_dkm_user(
        'keuangan@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Bendahara & Akuntansi DKM',
        'PJ_KEUANGAN',
        'Keuangan & Akuntansi',
        '+6281234567898'
    );

    -- 10. PJ KEAMANAN (Log Piket & Ronda 24 Jam)
    PERFORM public.create_dkm_user(
        'keamanan@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Penanggung Jawab Keamanan & Ketertiban',
        'PJ_KEAMANAN',
        'Keamanan & Ketertiban',
        '+6281234567899'
    );

    -- 11. PJ KEBERSIHAN (Sanitasi & Perawatan)
    PERFORM public.create_dkm_user(
        'kebersihan@masjidsophiajatiwarna.com',
        'SophiaJatiwarna2026!',
        'Penanggung Jawab Kebersihan & Sanitasi',
        'PJ_KEBERSIHAN',
        'Kebersihan & Sanitasi',
        '+6281234567800'
    );

    RAISE NOTICE '11 Akun Pengurus DKM & Super User Testing berhasil dibuat!';
END $$;
