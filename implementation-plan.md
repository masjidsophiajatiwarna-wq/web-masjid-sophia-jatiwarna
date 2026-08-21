# Master Implementation Plan - Ekosistem Portal Masjid Musafir Sophia Jatiwarna

**Entitas Proyek:** Masjid Musafir Sophia Jatiwarna  
**Lokasi Koordinat Astronomis:** Latitude `-6.310391`, Longitude `106.921264` (Zona Waktu: WIB / UTC+7)  
**Alamat:** Jl. Raya Hankam, RT.001/RW.011, Jatiwarna, Pondok Melati, Kota Bekasi, Jawa Barat 17415  
**Target Repositori:** `https://github.com/masjidsophiajatiwarna-wq/web-masjid-sophia-jatiwarna.git`  
**Domain Utama Produksi:** `https://masjidsophiajatiwarna.com/`  
**Domain Sekunder (Redirect 301):** `https://masjidsophiajatiwarna.my.id/`, `https://masjidsophia.com/`  
**Subdomain Pemantauan & Admin:** `https://progdev.masjidsophiajatiwarna.com/`, `https://admin.masjidsophiajatiwarna.com/`  
**Versi Rencana Induk:** v3.0  
**Terakhir Diperbarui:** 2026-08-21  

---

## 1. Ringkasan Eksekutif & Sasaran Strategis

Masjid Musafir Sophia Jatiwarna membutuhkan ekosistem web portal modern, terpadu, dan berstandar tinggi yang melayani dua ranah utama:

1. **Layanan Informasi & Filantropi Terbuka untuk Publik (Benchmark: Masjid Istiqlal Jakarta):** Memberikan kemudahan akses bagi para musafir yang melintas, transparansi penyaluran infaq/sedekah harian (Makan Berjamaah Gratis 70+ porsi/hari ba'da Dzuhur & Pembinaan Santri Tahfidz), jadwal shalat presisi lokal hisab Kemenag RI, rotasi petugas ibadah, galeri multimedia, kolom pengaduan & saran jamaah, serta fasilitas masjid 24 jam.
2. **Sistem Manajemen Operasional Terpadu DKM (Web Admin & Employee Dashboard, Benchmark: SIABE-PORTO):** Menyediakan platform kolaboratif bagi jajaran pengurus DKM untuk mengelola tugas harian melalui 5 mode tampilan (Kanban/Gantt/Calendar/Table/Archive), riwayat pengelolaan realtime, chat koordinasi internal multi-arah, CMS mandiri tanpa coding (Self-Sustain), pemantauan kesehatan arsitektur 7 pilar cloud, dan pembukuan arus kas donasi masuk.

---

## 2. Peta Fase Implementasi Teknis

```text
[FASE 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid]
       |
[FASE 1: Inisialisasi Infrastruktur, Berkas Tata Kelola & Monitoring] (STATUS: SELESAI 100%)
       |
[FASE 2: Fondasi Database Supabase, Auth, Storage & Hardening RLS] (STATUS: SELESAI 100%)
       |
[FASE 3: Pengembangan Frontend Web Portal Publik & Modul Shalat] (STATUS: DALAM PROSES)
       |
[FASE 4: Pengembangan Web Admin DKM & Dashboard Manajemen Tugas] (STATUS: DALAM PROSES)
       |
[FASE 5: Pengujian Terpadu, Audit Keamanan & User Acceptance Testing]
       |
[FASE 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live]
```

Catatan: Urutan fase bersifat fleksibel -- eksekusi dapat dilakukan secara paralel dan prioritas fase dapat dipindahkan sesuai keputusan Super Admin.

---

## 3. Rincian Pekerjaan Tiap Fase

### Fase 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid
- **Tujuan:** Mengumpulkan dan mengaudit seluruh materi visual otentik agar bebas dari foto stok generik.
- **Penanganan:** Murni oleh Tim Media Masjid melalui portal checklist `media-checklist.html` -- tidak disentuh oleh tim pengembang.
- **Daftar Tugas:**
  - [x] Audit aset logo resmi format vektor SVG (`logo_masjid_black.svg`, `logo_masjid_white.svg`) dan PNG transparan.
  - [x] Verifikasi paket Favicon multi-ukuran (16x16, 32x32, Apple Touch Icon, Android Chrome, site.webmanifest).
  - [ ] Kurasi galeri foto riil:
    - Dokumentasi program Makan Berjamaah Gratis ba'da Dzuhur (pemberian makanan kepada musafir dan ojek online).
    - Dokumentasi fasilitas 24 jam (area wudhu higienis, karpet ruang shalat utama, dispenser air minum, rest area).
    - Dokumentasi halaqah pembinaan santri tahfidz Al-Qur'an.
  - [ ] Konversi dan kompresi seluruh aset foto ke format WebP teroptimasi untuk performa web.

---

### Fase 1: Inisialisasi Infrastruktur, Berkas Tata Kelola & Monitoring
- **Tujuan:** Membangun fondasi repositori, standarisasi dokumen proyek, dan pelacak progres visual interaktif.
- **Status:** Selesai (100%)
- **Daftar Tugas:**
  - [x] Penyusunan berkas acuan `BRAND_GUIDE.md` (Light Theme: `#FFFFFF`, `#F8F6F0`, `#1D1D1B`, `#E3C466`, `#C9A84C`).
  - [x] Penyusunan `Master-Fullstack-Web-App-Services-v1.md` (Arsitektur 7 Pilar).
  - [x] Pembuatan `.gitignore` komprehensif untuk pengamanan kredensial dan eliminasi file cache.
  - [x] Pembuatan `README.md` terstruktur dengan panduan instalasi, arsitektur, dan matriks RBAC.
  - [x] Pembuatan `CHANGELOG.md` versi rilis awal v1.0.0.
  - [x] Pembuatan `implementation-plan.md` (berkas rencana induk ini).
  - [x] Pembuatan antarmuka visual pelacak progres `progress-implementation-plan.html` (bebas emoji, interaktif, responsif).
  - [x] Panduan manual konfigurasi Redirect 301 di Cloudflare DNS untuk domain sekunder.
  - [x] Panduan manual perintah Git step-by-step untuk inisialisasi repositori dan push pertama ke GitHub.

---

### Fase 2: Fondasi Database Supabase, Auth, Storage & Hardening RLS
- **Tujuan:** Merancang skema PostgreSQL, sistem autentikasi pengurus, penyimpanan media, Serverless Functions, dan keamanan Row Level Security (RLS) bertingkat.
- **Status:** Selesai (100%) untuk skema inti. Migrasi tambahan diperlukan untuk modul Task Management v2.
- **Daftar Tugas:**
  - [x] **Master Skema PostgreSQL (`database/schema.sql`):**
    - `media_checklists`: Pelacak kurasi 18 aset dokumentasi foto & video terhubung Google Drive dengan Real-Time WebSocket.
    - `donations`: Perekaman formulir donasi incognito, sedekah makan siang gratis, dan infaq operasional dengan kode unik verifikasi.
    - `jadwal_petugas`: Jadwal rotasi harian/mingguan Imam Rawatib, Muadzin, Khatib Jumat, dan Penceramah Kajian.
    - `artikel_berita`: CMS warta kegiatan dan artikel dakwah dengan slug unik dan status publikasi.
    - `team_tasks`: Manajemen produktivitas tugas DKM (tenggat waktu, PIC, divisi, status Kanban).
    - `system_health_logs`: Monitoring kesehatan sistem (Supabase latency, Vercel Edge, ImageKit 20GB quota, Resend gateway).
    - `admin_users`: Manajemen hak akses pengurus terikat peran RBAC (Super Admin, Ketua DKM, PJ Media, Bendahara, Staff).
    - `feedback_complaints`: Pengaduan & kotak saran jamaah.
  - [x] **Kebijakan Row Level Security (Zero-Trust Hardening):**
    - Publik (`anon`): Akses SELECT pada artikel, jadwal shalat, petugas, status checklist media, dan donasi terverifikasi. Akses INSERT pada formulir donasi dan system health.
    - Terautentikasi (`authenticated`): Hak akses penuh CRUD untuk modul administratif dan manajemen tugas.
  - [x] **Vercel Serverless Functions Suite (`/api`):**
    - `/api/health.js`: Pemeriksaan kesehatan sistem, latensi koneksi Supabase, kuota ImageKit 20GB, dan status Vercel Edge.
    - `/api/donasi.js`: Ingestion konfirmasi donasi instan dengan generator kode unik acak 3-digit ke Supabase.
    - `/api/send-receipt.js`: Pengiriman kuitansi donasi resmi secara instan ke email donatur melalui Resend API.
    - `/api/pengaduan.js`: Ingestion pengaduan dan saran jamaah dengan notifikasi email ke DKM.
  - [x] **Otomasi GitHub Actions Cron Keep-Alive:**
    - Workflow 24/7 `.github/workflows/supabase-keepalive.yml` untuk mencegah jeda otomatis pada database tier gratis.
  - [ ] **Migrasi Skema Tambahan Task Management v2:**
    - ALTER tabel `team_tasks`: Tambah kolom `start_date` (DATE), `is_archived` (BOOLEAN), `order_index` (INT).
    - CREATE tabel `task_activity_logs`: Audit trail realtime setiap aksi CRUD per PJ (actor_name, action_type, old_value JSONB, new_value JSONB).
    - CREATE tabel `task_comments`: Komentar dan instruksi kerja per tugas (author_name, author_role, comment_text).
    - CREATE tabel `task_chat_messages`: Chat koordinasi internal multi-arah antar-pengurus (sender_name, recipient_type: ALL/DIVISION/DIRECT, message_text, is_read).
    - RLS Policies & Realtime Publication untuk keempat tabel baru.
  - [ ] **Konfigurasi Supabase Storage & Bucket:**
    - Bucket `article-media`: Media publik untuk konten berita dan flyer kegiatan.
    - Bucket `donation-receipts`: Bukti transfer donasi dengan akses terbatas bagi divisi keuangan.
    - Bucket `dkm-avatars`: Foto profil pengurus DKM.

---

### Fase 3: Pengembangan Frontend Web Portal Publik & Modul Shalat
- **Tujuan:** Membangun antarmuka portal web publik komprehensif berstandar Masjid Istiqlal Jakarta dengan hisab shalat presisi lokal Jatiwarna, rotasi petugas ibadah, kanal filantropi 1-Click Copy BSI & QRIS, layanan musafir 24 jam, kolom pengaduan & saran, galeri multimedia, dan pemisahan penuh dari dashboard admin DKM.
- **Benchmark Rujukan:** Website Resmi Masjid Istiqlal Jakarta (`https://www.istiqlal.or.id/`)
- **Status:** Dalam Proses
- **Daftar Tugas:**
  - [x] **Design System & Layout Publik (`index.html`):**
    - Penerapan tema terang resmi (*Pure White* `#FFFFFF`, *Soft Cream Sand* `#F8F6F0`, *Charcoal Text* `#1D1D1B`, *Sophia Gold* `#E3C466` & `#C9A84C`).
    - Tipografi modern `Plus Jakarta Sans` / `Inter` dan kaligrafi doa Arab `Amiri`.
    - Navigasi responsif mobile-friendly murni untuk jamaah (tanpa tombol portal admin di navbar/beranda).
  - [x] **Modul Jadwal Shalat Presisi Jatiwarna (Kemenag Hisab Engine):**
    - Sinkronisasi koordinat astronomis Masjid Sophia Jatiwarna (`-6.310391, 106.921264`, WIB).
    - Penyesuaian standar hisab Kemenag (Sudut Subuh -20 derajat, Isya -18 derajat, ikhtiyat +2 menit).
    - Fitur *Live Countdown Timer* detik demi detik menuju waktu shalat berikutnya.
    - Penanda visual aktif (*Active Prayer Card Highlight*) pada waktu shalat yang sedang berjalan.
  - [x] **Modul Rotasi Petugas Ibadah & Kajian:**
    - Tampilan kartu petugas harian: Imam Rawatib aktif, Muadzin bertugas, Khatib Shalat Jumat, dan Pengisi Kajian Tematik.
  - [x] **Modul Filantropi & Donasi Umat:**
    - Program Unggulan Makan Berjamaah Gratis ba'da Dzuhur (70+ porsi/hari).
    - Program Pembinaan Santri Penghafal Al-Qur'an (Tahfidz) & Operasional 24 Jam.
    - Box Rekening Bank BSI `7235464297` a.n. Masjid Sophia dengan tombol *1-Click Copy* otomatis.
    - QRIS Merchant SEDEKAH MAKAN (NMID: `ID2025401816769`).
    - Formulir konfirmasi donasi & doa jamaah instan (*Dynamic Incognito Form*).
  - [x] **Modul Fasilitas & Layanan Musafir 24 Jam:**
    - Showcase kamar mandi & tempat wudhu bersih 24 jam, area istirahat sejuk, air minum higienis gratis, dan lokasi strategis samping UMAR Travel.
  - [x] **Kanal Berita, Tausiyah & Warta Kegiatan:**
    - Grid kartu artikel dakwah, laporan penyaluran donasi makan gratis, estimasi waktu baca, dan kategori.
  - [ ] **Redesign Besar Beranda Publik (Benchmark Istiqlal):**
    - Hero Banner Slider resolusi tinggi dengan animasi transisi halus dan CTA utama (Donasi, Jadwal Shalat, Layanan).
    - Kartu Layanan Cepat (Quick Access): Layanan Musafir, ZISWAF, Program Santri Tahfidz, Kajian Rutin.
    - Widget Kalender Hijriah & Masehi ganda.
    - Section Agenda & Jadwal Kajian Pekanan.
    - Galeri Sorotan Carousel (dokumentasi kegiatan, arsitektur masjid, suasana shalat berjamaah).
    - Sticky Header Navigation dengan smooth scroll.
    - Animasi scroll-reveal dan micro-interactions pada hover kartu.
    - Mobile Bottom Navigation Bar (Jadwal Shalat, Donasi, WhatsApp).
    - Footer 4 kolom (Identitas, Tautan Cepat, Layanan, Kontak & Sosmed).
  - [ ] **Kolom Pengaduan, Saran & Aspirasi Jamaah di Web Publik:**
    - Modal/section interaktif di beranda publik terhubung ke `/api/pengaduan` dan tabel `feedback_complaints`.
    - Kategori aspirasi: Pelayanan, Kebersihan, Keamanan, Fasilitas, Saran Umum.
    - Proteksi anti-spam (honeypot + rate limiting).
  - [ ] **Live Chat Jamaah ke Panel Admin (Coming Soon):**
    - Floating chat widget di sudut kanan bawah web publik.
    - Pesan jamaah masuk langsung ke panel chat admin dashboard secara realtime.
    - Status: *Coming Soon* -- implementasi memerlukan sumber daya tambahan signifikan (Supabase Realtime + persistent sessions + queue management).
  - [ ] **Halaman Berita Terpisah & Detail Artikel (`artikel.html`, `artikel-detail.html`):**
    - Grid feed artikel dakwah dan kegiatan masjid dengan pencarian instan, filter kategori, pagination, dan halaman baca artikel mandiri.
    - Tombol bagikan ke WhatsApp, Facebook, dan salin tautan.
    - Rekomendasi artikel terkait.
  - [ ] **Halaman Galeri Multimedia (`galeri.html`):**
    - Grid album foto & video dokumentasi kegiatan per kategori (Shalat Berjamaah, Kajian, Makan Gratis, Fasilitas).
    - Lightbox penampil foto resolusi penuh.
    - Integrasi streaming video via ImageKit CDN 20GB.

---

### Fase 4: Pengembangan Web Admin DKM, Self-Sustain CMS & Task Health Dashboard
- **Tujuan:** Membangun dashboard terpusat bagi jajaran pengurus DKM dengan sistem manajemen tugas terpadu 5 View + 2 Panel Pendukung (Benchmark: SIABE-PORTO), CMS mandiri tanpa coding (Self-Sustain), pemantauan kesehatan arsitektur 7 pilar cloud (Benchmark: SIABE-PORTO Multi-Cloud Monitor), chat koordinasi internal multi-arah, dan ekspor laporan PDF.
- **Benchmark Rujukan:** SIABE-PORTO (`I:\My Drive\GAWE\WEB DEV\SIABE-PORTO`)
- **Status:** Dalam Proses (Admin Core & KPI selesai, modul lanjutan belum)
- **Daftar Tugas:**
  - [x] **Autentikasi & Guard RBAC (`admin.html`):**
    - Halaman login aman dengan validasi sesi JWT Supabase.
    - Sidebar adaptif yang hanya menampilkan menu sesuai kewenangan peran akun (10 peran RBAC).
  - [x] **Panel KPI Real-Time & Buku Kas Donasi Masuk:**
    - Monitoring realtime arus infaq/sedekah makan ba'da Dzuhur, kode unik verifikasi, dan rekapitulasi kas.
  - [x] **Inbox Kotak Saran & Pusat Pengaduan Jamaah:**
    - Panel pemantauan laporan fasilitas rusak dan masukan jamaah terhubung tabel `feedback_complaints`.
  - [x] **Rekonsiliasi Kas Masuk & Laporan Keuangan:**
    - Verifikasi data donasi masuk via form incognito dan pencatatan pengeluaran operasional harian.
  - [ ] **Modul Task Management Terpadu (5 View + 2 Panel Pendukung):**
    - **View 1 - Kanban Board:** Papan drag-and-drop 4 kolom (Pending, Dikerjakan, Review Ketua DKM, Selesai) dengan badge timeline health (Overdue H+X / On Track Xd left), tombol cepat Setujui & Revisi di kolom Review.
    - **View 2 - Gantt Timeline:** Visualisasi bar jadwal `start_date` hingga `due_date` per PJ menggunakan pustaka `frappe-gantt v0.6.1`, toggle skala Hari/Minggu/Bulan, kode warna status.
    - **View 3 - Calendar View:** Grid kalender bulanan dengan spanning bars multi-hari (algoritma slot vertikal anti-tumpang tindih), sub-mode Agenda kronologis, drag-select rentang tanggal untuk buat tugas baru otomatis.
    - **View 4 - All Tasks Table:** Tabel master interaktif dengan Summary Metrics Bar (Total/Pending/Dikerjakan/Review/Selesai), filter pipeline multi-kriteria (teks/divisi/status/prioritas/rentang tanggal/scope arsip), sorting per kolom, multi-select bulk archive, export CSV.
    - **View 5 - Archive View:** Tabel arsip tugas selesai dikelompokkan per divisi, akordion sub-tabel deliverables, metrik persentase penyelesaian, restorasi granular per tugas atau per kelompok divisi.
    - **Panel 6 - Riwayat Pengelolaan Realtime (Audit Trail):** Timeline kronologis seluruh aksi CRUD per PJ (buat/pindah status/arsipkan/komentar/hapus), 100% realtime tanpa refresh via Supabase WebSocket CDC (Change Data Capture), filter per PJ dan per jenis aksi, badge notifikasi unread.
    - **Panel 7 - Chat Koordinasi Internal Multi-Arah:** Semua lini pengurus bisa saling berkirim pesan (PJ ke PJ, PJ ke Ketua DKM, langsung ke Super Admin -- bukan satu arah seperti SIABE-PORTO), 3 mode pengiriman (Broadcast ALL / Per Divisi / Direct Message), opsional dikaitkan ke tugas tertentu, 100% realtime tanpa refresh via Supabase WebSocket CDC, badge unread, riwayat percakapan scroll.
  - [ ] **No-Code Modular CMS & Dynamic Page Builder (Self-Sustain Tim Masjid):**
    - **Dynamic Homepage Media Manager:** Pengaturan foto/video banner slider hero, galeri kegiatan, dan kartu program yang tampil di beranda tanpa menyentuh kode HTML. RBAC: Khusus PJ Media, Ketua DKM, dan Super Admin. Jalur review wajib sebelum tayang.
    - **Custom Page / Section Builder:** Modul pembuatan halaman statis mandiri (misal: "Sejarah Masjid", "Profil Pengurus", "Laporan Qurban", "Panduan Ramadhan") dengan form/WYSIWYG sederhana.
    - **Article & Gallery Studio:** Pengelolaan artikel dakwah, berita penyaluran donasi makan gratis, upload media ImageKit CDN (foto & video streaming 20GB), dan pratinjau cuplikan SEO Google. RBAC: PJ Media akses penuh, Ketua DKM review.
  - [ ] **Panel Kalibrasi Waktu Shalat & Rotasi Petugas:**
    - Pengaturan menit ikhtiyat (tambah/kurang menit) yang langsung memperbarui kalkulasi jadwal di landing page publik.
    - Form penetapan dan rotasi nama Imam, Muadzin, Khatib, dan Penceramah.
  - [ ] **Pemantau Kesehatan Arsitektur 7 Pilar Cloud (Khusus Super Admin):**
    - Tab khusus dashboard Super Admin untuk monitoring seluruh infrastruktur agar tetap aman berjalan di free tier.
    - 7 Kartu Pilar dengan progress bar kuota: Supabase (DB Size/500MB, Auth Users/50K MAU, Realtime Channels), Vercel (Bandwidth/100GB, Serverless Hours), ImageKit (Storage/20GB, Bandwidth/25GB, Transformations/20K), Resend (Emails/3K per bulan), GitHub Actions (CI/CD Minutes/2K), Cloudflare (DNS/SSL/Turnstile), Google Drive (Storage quota).
    - Top-level KPI Row: Total biaya bulanan IDR 0, status infrastruktur ALL SAFE X/7, estimasi ukuran database.
    - Panduan tindakan preventif saat kuota mendekati ambang batas (>80%).
    - Kalkulasi dinamis ukuran Postgres dari jumlah baris tabel menggunakan `{ count: 'exact', head: true }`.
    - Tombol refresh manual dan deep-link ke dashboard resmi masing-masing penyedia cloud.
  - [ ] **Ekspor Laporan PDF Mandiri per Anggota Tim DKM:**
    - Ekspor laporan aktivitas dan kinerja masing-masing anggota tim DKM ke format PDF standar Web Landscape menggunakan pustaka `jsPDF v2.5.1`.

---

### Fase 5: Pengujian Terpadu, Audit Keamanan & UAT
- **Tujuan:** Memverifikasi seluruh logika bisnis, kalkulasi astronomis, performa beban, dan pengerasan celah keamanan.
- **Daftar Tugas:**
  - [ ] **Unit & Accuracy Testing:**
    - Verifikasi kesesuaian waktu hisab shalat lokal dengan jadwal resmi Kemenag RI untuk wilayah Kota Bekasi.
    - Uji presisi live countdown timer saat pergantian waktu shalat dan tengah malam.
  - [ ] **Form & Security Testing:**
    - Uji validasi input form (pencegahan injeksi SQL, pembersihan payload XSS, perlindungan honeypot spam).
    - Audit keamanan RLS Supabase untuk memastikan akun `anon` tidak dapat membaca data donatur lain.
  - [ ] **Cross-Device & Responsive Testing:**
    - Uji tampilan antarmuka pada berbagai resolusi layar (Mobile 360px - 430px, Tablet 768px - 1024px, Desktop 1280px+).
  - [ ] **UAT Pengurus DKM:**
    - Simulasi alur kerja pengurus (input artikel, rotasi petugas, perubahan status tugas di Kanban, dan ekspor kas).
    - Uji chat internal multi-arah antar PJ.
    - Uji riwayat pengelolaan realtime (pastikan muncul instan tanpa refresh).

---

### Fase 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live
- **Tujuan:** Peluncuran resmi portal publik dan pengoperasian dashboard admin secara langsung di internet.
- **Daftar Tugas:**
  - [x] **Email Gateway & Routing:**
    - Cloudflare Email Routing aktif (info@, pengaduan@, saran@masjidsophiajatiwarna.com).
    - Supabase Custom SMTP via Resend.com (DKIM/SPF terverifikasi).
    - Template email autentikasi HTML bertemakan Sophia Gold.
  - [x] **Berkas SEO Dasar:**
    - `robots.txt` dan `sitemap.xml` sudah live.
  - [ ] **Optimasi Mesin Pencari (SEO) Lanjutan:**
    - Metadata OpenGraph dan Twitter Card di setiap halaman.
    - Data terstruktur Schema.org JSON-LD (`Mosque`, `Organization`, `Article`).
  - [ ] **Halaman Error Kustom:**
    - Halaman `404.html` bertema terang resmi Masjid Sophia dengan navigasi kembali ke beranda.
  - [ ] **Konfigurasi Routing Vercel (`vercel.json`):**
    - Header keamanan (CSP, X-Content-Type-Options, X-Frame-Options).
  - [ ] **Pendaftaran Mesin Pencari:**
    - Registrasi properti di Google Search Console dan Bing Webmaster Tools.

---

## 4. Matriks Kewenangan Fitur Berdasarkan Peran (RBAC)

| Modul / Fitur Sistem | Super Admin | Ketua DKM | PJ Media | PJ Logistik | PJ Santri | PJ Musafir | PJ Ibadah | PJ Keuangan | PJ Keamanan | PJ Kebersihan |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Konfigurasi Sistem & API** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Manajemen Pengguna DKM** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Task Management (5 View)** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |
| **Riwayat Pengelolaan** | Penuh+Hapus | Baca | Baca | Baca | Baca | Baca | Baca | Baca | Baca | Baca |
| **Chat Koordinasi Internal** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |
| **CMS & Page Builder** | Penuh | Review | Penuh | Tidak | Tidak | Tidak | Input Kajian | Tidak | Tidak | Tidak |
| **Dynamic Homepage Manager** | Penuh | Review | Penuh | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Kalibrasi Shalat & Ikhtiyat** | Penuh | Persetujuan | Tidak | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak |
| **Rotasi Petugas & Imam** | Penuh | Persetujuan | Baca | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak |
| **Logistik & Makan Gratis** | Penuh | Laporan | Tidak | Penuh | Tidak | Tidak | Tidak | Laporan | Tidak | Tidak |
| **Data Santri & Tahfidz** | Penuh | Laporan | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Layanan Tamu Musafir** | Penuh | Laporan | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Baca | Baca |
| **Laporan Kas & Donasi** | Penuh | Penuh | Tidak | Request | Request | Request | Request | Penuh | Tidak | Request |
| **Log Keamanan & Piket** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh | Tidak |
| **Sanitasi & Kebersihan** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh |
| **Monitor Arsitektur 7 Pilar** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |

---

## 5. Dependensi Pustaka CDN Eksternal

| Pustaka | Versi | Kegunaan |
| :--- | :--- | :--- |
| `@supabase/supabase-js` | v2 (jsDelivr) | Auth, DB, Realtime WebSocket CDC |
| `frappe-gantt` | v0.6.1 (jsDelivr) | Gantt Timeline Chart interaktif |
| `jsPDF` | v2.5.1 (cdnjs) | Export laporan PDF mandiri |
| `Plus Jakarta Sans` / `Inter` | Google Fonts | Tipografi UI |
| `Font Awesome` | 6.5.1 (cdnjs) | Sistem ikon (strict no-emoji) |

---

## 6. Rencana Pengujian & Verifikasi

1. **Pengujian Subdomain & Routing Produksi:**
   - `masjidsophiajatiwarna.com` memuat landing page publik resmi.
   - `masjidsophia.com` dan `masjidsophiajatiwarna.my.id` secara otomatis dialihkan (Redirect 301) ke domain utama.
   - `progdev.masjidsophiajatiwarna.com` memuat halaman visual pelacak progres `progress-implementation-plan.html`.
   - `admin.masjidsophiajatiwarna.com` memuat dashboard operasional `admin.html`.

2. **Pengujian Fungsionalitas Jadwal Shalat:**
   - Validasi sinkronisasi hisab dengan jadwal shalat resmi Kemenag Kota Bekasi.
   - Pengujian live countdown timer dan visual highlight waktu shalat aktif.
   - Pengujian pembaruan instan menit ikhtiyat dari admin panel.

3. **Pengujian Transaksi Donasi & 1-Click Copy:**
   - Uji penyalinan nomor rekening BSI `7235464297` dengan satu klik tanpa format spasi.
   - Uji keterbacaan kode QRIS SEDEKAH MAKAN pada berbagai aplikasi perbankan dan e-wallet.
   - Uji pengiriman formulir konfirmasi donasi tanpa login ke tabel `donations` Supabase.

4. **Pengujian Task Management 5+2 View:**
   - Uji drag-and-drop Kanban -- status berubah + log tercatat realtime.
   - Uji Gantt Timeline -- bar muncul sesuai start_date/due_date.
   - Uji Calendar View -- spanning bars tidak tumpang tindih.
   - Uji All Tasks Table -- filter, sort, bulk archive, export CSV.
   - Uji Archive View -- arsipkan dan pulihkan tugas.
   - Uji Riwayat -- aksi CRUD muncul realtime tanpa refresh.
   - Uji Chat -- kirim broadcast/divisi/direct, muncul realtime tanpa refresh di browser penerima.

5. **Pengujian Keamanan & Kepatuhan Standar:**
   - Verifikasi tidak adanya variabel rahasia atau kunci service-role pada JavaScript publik.
   - Verifikasi kepatuhan seluruh berkas terhadap aturan bebas emoji dan gaya penulisan manusiawi.
