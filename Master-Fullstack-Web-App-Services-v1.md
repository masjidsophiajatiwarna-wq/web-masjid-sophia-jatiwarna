# MASTER BLUEPRINT: FULLSTACK WEB APP SERVICES (v1.0.0)

> Standar Arsitektur, Modul Terdistribusi, Protokol Otomasi AI (.agent ECC), dan Panduan Replikasi Antar-Brand

---

## DAFTAR ISI

1. [Standar Penulisan & Prinsip Dasar](#1-standar-penulisan--prinsip-dasar)
2. [Pemeriksaan Pra-Proyek (Pre-Flight Protocol)](#2-pemeriksaan-pra-proyek-pre-flight-protocol)
3. [Arsitektur 7 Pilar Infrastruktur](#3-arsitektur-7-pilar-infrastruktur)
4. [Katalog Modul Mandiri (Plug & Play Modules)](#4-katalog-modul-mandiri-plug--play-modules)
   - [Modul A: Dynamic Incognito Form & DB Ingestion](#modul-a-dynamic-incognito-form--db-ingestion)
   - [Modul B: Payment & Donation via QR (QRIS / EMVCo)](#modul-b-payment--donation-via-qr-qris--emvco)
   - [Modul C: Article & Content Studio (Benchmark WEB-UMAR)](#modul-c-article--content-studio-benchmark-web-umar)
   - [Modul D: Dashboard KPI & Analytics Engine](#modul-d-dashboard-kpi--analytics-engine)
   - [Modul E: Project Health & System Monitoring](#modul-e-project-health--system-monitoring)
   - [Modul F: Archive Project & Data Lifecycle](#modul-f-archive-project--data-lifecycle)
5. [Integrasi Protokol AI (.agent / ECC)](#5-integrasi-protokol-ai-agent--ecc)
6. [Fase Implementasi, Roadmap & Implementation Plan](#6-fase-implementasi-roadmap--implementation-plan)
7. [Checklist Finalisasi & Go-Live (SEO, Email, RLS, 404, Robots)](#7-checklist-finalisasi--go-live-seo-email-rls-404-robots)
8. [Changelog & Versioning](#8-changelog--versioning)

---

## 1. STANDAR PENULISAN & PRINSIP DASAR

Semua kode, dokumentasi, dan antarmuka yang dibangun di bawah standar ini wajib mematuhi 7 prinsip utama:

1. **Rapih:** Indentasi konsisten, penamaan variabel deskriptif (`camelCase` untuk JS, `snake_case` untuk SQL, `kebab-case` untuk CSS/HTML).
2. **Terstruktur:** Pemisahan concern yang jelas antara UI (presentation), Logika (business logic), dan Akses Data (data access layer).
3. **Easy to Read:** Kode dapat dipahami tanpa penjelasan lisan; dokumentasi inline hanya untuk logika kompleks.
4. **Easy to Map Out:** Struktur folder modular dan dapat dipetakan secara visual dalam 1 menit.
5. **Easy to Execute:** Skrip siap jalan dengan konfigurasi variabel lingkungan (`.env`) yang jelas.
6. **As-Humanly-As-Possible:** Penulisan pesan kesalahan, notifikasi UI, dan teks bantuan dibuat ramah, jelas, dan solutif bagi pengguna.
7. **BEBAS EMOJI (STRICT NO-EMOJI RULE):** DILARANG KERAS menggunakan emoji dalam kode, teks antarmuka, notifikasi, maupun berkas dokumentasi markdown. Gunakan ikon SVG (Lucide / Feather Icons), teks penanda formal (`[INFO]`, `[SUCCESS]`, `[WARNING]`, `[ERROR]`), atau badge CSS untuk keperluan visual profesional.

---

## 2. PEMERIKSAAN PRA-PROYEK (PRE-FLIGHT PROTOCOL)

Sebelum memulai baris kode pertama pada proyek atau brand baru, sistem/pengembang wajib menjalankan verifikasi berikut:

### 2.1. Pemeriksaan `BRAND_GUIDE.md`
* Cek apakah berkas `BRAND_GUIDE.md` tersedia di root folder.
* Jika **TIDAK DITEMUKAN**: Pengembang/AI wajib menanyakan kepada user:
  > "[PRE-FLIGHT] Berkas `BRAND_GUIDE.md` belum terdeteksi. Harap sediakan panduan identitas brand (palet warna primer/sekunder/aksen, tipografi font publik/admin, tone of voice, dan margin/layout style) sebagai acuan visual utama."

### 2.2. Pemeriksaan Direktori Aset (`/assets/`)
* Cek keberadaan folder `/assets/` beserta sub-folder:
  - `/assets/logo/`: Logo Brand utama format `.svg` atau `.png` (versi Light & Dark mode).
  - `/assets/favicon/`: `favicon.ico`, `favicon-16x16.png`, `favicon-32x32.png`, `apple-touch-icon.png`.
* Jika **TIDAK DITEMUKAN**: Pengembang/AI wajib menanyakan kepada user:
  > "[PRE-FLIGHT] Aset inti brand (Logo & Favicon) belum lengkap di dalam direktori `/assets/`. Harap unggah aset logo dan favicon berformat SVG/PNG transparan sebelum melanjutkan."

---

## 3. ARSITEKTUR 7 PILAR INFRASTRUKTUR

Setiap web application service mengadopsi stack 7 pilar berikut:

| Pilar | Platform | Peran & Tanggung Jawab |
| :---: | :--- | :--- |
| **1** | **GitHub** | Manajemen kode sumber, branching (`main`, `staging`), automasi CI/CD, issue tracking. |
| **2** | **Vercel** | Hosting Edge Global, Zero-Downtime Deployment, DNS & SSL Otomatis, Custom Error Routing. |
| **3** | **Supabase** | Backend Database (PostgreSQL), Keamanan RLS, Autentikasi JWT/OAuth, Stored Procedures. |
| **4** | **ImageKit.io** | CDN Gambar Global, Kompresi Format Otomatis (WebP/AVIF), Resize on the fly, Secure Upload Signature. |
| **5** | **Resend.com** | Layanan Pengiriman Email Transaksional & Notifikasi API, Integrasi DKIM/SPF/DMARC. |
| **6** | **Gmail Integration** | Email Bisnis Domain Kustom (`admin@domain.com`), Routing Forwarder, dan SMTP Gateway Alternatif. |
| **7** | **Google Drive** | Penyimpanan Berkas Berukuran Besar (>50MB), Video/Audio raw, Berkas Backup Database, dan Arsip Hukum. |

---

## 4. KATALOG MODUL MANDIRI (PLUG & PLAY MODULES)

Setiap modul di bawah ini bersifat independen (decoupled) dan dapat dipilih sesuai kebutuhan brand baru.

---

### Modul A: Dynamic Incognito Form & DB Ingestion

* **Tujuan:** Mengumpulkan data dari publik tanpa mewajibkan login (misal: formulir donasi masjid, pendaftaran acara, intake lead bisnis, formulir konsultasi).
* **Alur Logika:**
  1. Pengguna membuka form di browser.
  2. Input divalidasi di sisi klien (regex email, format nomor WhatsApp `+62`, panjang karakter).
  3. Mengirimkan payload ke database Supabase via kebijakan RLS khusus `anon` (Hanya diizinkan `INSERT`, dilarang `SELECT`/`UPDATE`/`DELETE`).
  4. Mencegah spam menggunakan honeypot field tersembunyi dan rate limiting IP.
* **Skema Database SQL:**

```sql
-- TABEL FORM SUBMISSION
CREATE TABLE IF NOT EXISTS public.form_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    form_type VARCHAR(50) NOT NULL, -- 'donasi', 'kontak', 'registrasi', 'survey'
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    phone_number VARCHAR(30) NOT NULL,
    amount NUMERIC(15, 2) DEFAULT 0.00,
    metadata JSONB DEFAULT '{}'::jsonb, -- Custom data dinamis per brand
    status VARCHAR(30) DEFAULT 'PENDING', -- 'PENDING', 'VERIFIED', 'PROCESSED', 'REJECTED'
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS HARDENING: Publik hanya boleh INSERT
ALTER TABLE public.form_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public anonymous insert only" 
ON public.form_submissions 
FOR INSERT 
TO anon 
WITH CHECK (true);

CREATE POLICY "Allow admin full access" 
ON public.form_submissions 
FOR ALL 
TO authenticated 
USING (auth.jwt() ->> 'role' = 'service_role' OR auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users));
```

---

### Modul B: Payment & Donation via QR (QRIS / EMVCo)

* **Tujuan:** Menyediakan pembayaran/donasi instan via QR dinamis/statis yang terintegrasi dengan pencatatan otomatis.
* **Alur Logika:**
  1. Form submission mengirimkan nominal transaksi.
  2. Generator menghasilkan payload QRIS (nominal dinamis + 3 digit kode unik acak untuk verifikasi otomatis).
  3. QR code dirender langsung ke elemen `<canvas id="qr-canvas"></canvas>`.
  4. Pengguna menyelesaikan pembayaran dan mengunggah bukti transfer (disimpan ke ImageKit/Storage) atau terkonfirmasi via webhook.
  5. Sistem mengirimkan invoice tanda terima otomatis via Resend.
* **Implementasi Skrip Klien (JavaScript):**

```javascript
// Render QRIS Payload ke Canvas
function generatePaymentQR(elementId, payloadString) {
    const canvas = document.getElementById(elementId);
    if (!canvas) return;
    
    QRCode.toCanvas(canvas, payloadString, {
        width: 280,
        margin: 2,
        color: {
            dark: '#0f172a',
            light: '#ffffff'
        }
    }, function (error) {
        if (error) console.error('[QR_GENERATOR_ERROR]', error);
        else console.log('[QR_GENERATOR_SUCCESS] QR code rendered successfully.');
    });
}
```

---

### Modul C: Article & Content Studio (Benchmark WEB-UMAR)

* **Tujuan:** Portal publikasi artikel dan berita lengkap dengan panel admin, pencarian instan, filter kategori, dan SEO tag otomatis.
* **Komponen Terintegrasi:**
  - `admin.html`: Editor artikel, unggah cover ImageKit, pengelolaan slug unik, status (`DRAFT` / `PUBLISHED`).
  - `artikel.html`: Grid daftar artikel publik, pencarian real-time, tab kategori, estimasi waktu baca.
  - `artikel-detail.html`: Halaman baca artikel dengan OpenGraph lengkap, tombol share sosial media, dan rekomendasi artikel terkait.
* **Skema Database SQL:**

```sql
-- TABEL ARTIKEL (STANDAR WEB-UMAR)
CREATE TABLE IF NOT EXISTS public.articles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    cover_image_url TEXT NOT NULL,
    excerpt TEXT NOT NULL,
    content_html TEXT NOT NULL,
    author_name VARCHAR(100) DEFAULT 'Tim Redaksi',
    reading_time_minutes INT DEFAULT 3,
    is_published BOOLEAN DEFAULT false,
    view_count BIGINT DEFAULT 0,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    meta_description VARCHAR(200),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS HARDENING: Publik hanya bisa baca artikel PUBLISHED
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read published articles" 
ON public.articles 
FOR SELECT 
TO anon, authenticated 
USING (is_published = true);

CREATE POLICY "Allow admin write articles" 
ON public.articles 
FOR ALL 
TO authenticated 
USING (auth.jwt() ->> 'role' = 'service_role' OR auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users));
```

---

### Modul D: Dashboard KPI & Analytics Engine

* **Tujuan:** Visualisasi data performa proyek/brand (total interaksi form, revenue/donasi, artikel terpopuler, konversi).
* **Fitur Utama:**
  - **Card Metric:** Total Submissions, Total Revenue, Conversion Rate, Total Views.
  - **Grafik Tren Interaktif:** Tren harian & bulanan berbasis Chart.js.
  - **Filter Rentang Tanggal:** Date Range Picker.
  - **Fitur Ekspor Data:** CSV & Print-Ready Summary.

---

### Modul E: Project Health & System Monitoring

* **Tujuan:** Monitoring performa dan ketersediaan semua layanan eksternal secara terpusat.
* **Indikator yang Dipantau:**
  - **Database Status:** Latensi respon PostgreSQL Supabase (ms).
  - **CDN Health:** Ketersediaan endpoint ImageKit.
  - **Email Service Health:** Status koneksi Resend API.
  - **Storage Quota:** Persentase kapasitas database & media storage.
* **Tampilan Visual Panel Admin:** Badge status `[HEALTHY / OPERATIONAL]`, `[DEGRADED]`, `[DOWN]`.

---

### Modul F: Archive Project & Data Lifecycle

* **Tujuan:** Mengelola penonaktifan proyek atau pemindahan data historis lama agar database tetap efisien.
* **Fitur Utama:**
  - **Soft Delete / Archival Flag:** Menyembunyikan data kadaluarsa dari query publik.
  - **Cold Storage Backup:** Mengekspor rekaman data berumur > 1 tahun ke format NDJSON/CSV dan menyimpannya secara terstruktur di folder Google Drive khusus menggunakan Service Account API.
  - **Restore Endpoint:** Memulihkan arsip data kembali ke database jika diperlukan.

---

## 5. INTEGRASI PROTOKOL AI (.agent / ECC)

Setiap repositori dan proyek baru wajib menyertakan direktori `.agent/` yang berisi dokumentasi dan aturan dari Everything Claude Code (ECC).

### Peran Agen AI dalam Pengembangan:
* **Planner (`planner`):** Menganalisis kebutuhan fitur baru dan menyusun rancangan arsitektur sebelum implementasi kode.
* **Architect (`architect`):** Menjaga skalabilitas database, relasi skema SQL, dan desain sistem.
* **TDD-Guide (`tdd-guide`):** Menulis pengujian unit dan integrasi sebelum fungsi inti dieksekusi.
* **Code-Reviewer (`code-reviewer`):** Memeriksa kualitas kode, keterbacaan, dan kepatuhan terhadap aturan no-emoji serta prinsip immutability.
* **Security-Reviewer (`security-reviewer`):** Mengaudit kebijakan Row Level Security (RLS) Supabase, sanitasi input XSS, pencegahan SQL Injection, dan perlindungan variabel rahasia (`.env`).

---

## 6. FASE IMPLEMENTASI, ROADMAP & IMPLEMENTATION PLAN

Setiap pembuatan atau kloning proyek baru mengikuti 7 fase terstruktur berikut:

```text
[FASE 0: Discovery]  --> Cek BRAND_GUIDE.md & Folder /assets/
       |
[FASE 1: Infra]      --> Setup GitHub Repo, Vercel Project, Supabase Project, ImageKit, Resend
       |
[FASE 2: Database]   --> Jalankan Migrasi SQL, Skema Tabel, Stored Procedures & Hardening RLS
       |
[FASE 3: Core App]   --> Bangun Modul Terpilih (Form, QR Payment, Artikel, Dashboard KPI)
       |
[FASE 4: UI/UX]      --> Terapkan Standar Visual Brand (Responsif Mobile-First, No-Emoji)
       |
[FASE 5: Testing]    --> Validasi Alur Transaksi, Keamanan Form & Audit RLS
       |
[FASE 6: Go-Live]    --> Setup SEO, Google Search Console, Bing Webmaster, Email DNS & 404
```

### Roadmap & Implementation Timeline:
* **Hari 1:** Fase 0 (Discovery) & Fase 1 (Infrastruktur & Akun Service).
* **Hari 2:** Fase 2 (Skema Database & RLS) & Fase 3 (Modul Form & Pembayaran).
* **Hari 3:** Fase 3 (Modul Artikel & Dashboard KPI) & Fase 4 (Penyesuaian UI Brand).
* **Hari 4:** Fase 5 (Pengujian & Security Audit) & Fase 6 (SEO, Email Routing & Peluncuran).

---

## 7. CHECKLIST FINALISASI & GO-LIVE

Sebelum proyek dinyatakan selesai dan diserahterimakan ke publik, seluruh checklist berikut wajib dipenuhi:

### 7.1. Optimasi Mesin Pencari (SEO & Metadata)
- [ ] Menambahkan tag `<title>` unik dan deskripsi `<meta name="description">` di setiap halaman.
- [ ] Menyediakan OpenGraph Tags (`og:title`, `og:description`, `og:image`, `og:url`, `og:type`).
- [ ] Menyediakan Twitter Card Tags (`twitter:card`, `twitter:title`, `twitter:image`).
- [ ] Menambahkan Schema.org JSON-LD (`WebSite`, `Organization`, `Article`).

### 7.2. Google Search Console & Bing Webmaster
- [ ] Mendaftarkan domain kustom di Google Search Console (verifikasi via DNS TXT record atau HTML tag).
- [ ] Mendaftarkan domain di Bing Webmaster Tools (sinkronisasi dari Google Search Console).
- [ ] Mengunggah berkas `sitemap.xml` ke Google dan Bing Webmaster.

### 7.3. Berkas `robots.txt` & `404.html`
- [ ] Membuat berkas `robots.txt` di root direktori:

```text
User-agent: *
Allow: /
Disallow: /admin
Disallow: /api/private/
Sitemap: https://[DOMAIN_BRAND]/sitemap.xml
```

- [ ] Membuat halaman `404.html` kustom yang rapih, informatif, dan memiliki tombol navigasi kembali ke Beranda (Home).

### 7.4. Pengerasan Keamanan (Security & Database RLS Hardening)
- [ ] Semua tabel di Supabase memiliki status `ENABLE ROW LEVEL SECURITY`.
- [ ] Tidak ada kunci API rahasia (Service Role Key) yang terekspos di kode klien JavaScript. Klien hanya menggunakan Anon Public Key.
- [ ] Menambahkan header keamanan pada Vercel (`vercel.json`): Content Security Policy (CSP), X-Content-Type-Options, X-Frame-Options.

### 7.5. Pengaturan Email Profesional & Routing
- [ ] **Resend.com:** Verifikasi domain pengirim dengan menambahkan catatan DNS DKIM, SPF, dan DMARC.
- [ ] **Supabase Auth Email:** Menghubungkan Custom SMTP Resend ke pengaturan Supabase Auth (menghindari limit email default).
- [ ] **Gmail Routing:** Menyiapkan penerusan email (forwarding) dari domain bisnis ke akun Gmail pengelola dengan filter penanda label.

---

## 8. CHANGELOG & VERSIONING

### Versi 1.0.0 (Baseline Release)
* `[INIT]` Standarisasi arsitektur 7 pilar (GitHub, Vercel, Supabase, ImageKit, Resend, Gmail, Google Drive).
* `[FEAT]` Katalog modul mandiri: Form Incognito, Payment QR, Artikel Benchmark WEB-UMAR, Dashboard KPI, Project Health, dan Archive.
* `[RULES]` Integrasi aturan penulisan profesional, larangan emoji, protokol pre-flight `BRAND_GUIDE.md`, dan checklist Go-Live lengkap.