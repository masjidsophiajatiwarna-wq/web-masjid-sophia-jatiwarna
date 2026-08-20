# SPESIFIKASI MODUL: CUSTOMER PORTAL & MEMBER SELF-SERVICE
> Kode Modul: `MOD-08` | Versi: `1.0.0` | Kategori: `Customer Experience & Auth (Odoo-Grade Suite)` | Dependensi: `Supabase Auth, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-08-CUSTOMER-PORTAL-AUTH` |
| **Nama Modul** | Customer Portal & Member Self-Service Dashboard |
| **Kategori** | Authentication, Profile & Customer Account |
| **Level Akses Publik** | Customer Authenticated Session (`auth.uid()`) |
| **Tingkat Decoupling** | High (Menghubungkan pelanggan ke riwayat MOD-04, MOD-06, MOD-07, MOD-11, MOD-16) |
| **Integrasi Pilar** | Supabase Auth (Magic Link Passwordless & OAuth Google), Resend (Transactional Auth) |

---

## 2. TUJUAN BISNIS & USE CASE

Memberikan akses mandiri (*self-service*) bagi pelanggan atau anggota komunitas untuk melihat status pesanan, mengunduh salinan invoice/e-tiket, memperbarui profil alamat, dan mengajukan tiket bantuan tanpa harus selalu menghubungi admin.

### Fitur Unggulan:
1. **Passwordless Magic Link Auth:** Masuk hanya menggunakan link yang dikirim ke email via Resend SMTP (zero password fatigue).
2. **Dashboard Sentral Pelanggan:** Tab ringkasan pesanan, riwayat faktur, dan tiket yang pernah dibuat.
3. **Manajemen Buku Alamat:** Menyimpan beberapa alamat pengiriman (Rumah, Kantor).
4. **Pembaruan Profil & Preferensi Notifikasi:** Pengaturan preferensi notifikasi WhatsApp dan email.

---

## 3. DIAGRAM ALUR AUTENTIKASI & AKSES PORTAL

```text
[PELANGGAN (portal-login.html)]
     |
     v (1. Masukkan Email -> Minta Magic Link)
[Supabase Auth Engine]
     |-- Generate Secure One-Time Token
     |-- Kirim Email Magic Link via Resend SMTP
     |
     v (2. Klik Link di Email)
[Verifikasi Sesi Klien (portal-dashboard.html)]
     |-- Simpan JWT Access Token di Browser Session
     |
     v (3. Akses Data Terproteksi via RLS auth.uid())
[Query Data Pelanggan]
     |-- SELECT FROM public.customer_profiles WHERE id = auth.uid()
     |-- SELECT FROM public.ecommerce_orders WHERE customer_email = auth.email()
     |-- SELECT FROM public.invoices WHERE customer_email = auth.email()
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL PROFIL PELANGGAN (LINK DENGAN SUPABASE AUTH.USERS)
CREATE TABLE IF NOT EXISTS public.customer_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(30) NOT NULL,
    avatar_url TEXT,
    company_name VARCHAR(150),
    tax_id VARCHAR(50), -- NPWP
    default_address TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(10),
    notification_preferences JSONB DEFAULT '{"email": true, "whatsapp": true}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- AUTO-CREATE PROFILE SAAT USER BARU MENDAFTAR DI AUTH.USERS
CREATE OR REPLACE FUNCTION public.handle_new_customer_signup()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.customer_profiles (id, full_name, phone_number)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Pelanggan Baru'),
        COALESCE(NEW.raw_user_meta_data->>'phone_number', '-')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_customer_signup();
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.customer_profiles ENABLE ROW LEVEL SECURITY;

-- 1. Pelanggan hanya bisa melihat dan mengedit profil miliknya sendiri
CREATE POLICY "Customers can view own profile" 
ON public.customer_profiles 
FOR SELECT 
TO authenticated 
USING (auth.uid() = id);

CREATE POLICY "Customers can update own profile" 
ON public.customer_profiles 
FOR UPDATE 
TO authenticated 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 2. Admin dapat melihat seluruh data pelanggan
CREATE POLICY "Admin can view all customer profiles" 
ON public.customer_profiles 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: MAGIC LINK LOGIN & SESSION GUARD (JAVASCRIPT)

```javascript
/**
 * MOD-08: Customer Portal Auth & Session Guard
 */

// Kirim Magic Link ke Email
async function sendCustomerMagicLink(email) {
    const { data, error } = await supabaseClient.auth.signInWithOtp({
        email: email,
        options: {
            emailRedirectTo: window.location.origin + '/portal/dashboard.html'
        }
    });

    if (error) {
        console.error('[AUTH_ERROR]', error);
        showNotification('[ERROR] Gagal mengirim link login. Pastikan email benar.', 'error');
    } else {
        showNotification('[SUCCESS] Link login telah dikirim ke email Anda! Silakan periksa inbox.', 'success');
    }
}

// Session Guard untuk Halaman Dashboard Portal
async function enforceCustomerAuth() {
    const { data: { session } } = await supabaseClient.auth.getSession();

    if (!session) {
        window.location.href = '/portal/login.html';
        return null;
    }

    return session.user;
}
```

---

## 7. SPESIFIKASI ANTARMUKA PORTAL PELANGGAN

```html
<div class="portal-layout">
    <aside class="portal-sidebar">
        <div class="user-brief">
            <h4 class="user-name" id="user-display-name">Ahmad Fauzan</h4>
            <span class="user-badge">[MEMBER AKTIF]</span>
        </div>
        <nav class="portal-nav">
            <a href="#orders" class="nav-item active">Riwayat Pesanan</a>
            <a href="#invoices" class="nav-item">Tagihan & Faktur</a>
            <a href="#tickets" class="nav-item">E-Tiket Acara</a>
            <a href="#profile" class="nav-item">Pengaturan Akun</a>
        </nav>
    </aside>

    <main class="portal-content">
        <div class="card-section">
            <h3>Pesanan Terakhir Anda</h3>
            <div id="customer-orders-list">
                <!-- List Pesanan Render JS -->
            </div>
        </div>
    </main>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Proteksi Data Pribadi:** Pelanggan A sama sekali tidak bisa mengakses profil atau tagihan milik Pelanggan B.
- [ ] **Magic Link Delivery:** Link login terkirim cepat via Resend dan memiliki masa kadaluarsa 10 menit.
- [ ] **Session Recovery:** Sesi login tetap tersimpan secara aman setelah browser ditutup (Refresh Token Rotation).
- [ ] **Strict No-Emoji:** Navigasi antarmuka portal dan badge profil menggunakan teks formal standar.