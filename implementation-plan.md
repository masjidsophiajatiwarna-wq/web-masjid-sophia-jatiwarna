# Master Implementation Plan - Ekosistem Portal Masjid Musafir Sophia Jatiwarna

**Entitas Proyek:** Masjid Musafir Sophia Jatiwarna  
**Lokasi Koordinat Astronomis:** Latitude `-6.310391`, Longitude `106.921264` (Zona Waktu: WIB / UTC+7)  
**Alamat:** Jl. Raya Hankam, RT.001/RW.011, Jatiwarna, Pondok Melati, Kota Bekasi, Jawa Barat 17415  
**Target Repositori:** `https://github.com/masjidsophiajatiwarna-wq/web-masjid-sophia-jatiwarna.git`  
**Domain Utama Produksi (Target Baru):** `https://masjidsophia.com/`  
**Domain Sekunder & Lawas (Redirect 301 Permanen):** `https://masjidsophiajatiwarna.com/`, `https://masjidsophiajatiwarna.my.id/`  
**Subdomain Pemantauan, Admin & Staging:** `https://progdev.masjidsophia.com/`, `https://admin.masjidsophia.com/`, `https://dev.masjidsophia.com/`  
**Versi Rencana Induk:** v6.8 (Perbaikan Antarmuka Tombol Respon Kotak Saran Jamaah)  
**Terakhir Diperbarui:** 2026-09-21  

---

## 1. Ringkasan Eksekutif & Sasaran Strategis

Masjid Musafir Sophia Jatiwarna membutuhkan ekosistem web portal modern, terpadu, dan berstandar tinggi yang melayani dua ranah utama:

1. **Layanan Informasi & Filantropi Terbuka untuk Publik (Benchmark: Masjid Istiqlal Jakarta & Web-UMAR Artikel):**
   - Portal umat & musafir mandiri bertema terang (*Pure White*, *Soft Cream Sand*, *Charcoal*, dan *Sophia Gold*).
   - Hisab jadwal shalat presisi lokal Kemenag Jatiwarna dengan *Live Countdown Timer*.
   - Program Makan Berjamaah Gratis (70+ porsi/hari) & Pembinaan Santri Tahfidz.
   - Kanal Donasi 1-Click Copy Rekening BSI `7235464297` & QRIS SEDEKAH MAKAN (NMID `ID2025401816769`).
   - Direktori Berita & Artikel Dakwah (`artikel.html` & `artikel-detail.html`) dengan pencarian instan, filter kategori, estimasi waktu baca, dan tombol share.
   - Galeri Multimedia (`galeri.html`) terhubung ke ImageKit CDN 20GB.
   - Kanal Pengaduan, Kotak Saran, dan Aspirasi Fasilitas Jamaah.
   - Layanan Musafir 24 Jam: Kamar mandi bersih, area istirahat, dispenser air minum, dan rute lokasi samping UMAR Travel.
2. **Sistem Manajemen Operasional Terpadu DKM & Employee Dashboard (Benchmark: SIABE-PORTO & Standard Modul Odoo/Masjid):**
   - **Desain Fluid Desktop vs Mobile-First Touch UI:** Pengalaman desktop yang lega dan leluasa, serta adaptasi fluid ke antarmuka mobile-first khusus smartphone (Table Drag Grabber Engine, Bottom Navigation Bar, Bottom Sheet Modal Drawer, target sentuh min 48px, gestur swipe touch pan).
   - **Task Management Karyawan 5 View + 2 Panel:** Kanban, Gantt Timeline Split-Pane ISO 8601, Calendar 2-Layer Matrix SIABE-PORTO Spanning Bars, All Tasks Table (Filter/Sort/Bulk Archive/CSV), Archive View per divisi, Riwayat Pengelolaan Realtime (CDC WebSocket 100% tanpa refresh), dan Chat Koordinasi Multi-Arah Pro WhatsApp-Style antar semua PJ & Ketua DKM.
   - **Suite Modul Manajemen Pengguna DKM (Account Control & RBAC Matrix):**
     - Tabel direktori akun pengurus realtime dengan pelacakan presensi 3-tier (Online, Idle, Offline) zero server overhead.
     - Modal override akun untuk Super Admin & Ketua DKM: reset kredensial ke default baku, auto-pattern multi-PJ (`media2@...`), matriks hak akses 17 modul granular (`permissions JSONB`), dan paksa akhiri sesi (*Force Logout*).
     - Modal profil mandiri pengurus: upload foto avatar ImageKit CDN dan pembaruan password/email dengan aturan wajib login ulang (*Strict Security Auto-Logout*).
     - Lapisan persistensi hibrida master lokal (`masjid_sophia_admin_users_master`) sebagai fail-safe otomatis terhadap pembatasan Row Level Security (RLS 403) Supabase DB.
   - **Suite Modul Operasional per Penanggung Jawab (PJ) Divisi:**
     - **PJ Media & Dakwah:** Content & Article Studio (Quill.js Rich Text, slug generator, ImageKit WebP cover), Dynamic Homepage Media Manager, dan Lightbox Gallery.
     - **PJ Logistik & Sarpras:** Manajemen Porsi Makan Dzuhur (kebutuhan bahan, porsi terbagi, logistik dapur) & Manajemen Aset/Inventaris Masjid (nomor inventaris, kondisi aset, lokasi, riwayat servis).
     - **PJ Santri & Pendidikan:** Data Profil Santri Tahfidz, Absensi Halaqah (Subuh & Maghrib), Mutaba'ah Setoran Hafalan Qur'an (Juz/Surat/Ayat/Tajwid), dan Rapor Perkembangan.
     - **PJ Musafir & Pelayanan:** Buku Tamu Musafir Digital, Log Tamu Menginap/Istirahat Darurat 24 Jam, dan Log Penitipan Kendaraan & Loker Barang.
     - **PJ Ibadah & Acara:** Kalibrasi Hisab & Menit Ikhtiyat, Rotasi Petugas Harian (Imam 5 waktu, Muadzin, Khatib Jumat, Bilal), dan Kalender Acara/Kajian Tematik/PHBI + Arsip Khutbah.
     - **PJ Keuangan (Accounting & Budget Request Suite):** Buku Kas Masuk (Infaq, QRIS, BSI, Tunai), Buku Kas Keluar (Operasional, Dapur, Sarpras, Santunan), Alur Pengajuan Anggaran (*Budget Request*) & Klaim Nota Bon (*Expense Reimbursement*) bagi seluruh 7 PJ divisi dengan approval flow Ketua DKM, Laporan Arus Kas, dan Neraca Kas Transparan (Export CSV & Print PDF).
     - **PJ Keamanan:** Log Piket Keamanan 24 Jam, Patroli Parkiran, Input Laporan Insiden, dan Unggah Bukti Foto/Video ke ImageKit CDN (auto WebP/WebM).
     - **PJ Kebersihan:** Checklist Sanitasi Harian (Wudhu, Toilet, Ruang Shalat Utama, Halaman), Input Laporan Kebersihan, Unggah Bukti Foto/Video ke ImageKit CDN (auto WebP/WebM), dan Kontrol Stok Bahan Pembersih.
   - **Super Admin Multi-Cloud 7 Pilar Monitor:** Pemantauan real-time kuota free-tier (Supabase DB & Storage, Vercel Bandwidth, ImageKit 20GB, Resend Email API, GitHub Actions, Cloudflare, Google Drive).
   - **Pipeline Aplikasi Mobile Android (3 Tingkat):** PWA Web Manifest, TWA / WebAPK installer `MasjidSophia-Admin.apk` (auto-sync update dari Vercel), dan Native Wrapper Capacitor.js (Push Notification & Camera Access).

---

## 2. Peta Fase Implementasi Teknis

```text
[FASE 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid] (STATUS: SELESAI 100%)
       |
[FASE 1: Inisialisasi Infrastruktur, Berkas Tata Kelola & Monitoring] (STATUS: SELESAI 100%)
       |
[FASE 2: Fondasi Database Supabase, Auth, Storage & Hardening RLS] (STATUS: SELESAI 100%)
       |
[FASE 3: Frontend Web Portal Publik, Berita Dakwah, Galeri & Modul Shalat] (STATUS: SELESAI 100%)
       |
[FASE 4: Web Admin DKM, Fluid Mobile-First UI & Suite Modul Lengkap PJ] (STATUS: SELESAI 100%)
       |
[FASE 5: Pengujian Terpadu, Audit Keamanan & User Acceptance Testing] (STATUS: SELESAI 100%)
       |
[FASE 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live] (STATUS: 95% SELESAI)
       |
[FASE 7: Pipeline Aplikasi Mobile Android (.apk) & PWA Khusus Pengurus DKM] (STATUS: RENCANA LANJUTAN)
```

---

## 3. Rincian Pekerjaan Tiap Fase

### Fase 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid
- **Status:** Selesai (100%)
- **Penanganan:** Kurasi aset media, kompresi batch WebP Lanczos (`quality=85`), unggah ImageKit.io CDN via Python Pipeline (`scripts/batch_image_optimizer_imagekit.py`), dan sinkronisasi manifest katalog (`asset/imagekit-manifest.json`) ke tabel Supabase `media_library` & `homepage_media` (`scripts/sync_manifest_to_supabase.py`).
- **Daftar Tugas:**
  - [x] Audit aset logo resmi format vektor SVG (`logo_masjid_black.svg`, `logo_masjid_white.svg`) dan PNG transparan.
  - [x] Verifikasi paket Favicon multi-ukuran (16x16, 32x32, Apple Touch Icon, Android Chrome, site.webmanifest).
  - [x] Kurasi galeri foto riil (128 berkas foto: Makan Siang Gratis, fasilitas 24 jam, santri tahfidz, ruang utama, fasad).
  - [x] Konversi dan kompresi seluruh aset foto ke format WebP teroptimasi untuk performa web (422.1 MB dikompresi menjadi 32.74 MB, efisiensi 92.2%).
  - [x] Unggah 100% aset ke CDN ImageKit.io (`https://ik.imagekit.io/masjidsophia/masjid-sophia/...`) dan integrasi manifest ke Supabase DB.

---

### Fase 1: Inisialisasi Infrastruktur, Berkas Tata Kelola & Monitoring
- **Status:** Selesai (100%)
- **Daftar Tugas:**
  - [x] Penyusunan berkas acuan `BRAND_GUIDE.md` (Tema Terang: `#FFFFFF`, `#F8F6F0`, `#1D1D1B`, `#E3C466`, `#C9A84C`).
  - [x] Penyusunan `Master-Fullstack-Web-App-Services-v1.md` (Arsitektur 7 Pilar).
  - [x] Pembuatan `.gitignore`, `README.md`, dan `CHANGELOG.md`.
  - [x] Pembuatan `implementation-plan.md` & antarmuka `progress-implementation-plan.html`.
  - [x] Konfigurasi Redirect 301 di Cloudflare DNS untuk domain sekunder (`masjidsophia.com`, `masjidsophiajatiwarna.my.id`).

---

### Fase 2: Fondasi Database Supabase, Auth, Storage & Hardening RLS
- **Status:** Selesai (100%)
- **Daftar Tugas:**
  - [x] **Master Skema Inti PostgreSQL (`database/schema.sql`):** `donations`, `jadwal_petugas`, `artikel_berita`, `team_tasks`, `system_health_logs`, `admin_users`, `feedback_complaints`, `media_checklists`.
  - [x] **Zero-Trust RLS Policies & Serverless Functions:** `/api/health.js`, `/api/donasi.js`, `/api/send-receipt.js`, `/api/pengaduan.js`.
  - [x] **Migrasi Skema Tambahan Task Management v2 & Obrolan Realtime (`database/migration_task_management_v1.6.sql`):**
    - `team_tasks` (ALTER: `start_date`, `is_archived`, `order_index`, `progress_pct`, `created_by`).
    - `task_activity_logs` (Audit trail riwayat pengelolaan tugas CDC).
    - `task_chat_messages` (Obrolan koordinasi tim multi-arah pro).
    - RLS Policies & Publikasi Supabase Realtime WebSocket.
  - [x] **Migrasi Skema Modul Account & Access Control (`database/migration_account_control.sql`):**
    - `admin_users` (ALTER: `avatar_url`, `permissions JSONB`, `session_version`).
    - Fungsi `force_end_user_session()` dan Realtime CDC `admin_users`.
  - [x] **Migrasi Sistem Media Unggah & Hapus Fisik Terpusat ImageKit.io CDN via Supabase RPC (`database/migration_imagekit_rpc_setup.sql`):**
    - Tabel terproteksi `public.app_secrets` (eksklusif `postgres` & `service_role`).
    - Fungsi RPC `public.get_imagekit_auth()` (HMAC-SHA1 signature generator aman).
    - Fungsi RPC `public.delete_imagekit_file(p_file_id)` (HTTP DELETE via `pg_net` API ImageKit).
    - Endpoint serverless relay `/api/imagekit-upload.js` dengan Basic Auth aman.
    - Injeksi 14 titik unggah berkas di `admin.html` ke ImageKit CDN.
  - [x] **Migrasi Skema Lanjutan Suite Modul PJ Operasional & Standarisasi RFC 4122 UUID (`database/migration_suite_all_modules_v2.sql`):**
    - 11 tabel operasional diselaraskan dengan RFC 4122 UUID v4: `jadwal_shalat_petugas`, `dapur_makan_siang`, `masjid_assets`, `financial_journals`, `budget_requests`, `santri_data`, `santri_mutabaah`, `musafir_logbook`, `security_reports`, `cleaning_reports`, `artikel_berita`.
  - [x] **Arsitektur Keamanan Zero-Leak & Isolasi Kredensial Runtime (Strict Zero-Hardcode):**
    - Endpoint serverless Vercel `/api/config.js` (`/api/config`) untuk melayani `supabaseUrl` dan `supabaseAnonKey` secara dinamis saat runtime dari `process.env`.
    - Pemuat runtime modular universal `asset/js/env-loader.js` (`window.MasjidConfig`) dengan mekanisme failover 5-tingkat (In-Memory -> SessionStorage -> `config.local.js` -> Serverless API `/api/config` -> LocalStorage) dan lazy initialization Supabase client.
    - Pembersihan 100% seluruh hardcode string URL proyek dan anon public key JWT dari berkas publik dan admin: `index.html`, `admin.html`, `media-checklist.html`, `api/health.js`, `api/donasi.js`, `api/pengaduan.js`, `api/cloud-usage.js`, dan `.github/workflows/supabase-keepalive.yml`.
    - Hardening `.gitignore` untuk memblokir seluruh berkas kredensial (`.env*`, `config.local.js`, `credentials.txt`, `AKUN_PENGURUS_DKM.txt`, `logerror/`, `.agents/`) serta penyediaan template dokumentasi aman `.env.example`.
    - Audit pemindaian otomatis seluruh repositori dengan status kelulusan 100% (0 temuan celah kebocoran kunci).

---

### Fase 3: Frontend Web Portal Publik, Berita Dakwah, Galeri & Modul Shalat
- **Benchmark Rujukan:** Masjid Istiqlal Jakarta (`https://www.istiqlal.or.id/`) & UMAR Travel (`artikel.html`, `artikel-detail.html`)
- **Status:** Selesai (100%)
- **Daftar Tugas:**
  - [x] **Design System & Komponen Beranda Inti (`index.html`):** Tema Terang Resmi, Hisab Jadwal Shalat Jatiwarna (Kemenag) + Live Countdown, Kartu Petugas Ibadah, Box Donasi BSI 1-Click Copy `7235464297` & QRIS SEDEKAH MAKAN, Dynamic Incognito Form, Informasi Fasilitas Musafir 24 Jam.
  - [x] **Integrasi Realtime Shalat & Petugas Ibadah (`index.html` <-> `admin.html`):** Query dinamis ke tabel Supabase `jadwal_shalat_petugas` status `Approved`, fallback hisab astronomis otomatis bila belum ada jadwal terbit, sinkronisasi live nama Imam 5 waktu, Muadzin, Khatib Jumat, dan update countdown timer tanpa reload via WebSocket Supabase Realtime channel `public:jadwal_shalat_petugas:index` dan `public:kajian_acara_ibadah:index`.
  - [x] **Redesign Besar Beranda Publik (Benchmark Istiqlal):** Dynamic Hero Banner Slider ImageKit WebP terhubung ke `homepage_media`, Kalender Ganda Hijriah Ummul Qura & Masehi, Agenda Majelis Kajian Pekanan terhubung ke `kajian_acara_ibadah`, Galeri Sorotan 4 Album Istiqlal berdesain photo-stack terhubung ke `/galeri`, kartu warta dakwah terhubung ke `/artikel/:slug`, Sticky Header w/ Infaq Button, Mobile Bottom Navigation Bar 5-Tab, dan Footer Informatif 4 Kolom.
  - [x] **Kolom Pengaduan, Saran & Aspirasi Jamaah di Web Publik:** Modal interaktif terhubung ke serverless `/api/pengaduan` dan tabel `feedback_complaints` dengan notifikasi toast elegan & reset form otomatis.
  - [x] **Supabase Realtime CDC 6 Channel:** Langganan aktif WebSocket sinkronisasi instan tanpa refresh untuk `jadwal_shalat_petugas`, `homepage_media`, `kajian_acara_ibadah`, `artikel_berita`, `donations`, dan `feedback_complaints`.
  - [x] **Halaman Direktori Berita & Artikel Dakwah (`artikel.html` - Benchmark UMAR):** Live Search, Filter Kategori Pills, Warta Pilihan Utama (*Featured Article Card*), Grid Kartu Warta ImageKit WebP (estimasi waktu baca, nama penulis, tanggal terbit), dan integrasi runtime Supabase Zero-Hardcode.
  - [x] **Halaman Detail Artikel Mandiri (`artikel-detail.html` - Benchmark UMAR):** Breadcrumbs navigasi Islami, Sticky Reading Progress Bar di puncak, Hero Cover WebP, Meta Bar Penulis, Box Kutipan Pembuka, Rich Text Body Content, Tombol Bagikan Media Sosial (WhatsApp, FB, X, Salin Tautan), Rekomendasi 3 Artikel Terkait, Box Ajakan Infaq BSI, dan resolusi slug dinamis (`/artikel-detail.html?slug=...` sesuai benchmark resmi UMAR Travel dan fail-safe HTTP 307 redirect untuk rute legacy `/artikel/:slug`).
  - [x] **Halaman Galeri Multimedia Mandiri (`galeri.html` - Benchmark Istiqlal):** Live Search Bar, Filter Kategori Pills (Semua, Makan Siang, Santri, Fasilitas, Ibadah, Fasad), Grid Kartu Foto Berbadge, Fullscreen Lightbox Photo Viewer interaktif (navigasi keyboard panah & Esc), dan sinkronisasi katalog ImageKit.
  - [x] **Hero Carousel Slider Manager Unlimited di Admin (`admin.html#media`):** Modul CRUD lengkap penambahan slide tak terbatas, pemilihan aset ImageKit, kolom ayat Al-Qur'an/Hadits Arab berharakat (`arabic_quote`), subjudul quotes terjemahan, CTA button editor, pengatur urutan, switch aktif/non-aktif, dan siaran broadcast Realtime CDC.
  - [x] **Clean URLs & Fail-Safe Routing (`vercel.json`):** Pengaktifan `cleanUrls: true`, `trailingSlash: false`, dynamic rewrites `/galeri`, `/artikel`, `/admin`, dan HTTP 307 redirects fail-safe untuk rute warta dinamis `/artikel/:slug` menuju `/artikel-detail.html?slug=:slug`.
  - [x] **Test Suite Kepatuhan Terpadu (`scripts/verify_index_compliance.py`):** Lolos 100% (8 sub-tes: file integrity, Strict No-Emoji, no admin links on public, zero hardcoded secrets, structural check, standalone pages check, routing check, and CDC channel subscriptions).

---

### Fase 4: Web Admin DKM, Fluid Mobile-First UI & Suite Modul Lengkap PJ
- **Benchmark Rujukan:** SIABE-PORTO (Task Engine & Cloud Monitor), WEB-UMAR Admin (Article Studio), dan Standard Modul Odoo/Masjid (`.unused-modul-web-sophia`)
- **Status:** Selesai (100%)
- **Catatan:** Admin Core, Task Engine 5 View, Chat Realtime, Account & Dynamic RBAC, Profil Mandiri, 11 Modul Operasional PJ, PDF Export Kinerja DKM — semua selesai.
- **Daftar Tugas:**
  - [x] **Pondasi Admin Core & Auth Gate (`admin.html`):** Gerbang login Supabase Auth JWT, sidebar adaptif RBAC 10 peran, panel KPI Real-Time, inbox kotak saran, dan rekonsiliasi kas harian.
  - [x] **Restrukturisasi Bilah Samping Navigasi (Sidebar 4 Pilar Fungsional):** Penataan 9 kelompok menu terfragmentasi menjadi 4 pilar fungsional operasional masjid (Ruang Kerja & Tugas, Pelayanan & Pendidikan, Operasional & Fasilitas, Media & Keuangan) plus Pengaturan & Sistem, menghemat 40% ruang vertikal dan mengeliminasi anti-pola menu tunggal.
  - [x] **Perbaikan Rute Navigasi 4 Modul Operasional & Penyelarasan Galeri Media ImageKit CDN 20 GB (`admin.html`):**
    - Whitelist array `validTabs` pada fungsi `switchTab(tabId)` ditambahkan 4 modul operasional (`santri`, `musafir`, `keamanan`, `kebersihan`), mengeliminasi bug reset tampilan ke Ringkasan Operasional.
    - Pembersihan header `top-app-bar`: menghapus tombol *Hub Checklist Media* dan tombol *Refresh Data* yang rawan memicu kekeliruan pengurus.
    - Penyelarasan modul Galeri Media dan Tab Artikel ke infrastruktur **ImageKit.io CDN 20 GB (20.480 MB)**, menghapus teks AI flexing (*Engine pintar...*), merapikan simetri bilah pencarian dan tombol *"Unggah Media"*, serta menyempurnakan status unggah berkas CDN.
  - [x] **Optimasi Antarmuka Fluid Desktop & Mobile-First Touch UI (`admin.html`):**
    - **Tampilan Desktop / Laptop:** Multi-kolom lebar, split-pane layout gantt (fixed sidebar 250px + timeline), tabel data komprehensif, sidebar collapse to icon mode (72px).
    - **Tampilan Smartphone (Android & iPhone):** Table Drag Grabber Engine (`.table-responsive`), drag-to-scroll kursor grab/grabbing, target sentuh min 48px, gestur swipe touch pan, auto-center Today view, modal backdrop scroll lock (`overflow: hidden`).
  - [x] **Task Management Terpadu (5 View + 2 Panel):**
    - [x] Kanban Board (drag-and-drop HTML5, filter divisi, badge prioritas, dan tombol cepat sentuh status).
    - [x] Gantt Timeline (arsitektur split-pane zero leakage, bar jadwal mulai hingga tenggat per PJ dengan skala Hari/Pekanan ISO 8601 W01-W53/Bulan, Auto-Fit all tasks, grab-to-scroll pan, auto-center Today).
    - [x] Calendar View (arsitektur 2-layer matrix SIABE-PORTO, baris pekan terpisah, background grid + events layer, continuous multi-day spanning bars via grid-column, collision-free vertical slotting, across-week continuation indicators, drag & hold date range selection, strict date chronological validation).
    - [x] All Tasks Table (filter multi-kriteria, live search, sorting interaktif, bulk archive, bulk delete, dan unduh CSV).
    - [x] Archive View (penyimpanan tugas selesai per divisi, 1-klik pulihkan, dan hapus permanen).
    - [x] Riwayat Pengelolaan Realtime (CDC WebSocket 100% tanpa refresh + RFC4122 UUID).
    - [x] Chat Koordinasi Multi-Arah Pro (WhatsApp-style reply/quote, WhatsApp markdown bold/italic/strike/code, multiline auto-grow composer, @PJ_Nama cursor-aware mentions & unread badge counters, Delete for Everyone CHAT_DELETE broadcast & Supabase CDC, ImageKit WebP/WebM media attachment, 7-day query filter & cache retention).
  - [x] **Modul User Accounts & Access Control (Khusus Super Admin & Ketua DKM - Benchmark SIABE-PORTO):**
    - [x] **Tabel Seluruh Akun Pengurus Realtime:** Daftar akun DKM dengan status presisi (Online / Idle / Offline) berbasis 3-Tier Activity Presence SIABE-PORTO, status login terakhir (*last active*), peran, divisi, algoritma pengurutan **Online-First Prioritas**, dan sinkronisasi live tanpa refresh via Supabase Presence & CDC.
    - [x] **Modal Override Akun (Super Admin / DKM):** Reset kredensial ke baku awal (1-click reset ke `AKUN_PENGURUS_DKM.txt`), ubah email/nama, auto-pattern multi-PJ generator (`media2@...`), dan tombol **Paksa Akhiri Sesi (*Force End Session / Logout*)** via WebSocket `FORCE_LOGOUT`.
    - [x] **Fitur Hapus Akun Permanen (Alur Aman 2 Langkah):** Tombol *Hapus Akun* disematkan eksklusif di dalam dialog box modal edit pengurus dengan proteksi akun inti (*root shield*), validasi dialog konfirmasi Modal 5, pembersihan multi-lapisan (DB Supabase + Local Master), dan siaran WebSocket `USER_DELETE_EVENT`.
    - [x] **Matriks Izin Dinamis 17 Modul (`permissions JSONB`):** Pengaturan hak akses granular per modul (Penuh / Baca / Request / Review / Laporan / Kajian / Persetujuan / Tidak Ada Akses) yang merender sidebar secara dinamis dan fleksibel (non-hardcoded).
    - [x] **Lapisan Presensi & Persistensi Hibrida (`masjid_sophia_admin_users_master`):** 3-Tier Activity Presence (Online <1 jam, Idle 1-3 jam, Offline >3 jam/logout, 3-hour inactivity session timeout), Single-Write Login Broadcast (tanpa polling heartbeat berat), dan Local Master Persistence sebagai fail-safe pembatasan Row Level Security (RLS 403 Forbidden).
  - [x] **Modal Profil & Keamanan Mandiri Pengurus (Self-Service Profile & Security - Standar Brand Sophia):**
    - [x] **Akses Mandiri PJ Divisi:** Dibuka lewat klik kartu profil/avatar di pojok kiri bawah sidebar.
    - [x] **Tab 1 - Profil Umum:** Ubah Nama Lengkap dan **Upload Foto Profil (Avatar)** dari perangkat lokal langsung teroptimasi (auto WebP 400x400) ke **ImageKit.io CDN**.
    - [x] **Tab 2 - Keamanan & Sandi:** Ganti kata sandi dan ganti email dengan **Strict Security Rule: Otomatis Logout & Wajib Login Ulang**.
    - [x] **Penyelarasan Visual Brand Sophia:** Latar belakang putih bersih `.modal-box`, indikator tab aktif garis bawah emas Sophia Gold tebal, tombol aksi bergradasi *Charcoal Gold Glow*, dan 100% bahasa Indonesia santun & formal.
  - [x] **Suite Modul Khusus per Divisi PJ (Terkoneksi Realtime Database PostgreSQL & Sinkronisasi Lintas Perangkat):**
    - [x] **Standarisasi RFC 4122 UUID v4 Multi-Modul:** Mengganti format ID string berbasis timestamp dengan UUID v4 standar industri di 11 modul operasional (`generateUUID()`), mengeliminasi penolakan tipe data Postgres `22P02`.
    - [x] **Engine Migrasi Otomatis Local Storage (`autoMigrateLegacyLocalStorage`):** Inisialisasi otomatis yang mendeteksi ID lama non-UUID pada cache browser, memperbarui ke RFC UUID, dan menyinkronkan data kembali ke Supabase DB.
    - [x] **Realtime CDC & Broadcast Hub (11 Tabel Operasional):** Pelacak perubahan live WebSocket untuk `jadwal_shalat_petugas`, `dapur_makan_siang`, `masjid_assets`, `financial_journals`, `budget_requests`, `santri_data`, `santri_mutabaah`, `musafir_logbook`, `security_reports`, `cleaning_reports`, dan `homepage_media`.
    - [x] **PJ Ibadah & Acara (SELESAI):** Kalibrasi Menit Ikhtiyat Shalat, Rotasi Petugas Harian (Imam 5 Waktu, Muadzin, Khatib, Bilal), Approval Batch DKM, tombol Simpan & Terbitkan Langsung ke Web, Kalender Acara/Kajian Tematik & Arsip Khutbah (`#tab-ibadah`).
    - [x] **Modul 1 — PJ Media & Dakwah (SELESAI):** Article Studio Standar UMAR Travel & Visual Web Builder Beranda terhubung ke Supabase `artikel_berita` & `homepage_media` (`#tab-articles`, `#tab-media` & `#tab-gallery`).
    - [x] **Modul 2 — PJ Logistik & Sarpras (SELESAI):** Dapur Sedekah Makan Ba'da Dzuhur (`dapur_makan_siang`) & Manajemen Inventaris Aset Fisik Masjid (`masjid_assets`) dengan RFC UUID (`#tab-logistik`).
    - [x] **Modul 3 — PJ Keuangan (Bendahara - SELESAI):** Jurnal Buku Kas Masuk & Kas Keluar (`financial_journals`), Alur Pengajuan Anggaran (*Budget Request*) & Klaim Nota Bon (*Reimbursement*) (`budget_requests`) dengan pemisahan approval DKM vs pencairan kasir, proteksi skema & integritas rollback transaksional, serta Subview Laporan Laba Rugi (Surplus / Defisit) interaktif berstandar ISAK 35 dengan visualisasi Chart.js dan fitur Cetak/Ekspor PDF resmi DKM (`#tab-donations`).
    - [x] **Modul 4 — PJ Santri & Pendidikan (SELESAI):** Direktori Santri Tahfidz (`santri_data`) & Log Mutaba'ah Setoran Hafalan Qur'an Harian (`santri_mutabaah`) dengan foreign key relasi RFC UUID valid (`#tab-santri`).
    - [x] **Modul 5 — PJ Musafir & Pelayanan (SELESAI):** Buku Tamu Musafir Digital, Tamu Menginap / Istirahat Darurat 24 Jam, dan Log Penitipan Kendaraan/Loker (`musafir_logbook`) dengan RFC UUID (`#tab-musafir`).
    - [x] **Modul 6a — PJ Keamanan & Ketertiban (SELESAI):** Log Piket Ronda Keamanan 24 Jam & Laporan Kejadian Lapangan (`security_reports`) dengan RFC UUID & penanganan constraint aman (`#tab-keamanan`).
    - [x] **Modul 6b — PJ Kebersihan & Sanitasi (SELESAI):** Checklist Sanitasi Harian Seluruh Zona Lingkungan Masjid (`cleaning_reports`) dengan RFC UUID (`#tab-kebersihan`).
    - [x] **Halaman Matriks QA & Testing Suite (`testing-suite.html` - SELESAI):** Portal pengujian terpadu seluruh modul operasional, verifikasi ketat hak akses RBAC seluruh PJ divisi, counter KPI live, dan fitur ekspor laporan.
  - [x] **Modul Pengajuan Izin & Cuti Pengurus DKM (Leave & Absence Management Suite - SELESAI):**
    - **Formulir Pengajuan Izin Mandiri (Seluruh Pengurus):** Formulir izin sakit, keperluan pribadi, tugas luar, cuti operasional terhubung ke `dkm_leave_requests`.
    - **Alur Persetujuan Terpusat (Approval Flow):** Panel khusus bagi **Ketua DKM & Super Admin** untuk approval permohonan izin dengan penunjukan petugas pengganti piket.
    - **Papan Ketersediaan Tim & Popup Pengganti Piket:** Widget status pengurus izin hari ini serta popup penugasan saat login.
  - [x] **Pemantau Kesehatan Arsitektur 7 Pilar Cloud (Khusus Super Admin - Benchmark SIABE-PORTO):**
    - Multi-Cloud Free-Tier Monitor: Dashboard pemantauan kuota 7 pilar (Supabase, Resend, Vercel, ImageKit, GitHub Actions, Cloudflare, Google Drive).
    - Kalkulasi dinamis total records database `{ count: 'exact', head: true }` dan estimasi ukuran DB Postgres MB.
  - [x] **Ekspor Laporan Kinerja PDF Mandiri per Anggota Tim DKM:**
    - Format PDF standar Web Landscape (`jsPDF v2.5.1`), lazy-load CDN.
    - Laporan multi-halaman: header brand Charcoal+Gold, 4 KPI cards global, tabel ringkasan kinerja per PIC, daftar tugas aktif per divisi, footer confidential.
    - Data bersumber langsung dari `getFilteredTasks(false)` — zero hardcode, terhubung Supabase live.

---

### Fase 5: Pengujian Terpadu, Audit Keamanan & UAT
- **Status:** Selesai (100%)
- **Daftar Tugas:**
  - [x] **Unit & Accuracy Testing:** Hisab shalat lokal vs kalender resmi Kemenag Kota Bekasi.
  - [x] **Form & Security Testing:** Validasi sanitasi form, pencegahan SQLi/XSS, dan audit Zero-Trust RLS Supabase.
  - [x] **Cross-Device & Mobile Performance Testing:** Uji responsif dan kelancaran touch pada Android (layar 360px–430px) dan iPhone.
  - [x] **UAT Pengurus DKM:** Simulasi alur kerja 10 peran pengurus via smartphone di lapangan.

---

### Fase 6: Finalisasi Produksi, SEO, Migrasi Domain ke masjidsophia.com & Go-Live
- **Status:** 95% Selesai
- **Prasyarat & Jadwal Eksekusi:** Migrasi domain dieksekusi **SETELAH** seluruh setup portal admin (`admin.html`) dan portal publik (`index.html`, `artikel.html`, `galeri.html`) selesai dibangun, diuji, dan dipublikasikan ke branch `main` produksi melalui domain awal (`masjidsophiajatiwarna.com`) untuk memastikan kestabilan sistem terlebih dahulu.
- **Daftar Tugas:**
  - [x] **Email Routing & SMTP Gateway Awal:** Cloudflare Email Routing & Resend SMTP aktif untuk domain awal.
  - [x] **SEO Dasar:** Berkas `robots.txt` dan `sitemap.xml` terpasang.
  - [x] **Halaman Error Kustom `404.html`:** Halaman 404 bertema terang resmi Sophia — ikon Font Awesome masjid, ayat Al-Qur'an (Al-Baqarah: 186), tombol kembali beranda & jadwal shalat, quick links galeri/artikel/donasi. Terdaftar di `vercel.json` blok `errors`.
  - [x] **SEO Lanjutan — Twitter Card seluruh halaman publik:** `twitter:card summary_large_image`, `twitter:title`, `twitter:description`, `twitter:image` ditambahkan di `index.html`, `galeri.html`, `artikel.html`, `artikel-detail.html`. OG locale & site_name dilengkapi.
  - [x] **SEO Lanjutan — Schema.org JSON-LD:** `Mosque` JSON-LD di `index.html`, `CollectionPage` di `galeri.html`, `Blog` di `artikel.html`, `NewsArticle` dinamis di `artikel-detail.html` (diperbarui JS setiap kali artikel dimuat).
  - [x] **Pendaftaran Mesin Pencari & Sitemap:** Google Search Console & Bing Webmaster Tools untuk domain baru `masjidsophia.com` (Selesai diverifikasi via DNS TXT dan sitemap.xml sukses dikirimkan).
  - [x] **Cloudflare Web Analytics:** Integrasi beacon script resmi Cloudflare bebas cookie pada seluruh halaman publik (`index.html`, `artikel.html`, `artikel-detail.html`, `galeri.html`, `404.html`, `maintenance.html`).
  - [x] **Eksekusi Migrasi Domain Utama ke masjidsophia.com (Arsitektur 7 Pilar):**
    - [x] **Pilar 1 - GitHub:** Repositori tetap di `web-masjid-sophia-jatiwarna`, author resmi `Masjid Sophia <masjidsophiajatiwarna@gmail.com>`.
    - [x] **Pilar 2 - Cloudflare DNS & Proxy:** Setup DNS Zone `masjidsophia.com`, SSL/TLS Full Strict, CNAME root & www ke `cname.vercel-dns.com`, MX & SPF Cloudflare Email Routing.
    - [x] **Pilar 3 - Email Resmi (Resend & Cloudflare Email Routing):** Domain sending baru `masjidsophia.com` di Resend (DKIM, SPF), forwarding Cloudflare Email Routing otomatis ke email dasar `masjidsophiajatiwarna@gmail.com` untuk 4 alamat (`aspirasi@`, `info@`, `saran@`, `pengaduan@`), serta Gmail "Send mail as" aktif untuk `info@` & `aspirasi@`.
    - [x] **Pilar 4 - Vercel Hosting:** Penambahan custom domains (`masjidsophia.com`, `admin.masjidsophia.com`, `progdev.masjidsophia.com`) dengan status valid di Vercel Dashboard.
    - [x] **Pilar 5 - Supabase Backend:** Pembaruan Site URL (`https://admin.masjidsophia.com`) & Redirect URLs (`https://masjidsophia.com/**`, `https://admin.masjidsophia.com/**`, `https://progdev.masjidsophia.com/**`) di Supabase Auth Settings.
    - [x] **Pilar 6 - ImageKit.io CDN:** Endpoint CDN `https://ik.imagekit.io/masjidsophia` siap melayani domain baru tanpa hambatan CORS.
    - [x] **Pilar 7 - Environment Variables & Codebase:** Sinkronisasi berkas `.env`, Vercel Project Environment Variables (`SITE_URL`, `RESEND_FROM_EMAIL`), pembaruan footer `index.html` (`info@masjidsophia.com`), kotak aspirasi (`aspirasi@masjidsophia.com`), `api/send-receipt.js`, `api/pengaduan.js`, `vercel.json`, `robots.txt`, dan `sitemap.xml`.
    - [x] **Pilar 8 - SEO Link Equity & 301 Redirect:** Aturan HTTP 301/308 Permanent Redirect dari `masjidsophiajatiwarna.com/*` ke `https://masjidsophia.com/$1` aktif di Cloudflare Redirect Rules (teruji preserve path 100%).
    - [x] **Pilar 9 - Integritas Akun & Kepemilikan Tetap:** Kepemilikan akun inti (GitHub, Cloudflare, Vercel, Resend, Supabase) tetap menggunakan akun yang sudah ada (`masjidsophiajatiwarna@gmail.com`), tanpa transfer akun yang berisiko.
  - [x] **IndexNow Instant Search Engine Indexing (Bing, Yandex & IndexNow Protocol):** Berkas kunci verifikasi domain `3c0606547e9f4e598bddd982c65cf8f0.txt` di root direktori, endpoint serverless `/api/indexnow` untuk integrasi otomatis/webhook, serta skrip CLI `scripts/submit_indexnow.py` yang sukses memvalidasi dan mengirimkan sitemap URL dengan respon HTTP 202 (Accepted) dari Microsoft Bing dan IndexNow.org.

---

### Panduan Teknis 1-by-1 Coaching: Eksekusi Migrasi Domain ke masjidsophia.com

Modul coaching ini dieksekusi secara interaktif melalui protokol **Grill-Me & 1-by-1 Coaching** sebelum dan selama setiap konfigurasi:

#### Langkah 1: Persiapan Domain & Cloudflare DNS
1. Buka dashboard Cloudflare (`dash.cloudflare.com`) -> Pastikan domain `masjidsophia.com` berada pada status **Active**.
2. Di tab **DNS Records** Cloudflare untuk `masjidsophia.com`, buat entri CNAME yang mengarah ke Vercel:
   - `CNAME` | `@` (root) -> `cname.vercel-dns.com` (Proxy: ON / Orange Cloud)
   - `CNAME` | `www` -> `cname.vercel-dns.com` (Proxy: ON)
   - `CNAME` | `admin` -> `cname.vercel-dns.com` (Proxy: ON)
   - `CNAME` | `progdev` -> `cname.vercel-dns.com` (Proxy: ON)
   - `CNAME` | `dev` -> `cname.vercel-dns.com` (Proxy: ON)
3. Di tab **SSL/TLS**, pastikan mode enkripsi disetel ke **Full (Strict)** dan aktifkan **Always Use HTTPS**.

#### Langkah 2: Setup Email Routing Cloudflare & Resend SMTP
1. **Cloudflare Email Routing (Inbound Forwarding):**
   - Di zone `masjidsophia.com`, buka menu **Email** -> **Email Routing** -> Klik **Enable Email Routing**.
   - Cloudflare akan meminta penambahan record DNS MX dan TXT SPF secara otomatis (klik **Add records automatically**).
   - Buat 4 Destination Rules / Custom Addresses:
     - `aspirasi@masjidsophia.com` -> arahkan ke `masjidsophiajatiwarna@gmail.com`
     - `info@masjidsophia.com` -> arahkan ke `masjidsophiajatiwarna@gmail.com`
     - `saran@masjidsophia.com` -> arahkan ke `masjidsophiajatiwarna@gmail.com`
     - `pengaduan@masjidsophia.com` -> arahkan ke `masjidsophiajatiwarna@gmail.com`
   - Buka inbox `masjidsophiajatiwarna@gmail.com` dan klik tautan verifikasi jika diminta oleh Cloudflare.
2. **Resend.com (Pengiriman Email Keluar / Transactional SMTP):**
   - Buka dashboard Resend (`resend.com/domains`) -> Klik **Add Domain** -> Masukkan `masjidsophia.com`.
   - Salin record verifikasi yang diberikan Resend (1 record MX, 1 record TXT SPF, dan 3 record TXT DKIM `resend._domainkey`).
   - Masukkan seluruh record tersebut ke DNS Cloudflare `masjidsophia.com` (Proxy: DNS Only / Grey Cloud).
   - Klik **Verify DNS Records** di Resend hingga status menjadi **Verified**.
   - Pada pengaturan *Sender email address*, setel ke `info@masjidsophia.com`.

#### Langkah 3: Konfigurasi Custom Domain di Vercel
1. Buka dashboard Vercel (`vercel.com`) -> Pilih proyek `web-masjid-sophia-jatiwarna` -> Buka tab **Settings** -> **Domains**.
2. Klik **Add Domain** dan daftarkan domain-domain berikut:
   - `masjidsophia.com` (Pilih opsi: Assign to `main` branch, dan centang redirect otomatis dari `www.masjidsophia.com`).
   - `admin.masjidsophia.com` (Assign to `main` branch).
   - `progdev.masjidsophia.com` (Assign to `main` branch).
   - `dev.masjidsophia.com` (Assign to `dev` branch).
3. Pastikan indikator status di Vercel berubah menjadi centang hijau **Valid Configuration**.

#### Langkah 4: Pembuatan Aturan 301 Permanent Redirect di Cloudflare (Domain Lawas ke Baru)
1. Buka zone domain lawas `masjidsophiajatiwarna.com` di Cloudflare.
2. Buka menu **Rules** -> **Redirect Rules** (atau **Page Rules**) -> Klik **Create Rule**.
3. Beri nama: `Redirect masjidsophiajatiwarna.com to masjidsophia.com (301)`.
4. Kriteria pencocokan (Expression):
   - `Incoming Request` -> `Hostname` equals `masjidsophiajatiwarna.com` ATAU `www.masjidsophiajatiwarna.com`
5. Target URL:
   - Type: `Dynamic`
   - Expression: `concat("https://masjidsophia.com", http.request.uri.path)`
   - Status Code: `301 (Moved Permanently)`
6. Ulangi aturan redirect serupa untuk subdomain:
   - `admin.masjidsophiajatiwarna.com/*` -> `https://admin.masjidsophia.com/$1`
   - `progdev.masjidsophiajatiwarna.com/*` -> `https://progdev.masjidsophia.com/$1`

#### Langkah 5: Penyelarasan Supabase Auth & Redirect URLs
1. Buka Supabase Dashboard (`supabase.com/dashboard`) -> Pilih proyek Masjid Sophia -> Buka **Authentication** -> **URL Configuration**.
2. **Site URL:** Ubah dari `https://admin.masjidsophiajatiwarna.com` menjadi `https://admin.masjidsophia.com` (atau `https://masjidsophia.com`).
3. **Redirect URLs (Allow list):** Tambahkan entri baru:
   - `https://masjidsophia.com/**`
   - `https://admin.masjidsophia.com/**`
   - `https://progdev.masjidsophia.com/**`
   - `https://dev.masjidsophia.com/**`
   - `http://localhost:3000/**`
4. Jika Google OAuth aktif, buka Google Cloud Console -> Credentials -> Authorized redirect URIs -> Tambahkan URI baru dari Supabase.

#### Langkah 6: Penyelarasan ImageKit.io CDN
1. Buka dashboard ImageKit.io (`imagekit.io`) -> Buka **Settings** -> **External Storage / Origin**.
2. Jika ada Web Proxy Origin atau URL whitelisting, perbarui ke domain `https://masjidsophia.com`.
3. Di menu **Security** -> **Allowed Domains / CORS**, tambahkan `https://masjidsophia.com` dan `https://admin.masjidsophia.com`.

#### Langkah 7: Pembaruan Environment Variables & Deploy Ulang
1. Di Vercel Settings -> **Environment Variables**, perbarui variabel:
   - `SITE_URL` = `https://masjidsophia.com`
   - `RESEND_FROM_EMAIL` = `Masjid Sophia <info@masjidsophia.com>`
2. Lakukan deployment ulang (*Redeploy*) di Vercel agar fungsi serverless membaca konfigurasi variabel lingkungan yang baru.

#### Langkah 8: Pengujian & Validasi Kestabilan
1. Uji akses domain baru `https://masjidsophia.com/` dan `https://admin.masjidsophia.com/`.
2. Uji redirect otomatis dari domain lawas: akses `https://masjidsophiajatiwarna.com/jadwal` -> pastikan langsung terlempar ke `https://masjidsophia.com/jadwal` dengan status HTTP 301.
3. Uji pengiriman formulir pengaduan & kontak: pastikan email notifikasi terkirim via `info@masjidsophia.com` dan diterima di inbox DKM.
4. Uji login admin di `https://admin.masjidsophia.com/` dan fungsi Realtime Supabase.

#### Langkah 9: Panduan Transfer Kepemilikan & Akses Akun (Handover)
1. **GitHub:** Repositori `web-masjid-sophia-jatiwarna` dapat diundang anggota tim DKM lain via Settings -> Collaborators, atau dipindahkan (*Transfer Ownership*) ke organisasi resmi DKM.
2. **Cloudflare:** Settings -> Members -> Invite `masjidsophiajatiwarna@gmail.com` sebagai Super Administrator.
3. **Vercel & Supabase:** Invite email DKM sebagai Project Member / Owner.

---

### Fase 7: Pipeline Aplikasi Mobile Android (.apk) & PWA Khusus Pengurus DKM (BARU)
- **Status:** Rencana Lanjutan
- **Tujuan:** Menyediakan aplikasi mobile mandiri yang ringan, cepat dibuka, dan siap pakai di smartphone Android seluruh jajaran pengurus DKM.
- **Strategi Penerapan 3 Tingkat:**
  - [ ] **Tingkat 1 - PWA (Progressive Web App):**
    - Pemasangan Service Worker untuk offline caching halaman statis dan aset ikon.
    - Integrasi `site.webmanifest` dengan orientasi `portrait-primary`, tema `#1D1D1B` & `#F8F6F0`.
    - Pengaktifan banner otomatis *"Pasang Aplikasi Portal DKM Sophia"* saat dibuka via browser Chrome/Safari.
  - [ ] **Tingkat 2 - TWA / WebAPK (`MasjidSophia-Admin.apk`):**
    - Pembangunan (*bundling*) installer mandiri format `.apk` khusus Android menggunakan Google Bubblewrap CLI / PWABuilder.
    - Berkas `MasjidSophia-Admin.apk` siap didistribusikan langsung ke grup WhatsApp pengurus DKM (tanpa perlu akun Play Store berbayar).
    - Mekanisme **Zero-Reinstall Auto-Sync**: Setiap ada pembaruan kode di web Vercel, aplikasi `.apk` di HP pengurus otomatis ter-update tanpa perlu instal ulang.
  - [ ] **Tingkat 3 - Native Wrapper (Capacitor.js - Fitur Khusus Hardware):**
    - Integrasi push notification tugas dan pesan chat internal via Firebase Cloud Messaging (FCM).
    - Akses kamera native instan untuk PJ Keamanan & Kebersihan saat unggah laporan lapangan.
    - Opsi login biometrik (sidik jari / fingerprint) untuk kemudahan akses akun admin.
  - [ ] **Kebijakan Ekosistem iOS & Aplikasi Jamaah:**
    - **Pengguna iPhone (iOS):** Menggunakan fitur PWA (*Add to Home Screen*) yang bebas biaya tahunan Apple Developer ($99/thn).
    - **Aplikasi Mobile Khusus Jamaah:** Berstatus *Coming Soon / Pasca-Peluncuran* (kebutuhan jamaah saat ini terpenuhi secara optimal melalui web responsif `index.html`).

---

## 4. Matriks Kewenangan Fitur Berdasarkan Peran (RBAC 10 Peran)

| Modul / Fitur Sistem | Super Admin | Ketua DKM | PJ Media | PJ Logistik | PJ Santri | PJ Musafir | PJ Ibadah | PJ Keuangan | PJ Keamanan | PJ Kebersihan |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Konfigurasi Sistem & API** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Manajemen Pengguna DKM** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Task Management (5 View)** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |
| **Riwayat Pengelolaan Realtime** | Penuh+Hapus | Baca | Baca | Baca | Baca | Baca | Baca | Baca | Baca | Baca |
| **Chat Koordinasi Multi-Arah** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |
| **Pengajuan Izin & Cuti Pengurus** | Penuh | Penuh | Request | Request | Request | Request | Request | Request | Request | Request |
| **Publish Artikel & Berita (CMS)** | Penuh | Review | Penuh | Tidak | Tidak | Tidak | Input Kajian | Tidak | Tidak | Tidak |
| **Pengatur Beranda (Self-Sustain)** | Penuh | Review | Penuh | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Logistik Makan & Aset Masjid** | Penuh | Laporan | Tidak | Penuh | Tidak | Tidak | Tidak | Laporan | Tidak | Tidak |
| **Data Santri & Mutaba'ah Tahfidz** | Penuh | Laporan | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Buku Tamu Musafir & Loker 24 Jam** | Penuh | Laporan | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Baca | Baca |
| **Kalibrasi Shalat & Rotasi Petugas** | Penuh | Persetujuan | Baca | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak |
| **Akuntansi, Kas & Budget Request** | Penuh | Penuh | Request | Request | Request | Request | Request | Penuh | Request | Request |
| **Report Keamanan & Upload Bukti** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh | Tidak |
| **Report Kebersihan & Upload Bukti** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh |
| **Monitor 7 Pilar Cloud (Super Admin)** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **PWA & Akses Mobile App APK** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |

---

## 5. Dependensi Pustaka CDN Eksternal

| Pustaka | Versi | Sumber CDN | Kegunaan |
| :--- | :--- | :--- | :--- |
| `@supabase/supabase-js` | `v2` | jsDelivr | Autentikasi, Database Postgres, Realtime WebSocket CDC |
| `frappe-gantt` | `0.6.1` | jsDelivr | Timeline Gantt Chart visual interaktif |
| `quill` | `1.3.6` | CDNjs | WYSIWYG Rich Text Editor untuk Article Studio |
| `jsPDF` | `2.5.1` | CDNjs | Generator Dokumen Laporan Kinerja & Keuangan PDF |
| `@capacitor/core` & `@capacitor/android` | `v5+` | npm / CDN | Native Wrapper Android APK & Hardware Access |
| `Plus Jakarta Sans` / `Inter` | Standar | Google Fonts | Tipografi antarmuka modern |
| `Amiri` | Standar | Google Fonts | Tipografi ayat Al-Qur'an, hadits, dan doa Arab |
| `Font Awesome` | `6.5.1` | CDNjs | Sistem ikon vektor monokrom (Strict No-Emoji) |

---

## 6. Matriks Verifikasi 21 Poin Perbaikan Sistem (v5.8 - Status: 100% Selesai)

| No | Poin Masalah / Perbaikan | Komponen / Modul | Status Teknis & Solusi |
| :---: | :--- | :--- | :--- |
| 1 | Modal dialog saling menumpuk / backdrop lumpuh | `admin.html` (`#modal-cover-preview`) | **SELESAI** — Menutup tag `</div>` unclosed pada baris 7558. Seluruh modal pulih. |
| 2 | Error console modal Dapur, Aset, Santri, Mutaba'ah | `admin.html` (5 modal markup) | **SELESAI** — Menginjeksi 5 modal form lengkap: `#modal-dapur-entry`, `#modal-asset-entry`, `#modal-asset-service`, `#modal-santri-entry`, `#modal-mutabaah-entry`. |
| 3 | Reorder hero slide error NOT NULL on 'judul' | `admin.html` (`moveHeroSlide`) | **SELESAI** — Mengganti klausa upsert parsial dengan 2 update atomik berbasis ID. |
| 4 | Unggah langsung ImageKit pada modal Hero Slide | `admin.html` (`#modal-hero-slide`) | **SELESAI** — Tombol unggah ImageKit WebP langsung di modal slide tanpa buka galeri dulu. |
| 5 | Perubahan nama menu sidebar Galeri Media | `admin.html` (`.sidebar-nav`) | **SELESAI** — Mengganti teks 'Galeri Media & WebP' menjadi 'Galeri Media'. |
| 6 | Kunci penutupan backdrop modal (klik luar) | `admin.html` (`closeModalOnBackdrop`) | **SELESAI** — Backdrop dismiss dinonaktifkan; modal hanya ditutup via tombol X atau Batal. |
| 7 | Kontras tombol Buka Tab Baru pada preview foto | `admin.html` (`#cover-modal-open-tab`) | **SELESAI** — Menerapkan gaya kontras gelap elegan (`#1D1D1B`, teks `#FFFFFF`). |
| 8 | Logo Masjid Sophia terpotong pada mobile | `index.html` (Navbar CSS) | **SELESAI** — Proteksi CSS `max-height: 40px`, `object-fit: contain`, dan padding terukur. |
| 9 | Filter kategori galeri merusak layout mobile | `galeri.html` (Filter Bar) | **SELESAI** — Dropdown seleksi fluid adaptif aktif pada layar $\le$ 640px. |
| 10 | Tombol Home tidak ada di navbar mobile artikel | `artikel.html`, `artikel-detail.html` | **SELESAI** — Tombol ikon Beranda (`fa-house`) disuntikkan di bilah navbar mobile. |
| 11 | Live preview builder mentah / tidak realistis | `admin.html` (`#builder-preview-screen`) | **SELESAI** — Rombak ke high-fidelity showcase dengan jadwal shalat, mini sedekah makan, dan warta. |
| 12 | Super Admin Task Management terlihat kosong | `admin.html` (`initAdminApp`) | **SELESAI** — Default filter divisi Super Admin dan Ketua DKM diset ke `'ALL'`. |
| 13 | Tombol Ajukan Izin / Cuti tidak dapat diklik | `admin.html` (`#modal-leave-request`) | **SELESAI** — Pulih normal seiring perbaikan penutupan tag modal dialog. |
| 14 | Gambar terhapus di admin belum terhapus di CDN | `api/imagekit-delete.js`, `admin.html` | **SELESAI** — Serverless endpoint Vercel relay ke REST API resmi ImageKit CDN. |
| 15 | Menu Galeri persisten saat logout & login role lain | `admin.html` (`handleLogout`, `switchTab`) | **SELESAI** — Hapus session hash URL (`#logistik`) dan pasang strict role gate pada tab gallery. |
| 16 | Standardisasi Nomenklatur Makan Berjamaah Gratis | Universal (HTML, JS, DB, Dokumen) | **SELESAI** — Seluruh istilah 'Sedekah Makan Dzuhur' diganti menjadi 'Makan Berjamaah Gratis'. |
| 17 | Sinkronisasi Supabase Realtime CDC modul PJ | Supabase DB & `admin.html` | **SELESAI** — Replikasi CDC aktif di `media_library`, fungsi delete periksa error Supabase. |
| 18 | Tombol Catat Sesi Dapur & Edit Log Dapur | `admin.html` (`openDapurModal`) | **SELESAI** — Formulir `#modal-dapur-entry` aktif penuh untuk catat dan edit log dapur. |
| 19 | Tombol Tambah Aset, Servis & Edit Barang | `admin.html` (`openAssetModal`, `openServiceModal`) | **SELESAI** — Modal registrasi aset dan riwayat servis berfungsi penuh. |
| 20 | Tombol Registrasi Santri Baru & Edit Profil | `admin.html` (`openSantriModal`) | **SELESAI** — Modal data santri aktif penuh dengan validasi form. |
| 21 | Tombol Input Setoran Hafalan & +Setor Khatam | `admin.html` (`openMutabaahModal`) | **SELESAI** — Modal pencatatan mutaba'ah hafalan aktif dan tersinkronisasi ke DB. |

---

## 7. Matriks Verifikasi 14 Poin Bug Journal Operasional (v6.0 - Status: 100% Selesai)

| No | Poin Bug / Temuan Lapangan | Berkas & Komponen | Resolusi Teknis & Status |
| :---: | :--- | :--- | :--- |
| 1 | Kartu Kajian Statis & Dummy di Beranda Publik | `index.html` (`#kajian-container`) | **SELESAI** — Menghapus kartu hardcoded, mengganti dengan pemanggil dinamis `loadKajianEvents()` dari Supabase status Approved, serta empty state informatif jika kosong. |
| 2 | Inkonsistensi Data Kajian (Supabase vs Lokal) | `index.html`, `admin.html` | **SELESAI** — Integrasi single source of truth ke tabel `kajian_acara_ibadah` dengan siaran WebSocket CDC Realtime. |
| 3 | Data Kajian Muncul di PJ Ibadah tapi Kosong di Superadmin | `admin.html` (`loadIbadahKajian`, `renderIbadahKajianTable`) | **SELESAI** — Menghapus fallback cache usang saat Supabase kosong, menyelaraskan pembacaan atribut kolom database. |
| 4 | Validasi Payload Submit Kajian Ibadah | `admin.html` (`handleIbadahKajianSubmit`) | **SELESAI** — Menyelaraskan nama atribut payload (`penceramah`, `tanggal`, `tempat_lokasi`, `kategori`, `waktu_mulai`, `waktu_selesai`) persis dengan skema Supabase. |
| 5 | Tabel Donasi Masuk Tidak Ada Aksi Verifikasi | `admin.html` (`#subview-keu-donasi`) | **SELESAI** — Menambahkan kolom Aksi dengan tombol Verifikasi, multi-checkbox seleksi, dan tombol Batch Approval "Verifikasi Terpilih". |
| 6 | Alur Otomatis Donasi Masuk ke Jurnal Kas | `admin.html` (`createAutoJournalForDonation`) | **SELESAI** — Donasi terverifikasi secara instan otomatis membukukan transaksi Kas Masuk pada tabel `financial_journals` dan realtime broadcast. |
| 7 | Crash Form Jurnal Transaksi Baru (TypeError: Cannot read properties of null) | `admin.html` (`#form-journal-entry`) | **SELESAI** — Menambahkan input hidden `#journal-form-kode` pada form modal jurnal kas. |
| 8 | Crash Tombol Buat Pengajuan Baru (TypeError: Cannot set properties of null) | `admin.html` (`#form-budget-entry`) | **SELESAI** — Menambahkan input hidden `#budget-form-kode` pada form modal pengajuan anggaran. |
| 9 | Panduan Shift Keamanan Hardcoded & Istilah Usang | `admin.html` (`#subview-keamanan-jadwal`, `#modal-security-sop`) | **SELESAI** — Kartu shift dinamis dengan modal konfigurasi SOP, tersimpan ke Supabase `homepage_media` (kategori: `SECURITY_SOP_CONFIG`), dan pembersihan istilah menjadi 'Makan Berjamaah Gratis'. |
| 10 | Status Keamanan WASPADA Muncul Sebagai KONDUSIF | `admin.html` (`renderSecurityTable`, `renderInsidenTable`) | **SELESAI** — Menambahkan badge status khusus untuk WASPADA / PERHATIAN_KHUSUS dan penyelarasan filter. |
| 11 | Persentase Kondusif Nyangkut 50% pada KPI Keamanan | `admin.html` (`updateSecurityKpiStats`) | **SELESAI** — Kasus yang telah berstatus tindak lanjut SELESAI tidak lagi dihitung sebagai insiden aktif, metrik kondusif mencapai 100% saat tidak ada kasus aktif. |
| 12 | Sub-tab Stok Kebersihan Pasif Tanpa Opsi Tambah/Filter | `admin.html` (`#subview-kebersihan-stok`) | **SELESAI** — Menambahkan tombol '+ Catat Kebutuhan Stok', search input, dan filter zona lokasi. |
| 13 | Alur Pengajuan Anggaran untuk Kebutuhan Stok Sanitasi | `admin.html` (`forwardCleaningStockToBudget`) | **SELESAI** — Tombol 'Ajukan Anggaran' pada baris stok yang langsung membuka modal anggaran dengan divisi 'Kebersihan & Sanitasi', judul, dan rincian terisi otomatis. |
| 14 | Error HTTP 400 Bad Request pada Visual Web Builder | `admin.html` (`saveHomepageConfig`), `database/migration_20260909_bugjournal_fixes.sql` | **SELESAI** — Perluasan kolom database `action_link` ke `TEXT`, penambahan kolom `meta_json JSONB`, dan optimasi penyimpanan payload builder. |

---

## 8. Matriks Verifikasi 10 Poin Bug Journal Operasional v2 & Redesain UI (v6.1 - Status: 100% Selesai)

| No | Poin Masalah / Perbaikan | Berkas & Komponen | Resolusi Teknis & Status |
| :---: | :--- | :--- | :--- |
| 1 | Sinkronisasi tipe transaksi kas masuk/keluar tidak otomatis | `admin.html` (`#journal-form-tipe`) | **SELESAI** — Menambahkan handler `onchange="handleJournalTypeChange(this.value)"` pada elemen select. Kategori transaksi otomatis berpindah dan sinkron seketika saat tipe berubah. |
| 2 | Error referensi kode pengajuan di modal review anggaran | `admin.html` (`#modal-budget-review`) | **SELESAI** — Menambahkan elemen `<span id="review-budget-kode">` di dalam modal review sehingga kode pengajuan ditampilkan dengan jelas tanpa error referensi DOM. |
| 3 | Evaluasi persetujuan dan pencairan anggaran hanya di modal review | `admin.html` (`#modal-budget-entry`, `handleBudgetEntrySubmit`) | **SELESAI** — Menambahkan blok `#budget-form-approver-box` pada formulir edit pengajuan bagi Approver (`SUPER_ADMIN`, `KETUA_DKM`, `PJ_KEUANGAN`) dan mengintegrasikan auto-disbursement kas keluar ke `financial_journals` saat dicairkan. |
| 4 | Subview stok kebersihan terpisah dan redundan | `admin.html` (`#subview-kebersihan-stok`) | **SELESAI** — Menghapus tab dan pane subview stok kebersihan yang redundan untuk menyederhanakan antarmuka modul Sanitasi Kebersihan. |
| 5 | Tombol pengajuan anggaran stok kebersihan tidak langsung | `admin.html` (`openAddCleaningStockToBudgetModal`) | **SELESAI** — Menambahkan tombol langsung "Ajukan Anggaran Stok" yang membuka modal pengajuan anggaran dengan divisi default 'Kebersihan & Sanitasi' dan rincian terformat. |
| 6 | Label panel Kas Masjid memuat teks redundan | `admin.html` (`#tab-donations` header) | **SELESAI** — Menghapus teks `(*Budget Request*)` pada header panel Kas Masjid & Infaq agar judul bersih dan rapi. |
| 7 | Ikon kategori pada grup sidebar membuat visual padat | `admin.html` (`SIDEBAR_MENU_GROUPS`) | **SELESAI** — Menghapus ikon kategori dari header grup menu di seluruh konfigurasi sidebar untuk menciptakan tampilan yang tenang dan profesional. |
| 8 | Label grup media dan cloud monitor kurang selaras | `admin.html` (`SIDEBAR_MENU_GROUPS`) | **SELESAI** — Mengubah grup `MEDIA & KEUANGAN` menjadi `MEDIA & WARTA MASJID`, serta membersihkan teks `(7 Pilar)` pada menu Cloud Monitor. |
| 9 | PJ divisi lain tidak dapat mengakses menu pengajuan anggaran (Alert Akses Ditolak) | `admin.html` (`switchTab`, `loadKeuanganData`, `switchKeuanganSubView`) | **SELESAI** — Menghapus pembatasan peran `switchTab('donations')`, mengunci otomatis seluruh PJ non-keuangan khusus ke subview Pengajuan Anggaran (`budget`) dengan menyembunyikan tab jurnal dan donasi, serta menampilkan label sidebar dinamis "Pengajuan Anggaran". |
| 10 | Sidebar desktop 100% terpotong dan sesak (Benchmark ERP Umar) | `admin.html` (CSS `.admin-sidebar`, `.nav-item-btn`, layout) | **SELESAI** — Memperlebar sidebar ke 275px (`admin-main` margin 275px), menghapus `white-space: nowrap` dan text truncation `...`, menambah `line-height: 1.35`, menyederhanakan nama menu panjang, dan memperluas vertical gap agar rapi dan mudah dibaca setara ERP Umar. |
| 11 | Hero slider kartu box beranda & widget dock shalat kurang rapih | `index.html` (CSS `.hero-slider-nav`, `.hero-prayer-dock`, HTML `#beranda`) | **SELESAI** — Mengangkat slider dots ke `bottom: 5.75rem` di dalam kapsul kaca mandiri berbingkai emas, merapikan kartu jam hitung mundur 2-kolom, dan menata petugas ibadah ke dalam badge mini terpisah dengan pemisah visual yang simetris. |
| 12 | Kas keluar tercatat prematur saat baru disetujui DKM & risiko duplikasi pencatatan | `admin.html` (`handleBudgetReviewSubmit`, `#modal-budget-disburse`, `handleBudgetDisburseSubmit`) | **SELESAI** — Memisahkan alur persetujuan DKM (`APPROVED_DKM`, tanpa mutasi kas keluar) dari alur pencairan uang kasir/accounting (`DISBURSED`), menambahkan modal khusus `#modal-budget-disburse`, tombol aksi "Cairkan Kas", serta proteksi idempotensi ketat anti-duplikasi jurnal kas. |
| 13 | Error skema `budget_request_id` pada Supabase saat pencairan kas keluar & status macet di Dana Dicairkan | `admin.html` (`handleBudgetDisburseSubmit`), Supabase DB (`budget_requests`) | **SELESAI** — Menghapus kolom non-eksisten `budget_request_id` dari payload `financial_journals`, menyematkan kode pengajuan pada `deskripsi` dan `disbursed_journal_code`, menerapkan transactional rollback safeguard (proses dibatalkan jika insert jurnal gagal), serta mereset record `REQ-2026-002` ke status `APPROVED_DKM`. |
| 14 | Ketiadaan Laporan Laba Rugi (Surplus / Defisit) interaktif, grafik Chart.js, dan tombol Ekspor PDF | `admin.html` (`#subview-keu-labarugi`, `renderLabaRugiReport`, `printLabaRugiReport`, `exportLabaRugiToCSV`, Chart.js CDN) | **SELESAI** — Menambahkan Subview 4 "Laporan Laba Rugi (Surplus / Defisit)" berstandar ISAK 35, 4 kartu KPI eksekutif, grafik batang komparasi Kas Masuk vs Kas Keluar, grafik donat beban kategori operasional, tabel rincian pendapatan & beban dengan subtotal, serta tombol Ekspor CSV dan Cetak PDF resmi ber-Kop DKM Masjid Sophia Jatiwarna lengkap dengan blok tanda tangan digital. |

---

## 9. Matriks Verifikasi Bug Race Condition Kas Keluar & Eliminasi Tombol Refresh Hardcoded (v6.3)

### Analisis Akar Masalah: Mengapa Muncul Duplikasi Pencatatan (2x di Tampilan)?
1. **Status Database Supabase:** Pengecekan langsung pada tabel `financial_journals` membuktikan bahwa data transaksi kas keluar pencairan `REQ-2026-002` hanya tersimpan **1 baris** (`id: 521700e9-67dc-4511-b29c-ba5fe48a9006`, nominal Rp 10.000, kode `TRX-OUT-001`). Tidak ada duplikasi data di database Supabase.
2. **Penyebab Duplikasi di Memori UI (*Race Condition*):**
   - Saat kasir/accounting mencairkan dana di `#modal-budget-disburse`, fungsi `handleBudgetDisburseSubmit(e)` memanggil `await sbClient.from('financial_journals').insert([journalRecord])`.
   - Begitu data ter-insert di Supabase, listener WebSocket Realtime CDC (`postgres_changes` pada tabel `financial_journals` di baris 11593) seketika aktif dan memicu `loadFinancialJournals()`.
   - Fungsi `loadFinancialJournals()` mengambil data dari Supabase via `SELECT *` yang sudah mencakup `TRX-OUT-001`, lalu mengisi array memori `financialJournalsList`.
   - Namun, fungsi `handleBudgetDisburseSubmit(e)` yang masih berjalan di latar depan kemudian mengeksekusi `financialJournalsList.unshift(journalRecord)` pada baris 21922.
   - Akibatnya, `journalRecord` dimasukkan untuk kedua kalinya ke dalam `financialJournalsList`. Fungsi `renderJournalsTable()` dan `updateJournalsKpiStats()` kemudian menghitung 2 baris `TRX-OUT-001` sehingga total kas keluar membengkak menjadi Rp 20.000.
   - Ketika halaman di-refresh via browser (F5), `financialJournalsList` di-load ulang murni dari Supabase sehingga tampilan kembali menjadi 1 baris (Rp 10.000).

### Analisis Akar Masalah: Mengapa Status 'Tunda / Perlu Kajian Lebih Lanjut' Tidak Berubah?
1. **Inkonsistensi Value `<option>`:** Pada form `#modal-budget-review` (baris 9312), pilihan "Tunda / Perlu Kajian Lebih Lanjut" memiliki atribut `value="PENDING"`.
2. **Inkonsistensi Label di Tabel:** Di fungsi `renderBudgetTable()` (baris 21373), status `'PENDING'` dirender dengan badge label `'Menunggu DKM'`.
3. **Akibat Lapangan:** Saat pengguna memilih "Tunda / Perlu Kajian Lebih Lanjut" lalu menyimpan keputusan, sistem menyimpan status `'PENDING'`. Karena tabel merender `'PENDING'` sebagai `'Menunggu DKM'`, tabel terlihat sama sekali tidak berubah dan tetap berstatus `'Menunggu DKM'`.
4. **Solusi:**
   - Pisahkan status pengajuan menjadi nilai unik:
     - `'PENDING'` -> **Menunggu Approval** (subteks: `Menunggu review`)
     - `'POSTPONED'` -> **Ditunda** (subteks: `Perlu dikaji lebih lanjut`)
     - `'APPROVED_DKM'` -> **Disetujui** (subteks: `Siap dicairkan`)
     - `'DISBURSED'` -> **Dana Telah Dicairkan** (subteks: `Kas Keluar YYYY-MM-DD`)
     - `'REJECTED'` -> **Ditolak** (subteks: `Tidak disetujui`)

### Alur Penyelesaian Teknis:
1. **Idempotensi In-Memory Sentral (`upsertJournalInMemory`):** Seluruh mutasi lokal jurnal kas diarahkan melalui fungsi pemeriksa duplikasi berbasis `id` dan `kode_transaksi`. Jika sudah ada (misal telah diisi lebih awal oleh Realtime CDC), lakukan penimpaan properti tanpa menambahkan baris baru.
2. **Filter Idempotensi pada `loadFinancialJournals` & Rendering:** Menambahkan proteksi `Set` unik untuk menyaring duplikat sebelum penyimpanan memori, rendering tabel, dan perhitungan KPI saldo kas.
3. **Penyempurnaan Form Evaluasi Pengajuan Anggaran (`#modal-budget-review`):**
   - Mengubah label field `Keputusan DKM` menjadi `'Status Pengajuan'`.
   - Menghapus seluruh teks di dalam tanda kurung pada opsi select sehingga hanya ada 4 pilihan:
     - `Tunda / Perlu Kajian Lebih Lanjut` (`value="POSTPONED"`)
     - `Disetujui` (`value="APPROVED_DKM"`)
     - `Ditolak` (`value="REJECTED"`)
     - `Dana Telah Dicairkan` (`value="DISBURSED"`)
4. **Pembaruan Badge & Filter Status Pengajuan Anggaran (`renderBudgetTable` & `#budget-status-filter`):**
   - Status baru `PENDING` menggunakan badge **Menunggu Approval** (menggantikan 'Menunggu DKM').
   - Status `POSTPONED` menggunakan badge **Ditunda** dengan subteks `Perlu dikaji lebih lanjut`.
   - Status `APPROVED_DKM` menggunakan badge **Disetujui** dengan subteks `Siap dicairkan`.
   - Status `DISBURSED` menggunakan badge **Dana Dicairkan** / **Dana Telah Dicairkan**.
   - Status `REJECTED` menggunakan badge **Ditolak**.
   - **Filter Status (`#budget-status-filter`):** Menghapus seluruh tanda kurung dari opsi dropdown filter sehingga tertulis bersih:
     - `Semua Status`
     - `Menunggu Approval`
     - `Ditunda`
     - `Disetujui`
     - `Dana Telah Dicairkan`
     - `Ditolak`
5. **Eliminasi Seluruh Tombol Refresh Hardcoded:** Menghapus 8 tombol refresh buatan di seluruh modul PJ (Keuangan, Donasi, Pengurus, Santri, Musafir, Keamanan, Kebersihan, Logistik), mengembalikan kebiasaan refresh murni ke browser (`F5` / `Ctrl+R`) didukung sinkronisasi otomatis Supabase Realtime WebSocket (CDC).

| No | Poin Masalah / Perbaikan | Berkas & Komponen | Resolusi Teknis & Status |
| :---: | :--- | :--- | :--- |
| 1 | Duplikasi pencatatan kas keluar in-memory saat pencairan anggaran (*race condition* CDC vs unshift) | `admin.html` (`handleBudgetDisburseSubmit`, `upsertJournalInMemory`, `loadFinancialJournals`) | **SELESAI (100% TERVERIFIKASI)** — Mengganti `unshift` dengan `upsertJournalInMemory`, menambahkan deduplikasi berbasis ID/kode transaksi pada `loadFinancialJournals`, `renderJournalsTable`, dan `updateJournalsKpiStats`. |
| 2 | Status 'Tunda / Perlu Kajian Lebih Lanjut' tidak berubah saat disimpan | `admin.html` (`#modal-budget-review`, `openReviewBudgetModal`, `handleBudgetReviewSubmit`, `renderBudgetTable`) | **SELESAI (100% TERVERIFIKASI)** — Memisahkan nilai status ke `POSTPONED`, menampilkan badge 'Ditunda' dengan subteks 'Perlu dikaji lebih lanjut'. |
| 3 | Teks dalam kurung pada field dan pergantian nama field ke 'Status Pengajuan' | `admin.html` (`#modal-budget-review`, `#modal-budget-entry`) | **SELESAI (100% TERVERIFIKASI)** — Mengubah label field menjadi 'Status Pengajuan', membersihkan tanda kurung dari opsi dropdown menjadi tepat 4 pilihan: Tunda / Perlu Kajian Lebih Lanjut, Disetujui, Ditolak, Dana Telah Dicairkan. |
| 4 | Pergantian badge 'Menunggu DKM' ke 'Menunggu Approval' & filter status bersih tanpa tanda kurung | `admin.html` (`renderBudgetTable`, `#budget-status-filter`) | **SELESAI (100% TERVERIFIKASI)** — Mengubah label badge status pengajuan baru dari 'Menunggu DKM' menjadi 'Menunggu Approval', serta memastikan seluruh opsi filter status bersih tanpa tanda kurung (Semua Status, Menunggu Approval, Ditunda, Disetujui, Dana Telah Dicairkan, Ditolak). |
| 5 | Tombol Refresh Keuangan hardcoded | `admin.html` (`#subview-keu-jurnal` nav) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-action-gold" onclick="loadKeuanganData(true)">` dari subview navigasi Keuangan. |
| 6 | Tombol Refresh Donasi hardcoded | `admin.html` (`#subview-keu-donasi` toolbar) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-action-gold" onclick="loadKeuanganData(true)">` dari toolbar tabel donasi. |
| 7 | Tombol Refresh Pengurus DKM hardcoded | `admin.html` (`#admin-users-table` toolbar) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-table-action" onclick="loadAdminUsers(true)">` dari toolbar direktori pengurus. |
| 8 | Tombol Refresh Santri hardcoded | `admin.html` (`#tab-santri` nav) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-action-gold" onclick="loadSantriData(true)">` dari subview navigasi Santri. |
| 9 | Tombol Refresh Musafir hardcoded | `admin.html` (`#tab-musafir` nav) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-action-gold" onclick="loadMusafirData(true)">` dari subview navigasi Musafir. |
| 10 | Tombol Refresh Keamanan hardcoded | `admin.html` (`#tab-keamanan` nav) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-action-gold" onclick="loadKeamananData(true)">` dari subview navigasi Keamanan. |
| 11 | Tombol Refresh Kebersihan hardcoded | `admin.html` (`#tab-kebersihan` nav) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-action-gold" onclick="loadKebersihanData(true)">` dari subview navigasi Kebersihan. |
| 12 | Tombol Refresh Logistik hardcoded | `admin.html` (`#tab-logistik` nav) | **SELESAI (100% TERVERIFIKASI)** — Menghapus tombol `<button class="btn-action-gold" onclick="loadLogistikData(true)">` dari subview navigasi Logistik. |
| 13 | Laporan keamanan berstatus 'Kondusif' tapi muncul di Insiden Eskalasi sebagai 'Waspada' | `admin.html` (`renderInsidenTable`) | **SELESAI (100% TERVERIFIKASI)** — Memperbaiki logika if-else badge pada tabel Insiden agar memprioritaskan kondisi `KONDUSIF` sebelum mencetak badge `WASPADA`. |
| 14 | Logika RBAC (Role-Based Access Control) pada "Status Tindak Lanjut" di modal Keamanan bocor | `admin.html` (`openEditSecurityModal`, `openAddSecurityModal`) | **SELESAI (100% TERVERIFIKASI)** — Menonaktifkan field status dan menyembunyikan "Catatan DKM" untuk PJ Keamanan jika status terkini adalah `ESKALASI_DKM` (Hanya DKM/Admin yang bisa edit). |
| 15 | Fitur Sakelar Status Live / Under Maintenance Terpadu, Supabase SSOT, & Pratinjau Tim Mandiri | `admin.html`, `maintenance.html`, `asset/js/env-loader.js` | **SELESAI (100% TERVERIFIKASI)** — Menyediakan sakelar status Live vs Maintenance di Visual Web Builder dengan proteksi wewenang RBAC (`SUPER_ADMIN`, `SUPER_USER`, `KETUA_DKM`, `PJ_MEDIA`), arsitektur murni Supabase SSOT bebas locking localStorage, tombol 'Buka Web Publik' dengan parameter `?preview=[role]` dan retensi sessionStorage, halaman kustom `maintenance.html` islami bebas emoji dengan kontak WhatsApp DKM & auto-reload realtime instan, serta indikator status mandiri berdenyut lembut di pojok kanan toolbar. |
| 16 | Resolusi Kerusakan Bersarang DOM (Unclosed Div) & Audit Aksesibilitas 18 Modul Portal Admin | `admin.html` (`#tab-kebersihan`, `#tab-logistik`, `#tab-ibadah`, `switchTab`) | **SELESAI (100% TERVERIFIKASI)** — Menutup tag kontainer `<div id="tab-kebersihan">` yang sebelumnya kehilangan tag penutup `</div>` pada baris 6753, mengeliminasi gejala layar putih kosong pada modul PJ Ibadah dan PJ Logistik. Memvalidasi seluruh 18 modul portal admin berada pada kedalaman tingkat utama (depth 5) secara mandiri dan seimbang. |



---

## FASE 4: UI/UX & Bug Fixing (Notifikasi, Mobile Menu, QRIS, & Formating)
**Tujuan:** Menyelesaikan catatan bug dan peningkatan antarmuka berdasarkan umpan balik pengguna.

### Daftar Pekerjaan:
1. **Bilah Button Notification Terpusat (dmin.html)**
   - Menambahkan icon notifikasi (a-bell) di pojok kanan atas 	op-app-bar.
   - Mengimplementasikan tampilan *dropdown* notifikasi kosong sementara (menyediakan slot untuk pengembangan fitur push notifikasi ke depannya).
2. **Tombol Menu Mobile / PWA (dmin.html)**
   - Menambahkan tombol *hamburger menu* (a-bars) di sebelah kiri judul pada 	op-app-bar yang khusus muncul di tampilan *mobile*.
   - Menghubungkannya dengan fungsi 	oggleSidebar() agar pengguna HP bisa membuka/menutup navigasi utama.
3. **Penyempurnaan Verifikasi Donasi & Tombol Reject (dmin.html)**
   - Mengubah *styling* tombol aksi "Verifikasi" di tabel donasi agar lebih interaktif dan berbentuk tombol (bukan sekadar teks).
   - Menambahkan tombol "Tolak" berwarna merah di sebelah tombol "Verifikasi".
   - Mengimplementasikan fungsi handleRejectSingleDonation(id) yang memunculkan prompt (atau *modal*) untuk meminta **Alasan Penolakan**.
   - Menyimpan status 'REJECTED' dan menambahkan catatan penolakan ke memori tabel atau *database* (opsional menambah kolom dmin_notes jika diizinkan).
4. **Pemasangan QRIS Masjid Resmi (index.html)**
   - Mengganti teks/placeholder QRIS di form donasi (halaman publik) dengan tag `<img>` yang memuat gambar QRIS Masjid resmi.
   - Karena keterbatasan akses API Key ImageKit di *environment local*, gambar akan disimpan dan dipanggil dari folder lokal (`asset/images/QRIS MASJID.jpeg`) terlebih dahulu. Jika nanti API key tersedia, bisa diupload terpisah.
5. **Perbaikan *Session Persistence* PWA/Desktop (admin.html)**
   - Mengatasi isu *logout* saat *refresh* dengan menyimpan sesi akun (`authUser`) ke dalam localStorage saat pengguna menggunakan jalur *fallback credential login* (benih akun master DKM).
   - Memastikan DOMContentLoaded mengecek *local storage* ini apabila `sbClient.auth.getSession()` dari Supabase gagal mengembalikan sesi.
6. **Pemformatan Angka Otomatis (*Thousand Separator*) (index.html)**
   - Mengubah form input nominal donasi agar otomatis memunculkan titik pemisah ribuan (contoh: 10.000) saat pengguna mengetik, sehingga mencegah kesalahan input jumlah nol.
7. **Penyempurnaan Lanjutan Berdasarkan Grill-Me & UAT:**
   - [x] **Perbaikan Tombol Aksi Tabel Donasi (`admin.html`):** Mengganti batasan 32x32px `.btn-action` dengan `.btn-donation-verify` dan `.btn-donation-reject` (width: auto, padding proporsional, flex-row berdampingan, min-width 175px).
   - [x] **Modal Tolak Donasi Kustom (`admin.html`):** Mengganti `prompt()` dengan modal bertema DKM Sophia (`#modal-reject-donation`) dilengkapi 3 preset alasan cepat + opsi "Lainnya" yang memunculkan textarea manual, serta sistem notifikasi toast (`showToast`).
   - [x] **Modal Lightbox Zoom QRIS (`index.html`):** Thumbnail QRIS diperbesar ke 110x110px dengan badge interaktif, terhubung ke popup lightbox fullscreen (`#qris-lightbox-modal`) lengkap dengan tombol unduh gambar (`download="QRIS-Masjid-Sophia-Jatiwarna.jpeg"`).
   - [x] **Resolusi Error Log 404 /config (`vercel.json`):** Menambahkan rewrite rule `/config` -> `/api/config` pada konfigurasi Vercel.
   - [x] **Resolusi Auth 422 (`admin.html`):** Membersihkan panggilan signUp otomatis yang gagal saat akun fallback master DKM digunakan.
   - [x] **Script SQL Migrasi Supabase:** Penyediaan `database/migration_update_donations_notes.sql` untuk penambahan kolom `admin_notes TEXT` pada tabel `donations`.

---

## FASE 4.1: Resolusi Responsif Mobile Viewport HP, Side Drawer & Eliminasi Overflow Visual Builder
**Status:** Selesai (100% Terverifikasi)  
**Tanggal Penyelesaian:** 2026-09-21  
**Target Viewport Uji:** Smartphone 395 x 824 px (Portrait) dan seluruh resolusi layar sempit (<= 900px, <= 640px).

### 1. Masalah yang Diselesaikan & Akar Masalah (Root Cause):
1. **Tombol Notifikasi Tergeser ke Bawah & Dropdown Terpotong ke Luar Layar:**
   - *Akar Masalah:* `.top-app-bar` menggunakan `flex-wrap: wrap;`. Judul halaman mengambil lebar 100%, mendesak tombol lonceng ke baris kedua di posisi `x = 0`. Dropdown menggunakan `position: absolute; right: 0; width: 320px;` sehingga terdorong 320px ke koordinat negatif kiri layar (hanya terlihat ujung kanannya).
   - *Solusi:* Layout diubah menjadi 1 baris sejajar (`flex-nowrap`), subjudul disembunyikan di mobile, judul utama dipangkas dengan elipsis, tombol lonceng terkunci di kanan atas, dan dropdown dibuat adaptif `position: fixed; left: 1rem; right: 1rem; max-width: 380px; margin: 0 auto; z-index: 10005;`.
2. **Sidebar Menu Tidak Muncul Saat Hamburger Diklik di Visual Web Builder:**
   - *Akar Masalah:* Navigasi tab (`switchTab`) tidak pernah membersihkan status class `.open` dari `.admin-sidebar` pada perangkat mobile saat berpindah tab. Akibatnya sidebar tetap berstatus "open" di DOM internal, dan klik hamburger berikutnya memicu event penutupan (toggle false). Tidak adanya backdrop overlay juga membuat penutupan drawer tidak intuitif.
   - *Solusi:* Dibuat arsitektur Side Drawer melayang dari kiri (`z-index: 10000; width: min(290px, 86vw)`) dengan backdrop gelap semi-transparan (`#sidebar-mobile-backdrop`, `z-index: 9998`), tombol tutup silang [X] pada header sidebar (`.btn-sidebar-mobile-close`), integrasi `toggleSidebarCollapse(false)` pada setiap event `switchTab()`, penguncian scroll body saat drawer terbuka, serta pembersihan otomatis via listener `resize`.
3. **Bagian Bawah Visual Web Builder Tembus ke Kanan (Horizontal Overflow / Zoom-Out):**
   - *Akar Masalah:* Kartu slide hero (`#hero-slides-admin-list`) menggunakan 1 baris flex kaku berisi thumbnail (85px) + teks info (flex:1) + 2 kolom tombol aksi (95px) dengan total min-width > 410px. Selain itu, input 3 kartu statistik di bawah hero dipaksa dalam grid 3 kolom (`1fr 1fr 1fr`). Hal ini menyebabkan lebar dokumen melampaui lebar viewport 395px, memicu scroll horizontal dan halaman bisa di-zoom out.
   - *Solusi:* Pertahanan viewport global anti-bleed (`html, body, .admin-layout, .admin-main { overflow-x: hidden; max-width: 100vw; min-width: 0; }`), restrukturisasi kartu slide hero menjadi responsif bertumpuk vertikal pada layar <= 640px (`.hero-slide-admin-item` dengan `.hero-slide-header-row` di atas dan `.hero-slide-actions` horizontal di bawah), serta transformasi grid input 3 statistik menjadi 1 kolom (`.builder-stat-grid { grid-template-columns: 1fr !important; }`).

### 2. Matriks Pengujian & Verifikasi:
- [x] Syntax checking inline JavaScript via Node.js: 0 errors terdeteksi pada 25.700+ baris kode `admin.html`.
- [x] Verifikasi layout Top App Bar 1 baris tanpa wrapping pada viewport <= 900px dan <= 640px.
- [x] Verifikasi dropdown notifikasi berada di tengah layar yang aman dan terbaca penuh.
- [x] Verifikasi Side Drawer meluncur mulus, backdrop menutup saat diklik, dan drawer otomatis tertutup saat menu navigasi diklik.
- [x] Verifikasi Visual Web Builder bebas scroll horizontal dan 100% responsif pada viewport 395x824px.

---

## FASE 4.2: Resolusi Zombie Tasks, Seleksi & Hapus Donasi, Respon Kotak Saran, dan Capaian Sedekah Makan Realtime
**Status:** Selesai (100% Terverifikasi)  
**Tanggal Penyelesaian:** 2026-09-21  

### 1. Masalah yang Diselesaikan & Solusi Arsitektural:
1. **Eliminasi Zombie Tasks & Stuck Bulk Toolbar (`admin.html`):**
   - *Akar Masalah:* `getLocalTasks()` mengembalikan `null` jika array kosong (`parsed.length === 0`), sehingga saat pengurus menghapus habis semua tugas dan me-refresh halaman, `allTasksList` mengambil fallback 9 tugas bawaan (`DEFAULT_SEED_TASKS`) lalu Supabase melakukan upsert ulang 9 tugas tersebut ke database. Selain itu, `renderMasterTable()` langsung keluar (`return;`) saat `tasks.length === 0` sebelum memanggil `updateBulkToolbarState()`, menyebabkan toolbar hitam tetap macet menampilkan "9 tugas terpilih".
   - *Solusi:* Memperbaiki `getLocalTasks()` agar menerima array kosong `[]` sebagai state valid, menambahkan guard persistensi benih `masjid_sophia_tasks_seeded`, dan memastikan `renderMasterTable()` membersihkan `selectedTaskIds`, mematikan checkbox header, dan menyembunyikan bulk toolbar saat tugas kosong.
2. **Log Donasi Publik & Koreksi KPI Donasi Masuk (`admin.html`):**
   - *Akar Masalah:* Baris donasi berstatus `VERIFIED` menampilkan ikon ceklist tanpa checkbox, sementara donasi `REJECTED` menampilkan checkbox, sehingga donasi yang ditolak tampak terseleksi sendirian. Selain itu, perhitungan KPI Donasi Masuk menjumlahkan seluruh donasi termasuk yang ditolak atau belum terverifikasi, dan belum tersedia fitur hapus donasi.
   - *Solusi:* Memberikan checkbox di seluruh baris donasi, memisahkan tombol "Verifikasi Terpilih" (hanya memproses status `PENDING`) dan tombol "Hapus Terpilih" (menghapus seluruh transaksi yang dicentang), menambahkan tombol hapus tunggal per baris, serta mengoreksi KPI Donasi Masuk agar hanya menghitung transaksi berstatus `VERIFIED`.
3. **Pusat Pengaduan & Kotak Saran Jamaah (`admin.html`):**
   - *Akar Masalah:* Tabel pengaduan hanya memiliki 6 kolom tanpa kolom Aksi, tidak memiliki kontrol pembaruan status, modal catatan tindak lanjut pengurus, maupun opsi hapus saran testing/spam.
   - *Solusi:* Menambahkan kolom Aksi dengan tombol "Respon" dan tombol "Hapus" (trash icon), membuat modal `#modal-feedback-followup` untuk pembaruan status penanganan (`BARU` -> `DIPROSES` -> `SELESAI`) dan pengisian catatan respon pengurus DKM, serta fungsi `handleDeleteSingleFeedback(id)`.
4. **Koneksi Dinamis Capaian Dapur ke KPI Overview (`admin.html`):**
   - *Akar Masalah:* Elemen `#kpi-makan-count` di dashboard Overview berisi teks statis `<h3 id="kpi-makan-count">70+ Porsi</h3>` dan tidak terhubung ke fungsi pembaharuan operasional dapur.
   - *Solusi:* Menghubungkan fungsi `updateDapurKpiStats()` dengan kartu `#kpi-makan-count` untuk menampilkan rata-rata porsi riil harian (`~${avgPorsi}+ Porsi`), serta mempercepat pemulihan data dapur dari cache lokal saat halaman dimuat.
5. **Capaian Sedekah Makan Realtime di Web Publik (`index.html`):**
   - *Akar Masalah:* Banner capaian sedekah makan menghitung donasi dengan rumus statis dan tidak membaca database operasional dapur `dapur_makan_siang`, serta belum memiliki siklus reset mingguan.
   - *Solusi:* Menghubungkan banner ke siklus reset mingguan otomatis (Senin 00:00 s.d. Ahad 23:59) untuk akumulasi infaq sedekah makan, dan menambahkan channel realtime CDC untuk `dapur_makan_siang` dan `donations`.
6. **Penyempurnaan Banner Publik & Eliminasi Target Publik (`index.html`):**
   - *Akar Masalah:* Publik melihat teks target (`Target: ... Porsi/Pekan`) dan progress bar yang berpotensi menimbulkan misinformasi jamaah, sementara target merupakan metrik internal DKM. Selain itu, judul banner memiliki teks porsi kaku.
   - *Solusi:* Mengubah judul banner menjadi "Capaian Infaq & Sedekah Makan Minggu Ini" dengan ikon penanda, menghapus judul lama "Penyaluran ~45+ Porsi...", menghapus label dan angka target publik beserta progress bar, dan menyajikan kartu metrik "Total Infaq Minggu Ini" yang menampilkan total rupiah dan padanan porsi secara elegan dan dinamis.
7. **Perbaikan Antarmuka & Tata Letak Tombol Respon Kotak Saran (`admin.html`):**
   - *Akar Masalah:* Tombol respon menggunakan kelas sempit `.btn-shift` yang mengunci ukuran tombol pada 26x26px, menyebabkan teks "Respon" terpotong, berhimpitan, dan bertabrakan dengan tombol hapus.
   - *Solusi:* Membuat kelas CSS khusus `.btn-feedback-respond` dan `.btn-feedback-delete` dengan padding proporsional (0.4rem 0.85rem), border melengkung 6px, bayangan halus, ikon `fa-reply`, jarak pemisah (`gap: 0.5rem`), serta memperlebar `min-width` kolom Aksi menjadi 155px.

### 2. Matriks Pengujian & Verifikasi:
- [x] Syntax checking inline JavaScript via Node.js: 0 errors pada `admin.html` dan `index.html`.
- [x] Zero-emoji strict compliance: 0 emoji baru diperkenalkan pada seluruh berkas yang dimodifikasi.
- [x] Verifikasi penghapusan seluruh tugas tidak memunculkan kembali tugas zombie saat refresh.
- [x] Verifikasi bulk toolbar tertutup bersih saat daftar tugas kosong.
- [x] Verifikasi seleksi donasi, hapus tunggal, hapus massal, dan KPI terverifikasi.
- [x] Verifikasi kolom Aksi, modal respon DKM, dan penghapusan saran pada Kotak Saran.
- [x] Verifikasi judul banner general "Capaian Infaq & Sedekah Makan Minggu Ini" dan kartu "Total Infaq Minggu Ini".
- [x] Verifikasi eliminasi total indikator target dan progress bar dari pandangan publik.
- [x] Verifikasi tata letak proporsional dan tidak terhimpitnya tombol Respon & Hapus pada Kotak Saran.


