# Master Implementation Plan - Ekosistem Portal Masjid Musafir Sophia Jatiwarna

**Entitas Proyek:** Masjid Musafir Sophia Jatiwarna  
**Lokasi Koordinat Astronomis:** Latitude `-6.310391`, Longitude `106.921264` (Zona Waktu: WIB / UTC+7)  
**Alamat:** Jl. Raya Hankam, RT.001/RW.011, Jatiwarna, Pondok Melati, Kota Bekasi, Jawa Barat 17415  
**Target Repositori:** `https://github.com/masjidsophiajatiwarna-wq/web-masjid-sophia-jatiwarna.git`  
**Domain Utama Produksi:** `https://masjidsophiajatiwarna.com/`  
**Domain Sekunder (Redirect 301):** `https://masjidsophiajatiwarna.my.id/`, `https://masjidsophia.com/`  
**Subdomain Pemantauan & Admin:** `https://progdev.masjidsophiajatiwarna.com/`, `https://admin.masjidsophiajatiwarna.com/`  
**Versi Rencana Induk:** v4.0 (Full Operational PJ Suite & Comprehensive Architecture)  
**Terakhir Diperbarui:** 2026-08-21  

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
   - **Task Management Karyawan 5 View + 2 Panel:** Kanban, Gantt Timeline (`frappe-gantt`), Calendar Spanning Bars, All Tasks Table (Filter/Sort/Bulk Archive/CSV), Archive View per divisi, Riwayat Pengelolaan Realtime (CDC WebSocket 100% tanpa refresh), dan Chat Koordinasi Multi-Arah antar semua PJ & Ketua DKM.
   - **Modul Operasional Khusus per Penanggung Jawab (PJ) Divisi:**
     - **PJ Media & Dakwah:** Content & Article Studio (Quill.js Rich Text, slug generator, ImageKit WebP cover), Dynamic Homepage Media Manager, dan Lightbox Gallery.
     - **PJ Logistik & Sarpras:** Manajemen Porsi Makan Dzuhur (kebutuhan bahan, porsi terbagi, logistik dapur) & Manajemen Aset/Inventaris Masjid (nomor inventaris, kondisi aset, lokasi, riwayat servis).
     - **PJ Santri & Pendidikan:** Data Profil Santri Tahfidz, Absensi Halaqah (Subuh & Maghrib), Mutaba'ah Setoran Hafalan Qur'an (Juz/Surat/Ayat/Tajwid), dan Rapor Perkembangan.
     - **PJ Musafir & Pelayanan:** Buku Tamu Musafir Digital, Log Tamu Menginap/Istirahat Darurat 24 Jam, dan Log Penitipan Kendaraan & Loker Barang.
     - **PJ Ibadah & Acara:** Kalibrasi Hisab & Menit Ikhtiyat, Rotasi Petugas Harian (Imam 5 waktu, Muadzin, Khatib Jumat, Bilal), dan Kalender Acara/Kajian Tematik/PHBI + Arsip Khutbah.
     - **PJ Keuangan (Accounting Suite):** Buku Kas Masuk (Infaq, QRIS, BSI, Tunai), Buku Kas Keluar (Operasional, Dapur, Sarpras, Santunan), Rekonsiliasi Donasi Otomatis, Laporan Arus Kas, dan Neraca Kas Transparan (Export CSV & Print PDF).
     - **PJ Keamanan:** Log Piket Keamanan 24 Jam, Patroli Parkiran, Input Laporan Insiden, dan Unggah Bukti Foto/Video ke ImageKit CDN (auto WebP/WebM).
     - **PJ Kebersihan:** Checklist Sanitasi Harian (Wudhu, Toilet, Ruang Shalat Utama, Halaman), Input Laporan Kebersihan, Unggah Bukti Foto/Video ke ImageKit CDN (auto WebP/WebM), dan Kontrol Stok Bahan Pembersih.
   - **Super Admin Multi-Cloud 7 Pilar Monitor:** Pemantauan real-time kuota free-tier (Supabase DB & Storage, Vercel Bandwidth, ImageKit 20GB, Resend Email API, GitHub Actions, Cloudflare, Google Drive) dengan kalkulasi dinamis `{ count: 'exact', head: true }` dan panduan tindakan preventif.

---

## 2. Peta Fase Implementasi Teknis

```text
[FASE 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid] (0% - Dikelola Tim Media)
       |
[FASE 1: Inisialisasi Infrastruktur, Berkas Tata Kelola & Monitoring] (STATUS: SELESAI 100%)
       |
[FASE 2: Fondasi Database Supabase, Auth, Storage & Hardening RLS] (STATUS: SELESAI 90%)
       |
[FASE 3: Frontend Web Portal Publik, Berita Dakwah, Galeri & Modul Shalat] (STATUS: DALAM PROSES)
       |
[FASE 4: Web Admin DKM, Employee Dashboard, 5 View Task & Suite Modul PJ] (STATUS: DALAM PROSES)
       |
[FASE 5: Pengujian Terpadu, Audit Keamanan & User Acceptance Testing]
       |
[FASE 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live]
```

---

## 3. Rincian Pekerjaan Tiap Fase

### Fase 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid
- **Tujuan:** Mengumpulkan dan mengaudit seluruh materi visual otentik agar bebas dari foto stok generik.
- **Penanganan:** Murni oleh Tim Media Masjid melalui portal checklist `media-checklist.html` -- tidak disentuh oleh tim pengembang.
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
- **Status:** 90% Selesai (Skema Inti Selesai, Migrasi Skema Lengkap Modul PJ Siap Dijalankan)
- **Daftar Tugas:**
  - [x] **Master Skema Inti PostgreSQL (`database/schema.sql`):**
    - `donations`, `jadwal_petugas`, `artikel_berita`, `team_tasks`, `system_health_logs`, `admin_users`, `feedback_complaints`, `media_checklists`.
  - [x] **Zero-Trust RLS Policies & Serverless Functions:**
    - `/api/health.js`, `/api/donasi.js`, `/api/send-receipt.js`, `/api/pengaduan.js`.
  - [x] **Otomasi GitHub Actions Cron Keep-Alive:**
    - Workflow 24/7 `.github/workflows/supabase-keepalive.yml` untuk mencegah database sleep.
  - [ ] **Migrasi Skema Tambahan Suite Lengkap Modul PJ & Task Management v2:**
    - **Tabel `team_tasks` (ALTER):** Tambah `start_date` (DATE), `is_archived` (BOOLEAN), `order_index` (INT).
    - **Tabel `task_activity_logs` (CREATE):** Audit trail realtime aksi CRUD per PJ (actor_name, action_type, old_value JSONB, new_value JSONB).
    - **Tabel `task_comments` (CREATE):** Komentar dan instruksi kerja per tugas.
    - **Tabel `task_chat_messages` (CREATE):** Chat koordinasi multi-arah (sender, recipient_type: ALL/DIVISION/DIRECT, message_text, is_read).
    - **Tabel `masjid_assets` (CREATE - PJ Logistik):** Inventaris aset masjid (asset_code, name, category, location, condition: BAIK/RUSAK_RINGAN/RUSAK_BERAT, purchase_date, purchase_cost, notes).
    - **Tabel `santri_data` (CREATE - PJ Santri):** Biodata santri tahfidz (nis, full_name, birth_date, guardian_name, guardian_phone, enrollment_date, status: AKTIF/ALUMNI).
    - **Tabel `santri_mutabaah` (CREATE - PJ Santri):** Catatan hafalan Qur'an (santri_id, tanggal, waktu: SUBUH/MAGHRIB, juz, surat, ayat_start, ayat_end, kelancaran, tajwid_score, pengampu).
    - **Tabel `musafir_logbook` (CREATE - PJ Musafir):** Buku tamu & log menginap/penitipan (guest_name, phone, origin_city, destination, visit_type: SHALAT/REST_AREA/MENGINAP/TITIP_KENDARAAN, vehicle_plate, locker_num, check_in, check_out, notes).
    - **Tabel `financial_journals` (CREATE - PJ Keuangan):** Jurnal kas masuk & kas keluar (trx_date, trx_type: KAS_MASUK/KAS_KELUAR, category, description, amount, payment_method, proof_url, created_by).
    - **Tabel `security_reports` (CREATE - PJ Keamanan):** Log piket & insiden keamanan (shift: PAGI/SIANG/MALAM, officer_name, report_type: PATROLI/INSIDEN/KONDISI_AMAN, description, media_url, media_type: IMAGE/VIDEO).
    - **Tabel `cleaning_reports` (CREATE - PJ Kebersihan):** Checklist sanitasi & kebersihan (shift, cleaner_name, area: WUDHU/TOILET/RUANG_UTAMA/HALAMAN, status: BERSIH/PERLU_TINDAKAN, media_url, supply_used, notes).
    - **RLS Policies & Supabase Realtime Publication** untuk seluruh tabel baru.

---

### Fase 3: Frontend Web Portal Publik, Berita Dakwah, Galeri & Modul Shalat
- **Benchmark Rujukan:** Masjid Istiqlal Jakarta (`https://www.istiqlal.or.id/`) & UMAR Travel (`artikel.html`, `artikel-detail.html`)
- **Status:** 60% Selesai
- **Daftar Tugas:**
  - [x] **Design System & Komponen Beranda Inti (`index.html`):**
    - Tema Terang Resmi, Tipografi Sans-Serif modern & Kaligrafi Amiri Arab.
    - Hisab Jadwal Shalat Jatiwarna (Kemenag) + Live Countdown Timer + Active Prayer Highlight.
    - Kartu Petugas Ibadah Harian (Imam, Muadzin, Khatib, Penceramah).
    - Box Donasi BSI 1-Click Copy `7235464297` & QRIS SEDEKAH MAKAN (NMID `ID2025401816769`).
    - Dynamic Incognito Form Konfirmasi Donasi & Doa.
    - Informasi Fasilitas Musafir 24 Jam & Navigasi Mobile-First Drawer.
  - [ ] **Redesign Besar Beranda Publik (Benchmark Istiqlal):**
    - Hero Banner Slider foto kegiatan resolusi tinggi dengan animasi transisi halus.
    - Kartu Layanan Cepat (Quick Access): Layanan Musafir, ZISWAF, Santri Tahfidz, Kajian Rutin.
    - Kalender Ganda Hijriah & Masehi.
    - Section Agenda & Kalender Kajian Pekanan / PHBI.
    - Galeri Sorotan Carousel foto & video dokumentasi peribadatan.
    - Sticky Header Navigation dengan smooth scroll-reveal.
    - Mobile Bottom Navigation Bar (Jadwal Shalat, Donasi, Hotline WhatsApp).
    - Footer 4 Kolom (Identitas, Tautan Cepat, Layanan, Kontak & Media Sosial).
  - [ ] **Kolom Pengaduan, Saran & Aspirasi Jamaah di Web Publik:**
    - Modal interaktif terhubung ke `/api/pengaduan` dan tabel `feedback_complaints`.
    - Kategori: Pelayanan, Kebersihan, Keamanan, Fasilitas, Saran Umum.
  - [ ] **Halaman Direktori Berita & Artikel Dakwah (`artikel.html` - Benchmark UMAR):**
    - Hero Banner Pencarian Berita dengan live text search.
    - Filter Kategori Berita: Warta Dakwah, Kegiatan Masjid, Kajian Fiqih, Laporan Makan Siang Gratis, Buletin Mimbar Jumat.
    - Kartu Artikel Utama (Featured Article) & Grid Artikel Terkini dengan thumbnail WebP, tanggal, tag kategori, dan estimasi waktu baca.
    - Navigasi Pagination halaman.
  - [ ] **Halaman Detail Artikel Mandiri (`artikel-detail.html` - Benchmark UMAR):**
    - Header artikel: Judul lengkap, nama penulis/ustadz, tanggal terbit, waktu baca.
    - Gambar sampul resolusi tinggi WebP teroptimasi ImageKit CDN.
    - Isi artikel Rich Text dengan tipografi nyaman, kutipan ayat/hadits bergaya kaligrafi, dan sub-heading terstruktur.
    - Tombol Bagikan ke WhatsApp, Facebook, dan Salin Tautan.
    - Rekomendasi Artikel Terkait di bagian bawah.
  - [ ] **Halaman Galeri Multimedia (`galeri.html`):**
    - Grid album foto dokumentasi & video kegiatan (Shalat Berjamaah, Makan Gratis, Santri, Wisata Religi Musafir).
    - Lightbox pop-up penampil foto layar penuh.
    - Embed pemutar video streaming ringan via ImageKit.io CDN.
  - [ ] **Live Chat Jamaah ke Panel Admin (Status: Coming Soon):**
    - Widget chat melayang di sudut kanan bawah web publik terhubung ke panel chat admin DKM.

---

### Fase 4: Web Admin DKM, Employee Dashboard & Suite Modul Lengkap per PJ
- **Benchmark Rujukan:** SIABE-PORTO (Task Engine & Cloud Monitor), WEB-UMAR Admin (Article Studio), dan Standard Modul Odoo/Masjid (`.unused-modul-web-sophia`)
- **Status:** 25% Selesai (Admin Core, Auth, KPI & Pengaduan Selesai)
- **Daftar Tugas:**
  - [x] **Pondasi Admin Core & Auth Gate (`admin.html`):**
    - Gerbang login aman Supabase Auth JWT, proteksi rute, dan sidebar adaptif RBAC 10 peran.
    - Panel KPI Real-Time: Donasi masuk, porsi makan siang gratis, dan task health rate.
    - Inbox Kotak Saran & Pengaduan Jamaah dari tabel `feedback_complaints`.
    - Rekonsiliasi donasi masuk dan pencatatan kas harian.
  - [ ] **Task Management Terpadu (5 View + 2 Panel):**
    - **View 1 (Kanban Board):** Papan drag-and-drop 4 kolom (`PENDING`, `IN_PROGRESS`, `IN_REVIEW`, `COMPLETED`), badge kesehatan waktu (*Overdue / On Track*), dan tombol aksi cepat Setujui/Revisi.
    - **View 2 (Gantt Timeline):** Visualisasi bar jadwal `start_date` - `due_date` per PJ menggunakan `frappe-gantt v0.6.1` (skala Hari/Minggu/Bulan).
    - **View 3 (Calendar View):** Grid bulanan dengan *spanning bars* multi-hari (algoritma slot vertikal anti-tumpang tindih) & mode Agenda kronologis.
    - **View 4 (All Tasks Table):** Tabel master master filter pipeline (teks/divisi/status/prioritas/tanggal/arsip), sorting kolom, multi-select bulk archive, dan export CSV.
    - **View 5 (Archive View):** Arsip tugas selesai per divisi, akordion sub-tabel, metrik persentase tuntas, dan tombol pemulihan tugas.
    - **Panel 6 (Riwayat Pengelolaan Realtime):** Audit trail seluruh aksi CRUD per PJ, **100% tanpa refresh** via Supabase CDC WebSocket.
    - **Panel 7 (Chat Koordinasi Multi-Arah):** Komunikasi internal antar semua pengurus (Broadcast ALL / Per Divisi / Direct Message ke PJ atau Ketua DKM atau Super Admin), **100% tanpa refresh** via Supabase WebSocket.
  - [ ] **Modul PJ Media & Dakwah (Content & Article Studio):**
    - **Article Studio:** Pembuatan & penerbitan artikel dengan Rich Text Editor (Quill.js), slug generator otomatis, upload media sampul ImageKit CDN (auto WebP), kategori, status DRAFT/PUBLISHED, dan pratinjau cuplikan SEO Google.
    - **Dynamic Homepage Media Manager:** Pengaturan foto/video banner slider hero, galeri kegiatan, dan kartu program beranda publik tanpa menyentuh kode HTML. Jalur persetujuan review Ketua DKM sebelum tayang.
  - [ ] **Modul PJ Logistik & Sarpras (Makan Gratis & Inventaris Aset):**
    - **Manajemen Makan Berjamaah Gratis:** Pencatatan porsi makan harian (70+ porsi/hari), logistik belanja bahan dapur, biaya per porsi, dan rekapitulasi distribusi ke musafir/ojol.
    - **Manajemen Aset & Inventaris Masjid:** Perekaman aset sarpras (sound system, AC, karpet, genset, dispenser, Al-Qur'an), nomor seri inventaris, lokasi penempatan, kondisi aset (Baik, Rusak Ringan, Rusak Berat), dan riwayat perbaikan/servis.
  - [ ] **Modul PJ Santri & Pendidikan (Tahfidz & Mutaba'ah):**
    - **Data & Profil Santri:** Direktori santri tahfidz aktif & alumni, biodata, data wali/kontak, kamar/halaqah, dan status beasiswa.
    - **Log Mutaba'ah Hafalan Qur'an:** Pencatatan setoran hafalan harian (Subuh & Maghrib: Juz/Surat/Ayat), penilaian kelancaran & tajwid, absensi halaqah, dan cetak rapor perkembangan santri.
  - [ ] **Modul PJ Musafir & Pelayanan (Buku Tamu & Penitipan 24 Jam):**
    - **Buku Tamu Musafir Digital:** Pencatatan tamu musafir yang singgah (Nama, Asal Kota, Tujuan, No HP).
    - **Log Tamu Menginap / Istirahat 24 Jam:** Izin menginap istirahat darurat musafir antar-kota, verifikasi identitas, dan fasilitas yang digunakan.
    - **Log Penitipan Kendaraan & Loker:** Pencatatan plat kendaraan dan nomor loker penitipan barang saat musafir shalat/istirahat.
  - [ ] **Modul PJ Ibadah & Acara (Kalibrasi Shalat & Rotasi Petugas):**
    - **Kalibrasi Hisab & Ikhtiyat:** Pengaturan menit ikhtiyat waktu shalat lokal.
    - **Rotasi Petugas Ibadah:** Penugasan Imam Rawatib (5 waktu), Muadzin, Khatib Jumat, Bilal, dan Penceramah Kuliah Subuh / Akhir Pekan.
    - **Manajemen Acara & Kajian Tematik:** Jadwal kajian, PHBI (Maulid, Isra Mi'raj, dll), dan arsip naskah khutbah Jumat yang dapat diunduh.
  - [ ] **Modul PJ Keuangan (Comprehensive Accounting Suite):**
    - **Buku Kas Masuk:** Infaq Jumat, Infaq Kotak Amal, Donasi QRIS SEDEKAH MAKAN, Transfer Bank BSI, dan Donasi Khusus.
    - **Buku Kas Keluar:** Biaya operasional dapur makan gratis, listrik/air/wifi, honorarium ustadz/petugas, perawatan sarpras, dan santunan santri.
    - **Laporan Keuangan & Rekonsiliasi:** Laporan Arus Kas, Neraca Kas Berkala, Verifikasi Donasi Kode Unik, dan Ekspor Laporan Keuangan ke format CSV & Cetak PDF Transparan.
  - [ ] **Modul PJ Keamanan (Log Piket & Laporan Insiden):**
    - **Log Piket & Ronda Keamanan 24 Jam:** Jadwal petugas jaga, checklist patroli area masjid & parkiran.
    - **Input Laporan Keamanan & Upload Bukti:** Formulir pelaporan insiden/kondisi aman dengan unggah foto/video ke ImageKit CDN (auto WebP/WebM).
  - [ ] **Modul PJ Kebersihan (Checklist Sanitasi & Laporan Kerja):**
    - **Checklist Sanitasi Harian:** Jadwal pembersihan area wudhu, toilet, karpet ruang utama, dan halaman.
    - **Input Laporan Kebersihan & Upload Bukti:** Formulir laporan hasil kerja dengan unggah foto/video ke ImageKit CDN (auto WebP/WebM) dan kontrol stok alat/sabun pembersih.
  - [ ] **Pemantau Kesehatan Arsitektur 7 Pilar Cloud (Khusus Super Admin):**
    - Dashboard monitoring 7 pilar cloud gratis (Supabase DB/Storage, Vercel Bandwidth, ImageKit 20GB, Resend Email API, GitHub Actions, Cloudflare, Google Drive).
    - Kalkulasi dinamis ukuran Postgres via `{ count: 'exact', head: true }`, progress bar kuota, KPI Row biaya IDR 0/bulan, dan panduan preventif ambang batas (>80%).
  - [ ] **Ekspor Laporan Kinerja PDF Mandiri per Anggota Tim DKM:**
    - Ekspor laporan aktivitas dan rekap tugas per anggota ke format PDF standar Web Landscape (`jsPDF v2.5.1`).

---

### Fase 5: Pengujian Terpadu, Audit Keamanan & UAT
- **Daftar Tugas:**
  - [ ] **Unit & Accuracy Testing:** Hisab shalat lokal vs kalender resmi Kemenag Kota Bekasi.
  - [ ] **Form & Security Testing:** Validasi sanitasi form, pencegahan SQLi/XSS, dan audit Zero-Trust RLS Supabase.
  - [ ] **Cross-Device & Responsive Testing:** Mobile (360px-430px), Tablet, Desktop (1280px+).
  - [ ] **UAT Pengurus DKM:** Simulasi alur kerja seluruh 10 peran pengurus (Input Artikel, Mutaba'ah Santri, Log Musafir, Kas Masuk/Keluar, Report Keamanan/Kebersihan, Task 5 View, dan Chat Realtime).

---

### Fase 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live
- **Status:** 40% Selesai
- **Daftar Tugas:**
  - [x] **Email Routing & SMTP Gateway:** Cloudflare Email Routing & Resend SMTP aktif (DKIM/SPF valid).
  - [x] **SEO Dasar:** Berkas `robots.txt` dan `sitemap.xml` terpasang.
  - [ ] **SEO Lanjutan & Schema.org JSON-LD:** Metadata OpenGraph, Twitter Card, Rich Snippets Mosque/Organization/Article.
  - [ ] **Halaman Error Kustom:** `404.html` bertema terang resmi Masjid Sophia.
  - [ ] **Pendaftaran Mesin Pencari:** Google Search Console & Bing Webmaster Tools verification.

---

## 4. Matriks Kewenangan Fitur Berdasarkan Peran (RBAC 10 Peran)

| Modul / Fitur Sistem | Super Admin | Ketua DKM | PJ Media | PJ Logistik | PJ Santri | PJ Musafir | PJ Ibadah | PJ Keuangan | PJ Keamanan | PJ Kebersihan |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Konfigurasi Sistem & API** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Manajemen Pengguna DKM** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Task Management (5 View)** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |
| **Riwayat Pengelolaan Realtime** | Penuh+Hapus | Baca | Baca | Baca | Baca | Baca | Baca | Baca | Baca | Baca |
| **Chat Koordinasi Multi-Arah** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |
| **Publish Artikel & Berita (CMS)** | Penuh | Review | Penuh | Tidak | Tidak | Tidak | Input Kajian | Tidak | Tidak | Tidak |
| **Pengatur Beranda (Self-Sustain)** | Penuh | Review | Penuh | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Logistik Makan & Aset Masjid** | Penuh | Laporan | Tidak | Penuh | Tidak | Tidak | Tidak | Laporan | Tidak | Tidak |
| **Data Santri & Mutaba'ah Tahfidz** | Penuh | Laporan | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Buku Tamu Musafir & Loker 24 Jam** | Penuh | Laporan | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Baca | Baca |
| **Kalibrasi Shalat & Rotasi Petugas** | Penuh | Persetujuan | Baca | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak |
| **Akuntansi, Kas & Laporan Keuangan** | Penuh | Penuh | Tidak | Request | Request | Request | Request | Penuh | Tidak | Request |
| **Report Keamanan & Upload Bukti** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh | Tidak |
| **Report Kebersihan & Upload Bukti** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh |
| **Monitor 7 Pilar Cloud (Super Admin)** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |

---

## 5. Dependensi Pustaka CDN Eksternal

| Pustaka | Versi | Sumber CDN | Kegunaan |
| :--- | :--- | :--- | :--- |
| `@supabase/supabase-js` | `v2` | jsDelivr | Autentikasi, Database Postgres, Realtime WebSocket CDC |
| `frappe-gantt` | `0.6.1` | jsDelivr | Timeline Gantt Chart visual interaktif |
| `quill` | `1.3.6` | CDNjs | WYSIWYG Rich Text Editor untuk Article Studio |
| `jsPDF` | `2.5.1` | CDNjs | Generator Dokumen Laporan Kinerja & Keuangan PDF |
| `Plus Jakarta Sans` / `Inter` | Standar | Google Fonts | Tipografi antarmuka modern |
| `Amiri` | Standar | Google Fonts | Tipografi ayat Al-Qur'an, hadits, dan doa Arab |
| `Font Awesome` | `6.5.1` | CDNjs | Sistem ikon vektor monokrom (Strict No-Emoji) |
