# Master Implementation Plan - Ekosistem Portal Masjid Musafir Sophia Jatiwarna

**Entitas Proyek:** Masjid Musafir Sophia Jatiwarna  
**Lokasi Koordinat Astronomis:** Latitude `-6.310391`, Longitude `106.921264` (Zona Waktu: WIB / UTC+7)  
**Alamat:** Jl. Raya Hankam, RT.001/RW.011, Jatiwarna, Pondok Melati, Kota Bekasi, Jawa Barat 17415  
**Target Repositori:** `https://github.com/masjidsophiajatiwarna-wq/web-masjid-sophia-jatiwarna.git`  
**Domain Utama Produksi:** `https://masjidsophiajatiwarna.com/`  
**Domain Sekunder (Redirect 301):** `https://masjidsophiajatiwarna.my.id/`, `https://masjidsophia.com/`  
**Subdomain Pemantauan & Admin:** `https://progdev.masjidsophiajatiwarna.com/`, `https://admin.masjidsophiajatiwarna.com/`  
**Versi Rencana Induk:** v5.2 (Integrasi Suite Akun Pengurus DKM, Dynamic RBAC 17 Modul, Presensi 3-Tier SIABE-PORTO, Single-Write Login Broadcast, Hybrid Local Master Persistence, dan Mobile Grabber Table Engine)  
**Terakhir Diperbarui:** 2026-08-22  

---

## 1. Ringkasan Eksekutif & Sasaran Strategis

Masjid Musafir Sophia Jatiwarna membutuhkan ekosistem web portal modern, terpadu, dan berstandar tinggi yang melayani dua ranah utama:

1. **Layanan Informasi & Filantropi Terbuka untuk Publik (Benchmark: Masjid Istiqlal Jakarta & Web-UMAR Artikel):**
   - Portal umat & musafir mandiri bertema terang (*Pure White*, *Soft Cream Sand*, *Charcoal*, dan *Sophia Gold*).
   - Hisab jadwal shalat presisi lokal Kemenag Jatiwarna dengan *Live Countdown Timer*.
   - Program Sedekah Makan Dzuhur (70+ porsi/hari) & Pembinaan Santri Tahfidz.
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
[FASE 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid] (50% - Dikelola Tim Media)
       |
[FASE 1: Inisialisasi Infrastruktur, Berkas Tata Kelola & Monitoring] (STATUS: SELESAI 100%)
       |
[FASE 2: Fondasi Database Supabase, Auth, Storage & Hardening RLS] (STATUS: SELESAI 90%)
       |
[FASE 3: Frontend Web Portal Publik, Berita Dakwah, Galeri & Modul Shalat] (STATUS: 60% SELESAI)
       |
[FASE 4: Web Admin DKM, Fluid Mobile-First UI & Suite Modul Lengkap PJ] (STATUS: 50% SELESAI)
       |
[FASE 5: Pengujian Terpadu, Audit Keamanan & User Acceptance Testing]
       |
[FASE 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live]
       |
[FASE 7: Pipeline Aplikasi Mobile Android (.apk) & PWA Khusus Pengurus DKM]
```

---

## 3. Rincian Pekerjaan Tiap Fase

### Fase 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid
- **Penanganan:** Murni oleh Tim Media Masjid melalui portal checklist `media-checklist.html`.
- **Daftar Tugas:**
  - [x] Audit aset logo resmi format vektor SVG (`logo_masjid_black.svg`, `logo_masjid_white.svg`) dan PNG transparan.
  - [x] Verifikasi paket Favicon multi-ukuran (16x16, 32x32, Apple Touch Icon, Android Chrome, site.webmanifest).
  - [ ] Kurasi galeri foto riil (Makan Siang Gratis, fasilitas 24 jam, santri tahfidz, ruang utama).
  - [ ] Konversi dan kompresi seluruh aset foto ke format WebP teroptimasi untuk performa web.

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
- **Status:** 90% Selesai
- **Daftar Tugas:**
  - [x] **Master Skema Inti PostgreSQL (`database/schema.sql`):** `donations`, `jadwal_petugas`, `artikel_berita`, `team_tasks`, `system_health_logs`, `admin_users`, `feedback_complaints`, `media_checklists`.
  - [x] **Zero-Trust RLS Policies & Serverless Functions:** `/api/health.js`, `/api/donasi.js`, `/api/send-receipt.js`, `/api/pengaduan.js`.
  - [x] **Otomasi GitHub Actions Cron Keep-Alive:** Workflow 24/7 `.github/workflows/supabase-keepalive.yml`.
  - [ ] **Migrasi Skema Tambahan Suite Lengkap Modul PJ & Task Management v2:**
    - `team_tasks` (ALTER: `start_date`, `is_archived`, `order_index`).
    - `task_activity_logs`, `task_comments`, `task_chat_messages`.
    - `masjid_assets`, `santri_data`, `santri_mutabaah`, `musafir_logbook`, `financial_journals`, `security_reports`, `cleaning_reports`.
    - RLS Policies & Realtime Publication untuk seluruh tabel baru.

---

### Fase 3: Frontend Web Portal Publik, Berita Dakwah, Galeri & Modul Shalat
- **Benchmark Rujukan:** Masjid Istiqlal Jakarta (`https://www.istiqlal.or.id/`) & UMAR Travel (`artikel.html`, `artikel-detail.html`)
- **Status:** 60% Selesai
- **Daftar Tugas:**
  - [x] **Design System & Komponen Beranda Inti (`index.html`):** Tema Terang Resmi, Hisab Jadwal Shalat Jatiwarna (Kemenag) + Live Countdown, Kartu Petugas Ibadah, Box Donasi BSI 1-Click Copy `7235464297` & QRIS SEDEKAH MAKAN, Dynamic Incognito Form, Informasi Fasilitas Musafir 24 Jam.
  - [ ] **Redesign Besar Beranda Publik (Benchmark Istiqlal):** Hero Slider, Kartu Layanan Cepat, Kalender Ganda Hijriah/Masehi, Agenda Kajian Pekanan, Galeri Sorotan Carousel, Sticky Header, Mobile Bottom Nav Bar, Footer 4 Kolom.
  - [ ] **Kolom Pengaduan, Saran & Aspirasi Jamaah di Web Publik:** Modal interaktif terhubung ke `/api/pengaduan` dan tabel `feedback_complaints`.
  - [ ] **Halaman Direktori Berita & Artikel Dakwah (`artikel.html` - Benchmark UMAR):** Hero Search, Filter Kategori, Featured Article & Grid Artikel WebP, Pagination.
  - [ ] **Halaman Detail Artikel Mandiri (`artikel-detail.html` - Benchmark UMAR):** Header, Cover WebP, Rich Text Body, Tombol Share WhatsApp/FB, Rekomendasi Artikel Terkait.
  - [ ] **Halaman Galeri Multimedia (`galeri.html`):** Album Foto & Video per Kategori, Lightbox Pop-up, Video Streaming ImageKit.io.
  - [ ] **Live Chat Jamaah ke Panel Admin (Status: Coming Soon / Rencana Lanjutan):** Widget obrolan mengambang di pojok kanan bawah web publik.

---

### Fase 4: Web Admin DKM, Fluid Mobile-First UI & Suite Modul Lengkap PJ
- **Benchmark Rujukan:** SIABE-PORTO (Task Engine & Cloud Monitor), WEB-UMAR Admin (Article Studio), dan Standard Modul Odoo/Masjid (`.unused-modul-web-sophia`)
- **Status:** 50% Selesai (Admin Core, Task Management 5 View, Obrolan Koordinasi Multi-Arah, Account Control & Dynamic RBAC, Profil Mandiri & Mobile Grabber Selesai)
- **Daftar Tugas:**
  - [x] **Pondasi Admin Core & Auth Gate (`admin.html`):** Gerbang login Supabase Auth JWT, sidebar adaptif RBAC 10 peran, panel KPI Real-Time, inbox kotak saran, dan rekonsiliasi kas harian.
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
    - [x] **Tabel Seluruh Akun Pengurus Realtime:** Daftar akun DKM dengan status presisi (Online / Idle / Offline) berbasis 3-Tier Activity Presence SIABE-PORTO, status login terakhir (*last active*), peran, divisi, dan sinkronisasi live tanpa refresh via Supabase Presence & CDC.
    - [x] **Modal Override Akun (Super Admin / DKM):** Reset kredensial ke baku awal (1-click reset ke `AKUN_PENGURUS_DKM.txt`), ubah email/nama, auto-pattern multi-PJ generator (`media2@...`), dan tombol **Paksa Akhiri Sesi (*Force End Session / Logout*)** via WebSocket `FORCE_LOGOUT`.
    - [x] **Matriks Izin Dinamis 17 Modul (`permissions JSONB`):** Pengaturan hak akses granular per modul (Penuh / Baca / Request / Review / Laporan / Kajian / Persetujuan / Tidak Ada Akses) yang merender sidebar secara dinamis dan fleksibel (non-hardcoded).
    - [x] **Lapisan Presensi & Persistensi Hibrida (`masjid_sophia_admin_users_master`):** 3-Tier Activity Presence (Online <1 jam, Idle 1-3 jam, Offline >3 jam/logout, 3-hour inactivity session timeout), Single-Write Login Broadcast (tanpa polling heartbeat berat), dan Local Master Persistence sebagai fail-safe pembatasan Row Level Security (RLS 403 Forbidden).
  - [x] **Modal Profil & Keamanan Mandiri Pengurus (Self-Service Profile & Security):**
    - [x] **Akses Mandiri PJ Divisi:** Dibuka lewat klik kartu profil/avatar di pojok kiri bawah sidebar.
    - [x] **Tab 1 - General Profile:** Ubah Nama Lengkap dan **Upload Foto Profil (Avatar)** dari perangkat lokal langsung teroptimasi (auto WebP 400x400) ke **ImageKit.io CDN**.
    - [x] **Tab 2 - Security & Login:** Ganti kata sandi dan ganti email dengan **Strict Security Rule: Otomatis Logout & Wajib Login Ulang**.
  - [ ] **Suite Modul Khusus per Divisi PJ:**
    - **PJ Media & Dakwah:** Article Studio (Quill.js Rich Text, slug generator, ImageKit cover WebP) & Dynamic Homepage Media Manager (review Ketua DKM).
    - **PJ Logistik & Sarpras:** Porsi Makan Gratis ba'da Dzuhur (70+ porsi/hari, dapur) & Inventaris Aset Fisik Masjid (kode inventaris, lokasi, kondisi, servis).
    - **PJ Santri & Pendidikan:** Direktori Santri Tahfidz & Log Mutaba'ah Setoran Hafalan Qur'an (Subuh & Maghrib) serta rapor perkembangan.
    - **PJ Musafir & Pelayanan:** Buku Tamu Musafir Digital, Izin Menginap / Istirahat 24 Jam, dan Log Penitipan Kendaraan & Loker Barang.
    - **PJ Ibadah & Acara:** Kalibrasi Menit Ikhtiyat Shalat, Rotasi Petugas Harian (Imam, Muadzin, Khatib, Bilal), Kalender Acara/Kajian & Arsip Khutbah.
    - **PJ Keuangan:** Buku Kas Masuk, Buku Kas Keluar, Alur Form Pengajuan Anggaran (*Budget Request*) & Klaim Nota Bon (*Expense Claim*) bagi seluruh 7 PJ divisi dengan persetujuan Ketua DKM & PJ Keuangan, Laporan Arus Kas, dan Neraca Kas Berkala (CSV & PDF).
    - **PJ Keamanan:** Log Piket Keamanan 24 Jam, Patroli Area, dan Input Laporan Kejadian dengan unggah foto/video ke ImageKit CDN (auto WebP/WebM).
    - **PJ Kebersihan:** Checklist Sanitasi Harian (Wudhu, Toilet, Ruang Shalat, Halaman) dan Input Laporan Kebersihan dengan unggah foto/video ke ImageKit CDN (auto WebP/WebM).
  - [ ] **Modul Pengajuan Izin & Cuti Pengurus DKM (Leave & Absence Management):**
    - **Formulir Pengajuan Izin Mandiri (Seluruh Pengurus):** Formulir bagi seluruh PJ divisi untuk mengajukan izin (Izin Sakit + bukti surat dokter, Keperluan Pribadi, Tugas Luar, Cuti Operasional) dengan tanggal mulai, tanggal selesai, alasan, dan status transparan.
    - **Alur Persetujuan Terpusat (Approval Flow):** Panel khusus bagi **Ketua DKM & Super Admin** untuk menyetujui (*Approve*) atau menolak (*Reject*) permohonan izin dengan catatan.
    - **Cron Otomasi & Keep-Alive:** Rekapitulasi absensi harian dan notifikasi pengingat pengajuan izin pending ke pimpinan DKM.
  - [ ] **Pemantau Kesehatan Arsitektur 7 Pilar Cloud (Khusus Super Admin):**
    - Dashboard kuota free-tier 7 pilar, kalkulasi dinamis `{ count: 'exact', head: true }`, KPI Row biaya IDR 0, panduan preventif (>80%).
  - [ ] **Ekspor Laporan Kinerja PDF Mandiri per Anggota Tim DKM:**
    - Format PDF standar Web Landscape (`jsPDF v2.5.1`).

---

### Fase 5: Pengujian Terpadu, Audit Keamanan & UAT
- **Daftar Tugas:**
  - [ ] **Unit & Accuracy Testing:** Hisab shalat lokal vs kalender resmi Kemenag Kota Bekasi.
  - [ ] **Form & Security Testing:** Validasi sanitasi form, pencegahan SQLi/XSS, dan audit Zero-Trust RLS Supabase.
  - [ ] **Cross-Device & Mobile Performance Testing:** Uji responsif dan kelancaran touch pada Android (layar 360px–430px) dan iPhone.
  - [ ] **UAT Pengurus DKM:** Simulasi alur kerja 10 peran pengurus via smartphone di lapangan.

---

### Fase 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live
- **Status:** 40% Selesai
- **Daftar Tugas:**
  - [x] **Email Routing & SMTP Gateway:** Cloudflare Email Routing & Resend SMTP aktif.
  - [x] **SEO Dasar:** Berkas `robots.txt` dan `sitemap.xml` terpasang.
  - [ ] **SEO Lanjutan & Schema.org JSON-LD:** Metadata OpenGraph, Twitter Card, Rich Snippets Mosque/Organization/Article.
  - [ ] **Halaman Error Kustom:** `404.html` bertema terang resmi Masjid Sophia.
  - [ ] **Pendaftaran Mesin Pencari:** Google Search Console & Bing Webmaster Tools.

---

### Fase 7: Pipeline Aplikasi Mobile Android (.apk) & PWA Khusus Pengurus DKM (BARU)
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
