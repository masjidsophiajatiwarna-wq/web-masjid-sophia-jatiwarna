# SPESIFIKASI MODUL: DYNAMIC INCOGNITO FORM & DB INGESTION
> Kode Modul: `MOD-01` | Versi: `1.0.0` | Kategori: `Core & Public Interaction` | Dependensi: `Supabase, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-01-DYNAMIC-INCOGNITO-FORM` |
| **Nama Modul** | Dynamic Incognito Form & DB Ingestion |
| **Kategori** | Public Intake & Lead Capture |
| **Level Akses Publik** | Anonymous Public (`anon` Role) |
| **Tingkat Decoupling** | 100% Standalone (Dapat dipasang di web statis mana pun) |
| **Integrasi Pilar** | Supabase (PostgreSQL + RLS), Resend (Auto-Email Notification) |

---

## 2. TUJUAN BISNIS & USE CASE

Modul ini dirancang untuk menangkap data dari pengunjung publik secara cepat tanpa mengharuskan pengunjung membuat akun atau masuk (*login*). Mengurangi gesekan (*friction*) pendaftaran hingga 70%.

### Use-Case Utama:
1. **Formulir Donasi Publik / Kotak Amal Digital:** Pengumpulan dana sosial dan zakat/infaq secara anonim atau terdaftar.
2. **Formulir Kontak Bisnis & Penawaran:** Intake prospek (lead capture) untuk layanan jasa dan konsultasi.
3. **Formulir Pendaftaran Acara / Webinar Terbuka:** Pendaftaran instan tanpa password.
4. **Survei Kepuasan & Kotak Saran:** Pengumpulan kritik dan aspirasi anonim dari publik.

---

## 3. DIAGRAM ALUR LOGIKA & ANTI-SPAM DEFENSE

```text
[PENGUNJUNG]
     |
     v
[1. Form Klien (HTML/JS)]
     |-- Validasi Regex (Email, WhatsApp +62, Karakter)
     |-- Pemeriksaan Honeypot Field (Field tersembunyi untuk jebakan bot)
     |-- Client-Side Rate Limit (Throttle submit via LocalStorage)
     |
     v
[2. Supabase API Gateway]
     |-- RLS Engine: Evaluasi Policy "Allow public anonymous insert only"
     |-- Mencegah akses SELECT, UPDATE, DELETE untuk publik
     |
     v
[3. PostgreSQL Ingestion]
     |-- Insert ke public.form_submissions
     |-- Trigger Database: Eksekusi notifikasi otomatis (opsional)
     |
     v
[4. Notifikasi Transaksional (Resend API)]
     |-- Mengirim email konfirmasi ke pengisi form
     |-- Mengirim ringkasan lead ke pengelola/admin
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- EKSTENSI YANG DIBUTUHKAN
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TABEL FORM SUBMISSION LENGKAP
CREATE TABLE IF NOT EXISTS public.form_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    form_type VARCHAR(50) NOT NULL, -- 'donasi', 'kontak', 'registrasi', 'survey', 'konsultasi'
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    phone_number VARCHAR(30) NOT NULL,
    amount NUMERIC(15, 2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'IDR',
    metadata JSONB DEFAULT '{}'::jsonb, -- Menyimpan data dinamis (pesan, opsi, custom input)
    status VARCHAR(30) DEFAULT 'PENDING', -- 'PENDING', 'VERIFIED', 'PROCESSED', 'REJECTED', 'SPAM'
    ip_address VARCHAR(45),
    user_agent TEXT,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_form_submissions_type ON public.form_submissions (form_type);
CREATE INDEX IF NOT EXISTS idx_form_submissions_status ON public.form_submissions (status);
CREATE INDEX IF NOT EXISTS idx_form_submissions_created_at ON public.form_submissions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_form_submissions_metadata ON public.form_submissions USING gin (metadata);

-- AUTO UPDATE TIMESTAMP TRIGGER
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_form_submissions_updated_at ON public.form_submissions;
CREATE TRIGGER trg_form_submissions_updated_at
BEFORE UPDATE ON public.form_submissions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
-- 1. AKTIFKAN KEAMANAN RLS
ALTER TABLE public.form_submissions ENABLE ROW LEVEL SECURITY;

-- 2. HAK AKSES PUBLIK (ANON): HANYA INSERT, DILARANG MELIHAT ATAU MENGUBAH
CREATE POLICY "Allow public anonymous insert only" 
ON public.form_submissions 
FOR INSERT 
TO anon 
WITH CHECK (
    -- Validasi anti data kosong pada level database
    char_length(trim(full_name)) >= 2 AND 
    char_length(trim(phone_number)) >= 8
);

-- 3. HAK AKSES ADMIN OTENTIKASI: BACA, UPDATE, DAN ARSIP
CREATE POLICY "Allow admin full access" 
ON public.form_submissions 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. KONTRAK API & IMPLEMENTASI SKRIP KLIEN (JAVASCRIPT)

```javascript
/**
 * MOD-01: Form Handler Klien
 * Integrasi Supabase JS SDK v2
 */
const SUPABASE_URL = 'https://[PROJECT_ID].supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOi...'; // Public anon key ONLY
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function submitIncognitoForm(event) {
    event.preventDefault();
    const form = event.target;
    const submitBtn = form.querySelector('button[type="submit"]');

    // 1. Anti-Spam Honeypot Verification
    const honeypot = form.querySelector('input[name="website_url"]');
    if (honeypot && honeypot.value !== '') {
        console.warn('[SPAM_DETECTED] Honeypot field triggered.');
        showNotification('[WARNING] Permintaan Anda terdeteksi sebagai spam.', 'warning');
        return;
    }

    // 2. Ekstraksi Data
    const payload = {
        form_type: form.dataset.formType || 'kontak',
        full_name: form.querySelector('#full_name').value.trim(),
        email: form.querySelector('#email') ? form.querySelector('#email').value.trim() : null,
        phone_number: form.querySelector('#phone_number').value.trim(),
        amount: form.querySelector('#amount') ? parseFloat(form.querySelector('#amount').value) || 0 : 0,
        metadata: {
            subject: form.querySelector('#subject') ? form.querySelector('#subject').value : '',
            message: form.querySelector('#message') ? form.querySelector('#message').value : '',
            referrer: document.referrer || 'direct'
        }
    };

    // 3. Validasi Format Nomor WhatsApp Indonesia
    const phoneRegex = /^(\+62|62|0)8[1-9][0-9]{6,11}$/;
    if (!phoneRegex.test(payload.phone_number)) {
        showNotification('[ERROR] Format nomor telepon/WhatsApp tidak valid. Contoh: 081234567890', 'error');
        return;
    }

    // 4. Loading State
    submitBtn.disabled = true;
    submitBtn.innerText = 'Mengirim data...';

    try {
        const { data, error } = await supabaseClient
            .from('form_submissions')
            .insert([payload])
            .select('id')
            .single();

        if (error) throw error;

        showNotification('[SUCCESS] Terima kasih! Formulir Anda telah berhasil kami terima.', 'success');
        form.reset();

        // Callback opsional jika terhubung ke Modul B (Payment QRIS)
        if (typeof onFormSubmissionSuccess === 'function') {
            onFormSubmissionSuccess(data.id, payload);
        }
    } catch (err) {
        console.error('[FORM_SUBMIT_ERROR]', err);
        showNotification('[ERROR] Terjadi kesalahan saat mengirim data. Silakan coba lagi.', 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.innerText = 'Kirim Sekarang';
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA (HTML & FORM COMPONENTS)

```html
<!-- STRUKTUR FORM INCOGNITO FORMAL (STRICT NO-EMOJI) -->
<form id="public-intake-form" data-form-type="kontak" onsubmit="submitIncognitoForm(event)" class="form-container">
    <!-- Honeypot Field (Tersembunyi dari Pengguna Nyata) -->
    <div style="display: none;" aria-hidden="true">
        <input type="text" name="website_url" tabindex="-1" autocomplete="off">
    </div>

    <div class="form-group">
        <label for="full_name">Nama Lengkap <span class="required">*</span></label>
        <input type="text" id="full_name" name="full_name" required placeholder="Masukkan nama lengkap Anda" class="form-input">
    </div>

    <div class="form-group">
        <label for="phone_number">Nomor WhatsApp <span class="required">*</span></label>
        <input type="tel" id="phone_number" name="phone_number" required placeholder="Contoh: 081234567890" class="form-input">
    </div>

    <div class="form-group">
        <label for="email">Alamat Email (Opsional)</label>
        <input type="email" id="email" name="email" placeholder="nama@domain.com" class="form-input">
    </div>

    <div class="form-group">
        <label for="message">Pesan / Keterangan</label>
        <textarea id="message" name="message" rows="4" placeholder="Tuliskan kebutuhan Anda secara rinci" class="form-textarea"></textarea>
    </div>

    <div class="form-actions">
        <button type="submit" class="btn btn-primary">Kirim Sekarang</button>
    </div>
</form>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Validasi Anonim:** Pengguna tanpa sesi login dapat melakukan `INSERT` tanpa error CORS atau otorisasi.
- [ ] **Keamanan Data:** Pengguna publik dilarang keras melakukan `SELECT` pada endpoint tabel `form_submissions`.
- [ ] **Uji Honeypot:** Mengisi field `website_url` menggagalkan proses tanpa membuat entri di database.
- [ ] **Respon Cepat:** Proses submit dan konfirmasi selesai dalam waktu < 800ms.
- [ ] **Kepatuhan Aturan:** Tidak ada emoji dalam teks antarmuka atau notifikasi.