# Master Implementation Plan - Ekosistem Portal Masjid Musafir Sophia Jatiwarna

**Entitas Proyek:** Masjid Musafir Sophia Jatiwarna  
**Lokasi Koordinat Astronomis:** Latitude `-6.310391`, Longitude `106.921264` (Zona Waktu: WIB / UTC+7)  
**Alamat:** Jl. Raya Hankam, RT.001/RW.011, Jatiwarna, Pondok Melati, Kota Bekasi, Jawa Barat 17415  
**Target Repositori:** `https://github.com/masjidsophiajatiwarna-wq/web-masjid-sophia-jatiwarna.git`  
**Domain Utama Produksi:** `https://masjidsophiajatiwarna.com/`  
**Domain Sekunder (Redirect 301):** `https://masjidsophiajatiwarna.my.id/`, `https://masjidsophia.com/`  
**Subdomain Pemantauan & Admin:** `https://progdev.masjidsophiajatiwarna.com/`, `https://admin.masjidsophiajatiwarna.com/`  
**Status Proyek:** Fase 1 Selesai (Fondasi & Rencana Induk Tervalidasi)  

---

## 1. Ringkasan Eksekutif & Sasaran Strategis

Masjid Musafir Sophia Jatiwarna membutuhkan ekosistem web portal modern, terpadu, dan berstandar tinggi yang melayani dua ranah utama:

1. **Layanan Informasi & Filantropi Terbuka untuk Publik:** Memberikan kemudahan akses bagi para musafir yang melintas, transparansi penyaluran infaq/sedekah harian (Makan Berjamaah Gratis 70+ porsi/hari ba'da Dzuhur & Pembinaan Santri Tahfidz), jadwal shalat presisi lokal hisab Kemenag RI, rotasi petugas ibadah, serta fasilitas masjid 24 jam.
2. **Sistem Manajemen Operasional Terpadu DKM (Web Admin & Employee Dashboard):** Menyediakan platform kolaboratif bagi jajaran pengurus DKM untuk mengelola tugas harian, papan kerja Kanban/Gantt/Table/Archive, ruang komunikasi internal, penerbitan artikel/agenda kajian melalui CMS, dan pembukuan arus kas donasi masuk.

---

## 2. Peta Fase Implementasi Teknis

```text
[FASE 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid]
       |
[FASE 1: Inisialisasi Infrastruktur, Berkas Tata Kelola & Monitoring] (STATUS: SELESAI)
       |
[FASE 2: Fondasi Database Supabase, Auth, Storage & Hardening RLS]
       |
[FASE 3: Pengembangan Frontend Web Portal Publik & Modul Shalat]
       |
[FASE 4: Pengembangan Web Admin DKM & Dashboard Manajemen Tugas]
       |
[FASE 5: Pengujian Terpadu, Audit Keamanan & User Acceptance Testing]
       |
[FASE 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live]
```

---

## 3. Rincian Pekerjaan Tiap Fase

### Fase 0: Pipeline Kurasi & Pengumpulan Aset Media Dokumentasi Masjid
- **Tujuan:** Mengumpulkan dan mengaudit seluruh materi visual otentik agar bebas dari foto stok generik.
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
- **Tujuan:** Merancang skema PostgreSQL, sistem autentikasi pengurus, penyimpanan media, dan keamanan Row Level Security (RLS) bertingkat.
- **Daftar Tugas:**
  - [ ] **Skema Tabel Inti PostgreSQL:**
    - `prayer_settings`: Parameter hisab, koordinat (-6.310391, 106.921264), dan offset menit ikhtiyat per waktu shalat.
    - `duty_rosters`: Jadwal rotasi harian/mingguan Imam Rawatib, Muadzin, Khatib Jumat, dan Penceramah Kajian.
    - `form_submissions`: Data formulir konfirmasi donasi & doa jamaah via Incognito Form.
    - `donations_cashflow`: Catatan mutasi kas donasi masuk/keluar terverifikasi dan kategori alokasi program.
    - `articles`: Konten dakwah, berita kegiatan, panduan ibadah, slug unik, tag, dan status publikasi.
    - `tasks`: Manajemen tugas DKM (judul, deskripsi, status Kanban, tenggat waktu, PIC, prioritas).
    - `task_comments`: Riwayat diskusi/chat koordinasi internal antar-pengurus pada setiap tugas.
    - `santri_profiles`: Data santri tahfidz, progres hafalan juz/surah, dan rekap kehadiran.
    - `user_profiles`: Profil akun pengurus terikat dengan `auth.users` dan penugasan peran RBAC.
    - `audit_logs`: Pencatatan aktivitas sensitif admin (perubahan data kas, rotasi petugas, perubahan ikhtiyat).
  - [ ] **Kebijakan Row Level Security (Zero-Trust):**
    - Publik (`anon`): Akses SELECT hanya pada artikel terbit, jadwal shalat, profil santri publik, dan jadwal petugas. Diizinkan INSERT pada formulir donasi tanpa akses SELECT/UPDATE/DELETE.
    - Terautentikasi (`authenticated`): Pembatasan akses CRUD berdasarkan peran RBAC pada JWT profile.
  - [ ] **Konfigurasi Supabase Storage:**
    - Bucket `article-media`: Media publik untuk konten berita dan flyer kegiatan.
    - Bucket `donation-receipts`: Bukti transfer donasi dengan akses terbatas bagi divisi keuangan.
    - Bucket `dkm-avatars`: Foto profil pengurus DKM.
  - [ ] **Otomasi GitHub Actions Cron Keep-Alive:**
    - Menyiapkan workflow 24/7 `.github/workflows/supabase-keepalive.yml` untuk mencegah jeda otomatis pada database tier gratis.

---

### Fase 3: Pengembangan Frontend Web Portal Publik & Modul Shalat
- **Tujuan:** Membangun antarmuka landing page utama, modul jadwal shalat presisi, kanal donasi, dan direktori konten.
- **Daftar Tugas:**
  - [ ] **Design System & Layout (`css/style.css`):**
    - Penerapan tema terang (Pure White `#FFFFFF`, Soft Cream Sand `#F8F6F0`, Charcoal Text `#1D1D1B`, Sophia Gold `#E3C466` & `#C9A84C`).
    - Tipografi `Inter`/`Plus Jakarta Sans` dan kaligrafi `Amiri` untuk doa Arab.
    - Navigasi responsif mobile-friendly dengan off-canvas drawer.
  - [ ] **Modul Jadwal Shalat Presisi Jatiwarna (Kemenag Hisab Engine):**
    - Perhitungan algoritma astronomis posisi matahari berbasis garis lintang/bujur Masjid Sophia.
    - Penyesuaian standar hisab Kemenag (Sudut Subuh -20 derajat, Isya -18 derajat, koreksi ketinggian tempat).
    - Live Countdown Timer detik demi detik menuju waktu shalat berikutnya.
    - Highlight visual dinamis pada kartu waktu shalat yang sedang aktif.
    - Integrasi offset ikhtiyat yang tersinkronisasi dari database Supabase.
  - [ ] **Modul Rotasi Petugas Ibadah & Kajian:**
    - Tampilan kartu petugas harian: Imam Rawatib, Muadzin, Khatib Shalat Jumat, dan Penceramah Kajian.
  - [ ] **Modul Filantropi & Donasi Umat:**
    - Penjelasan Program Makan Berjamaah Gratis ba'da Dzuhur (target 70+ porsi/hari).
    - Penjelasan Program Pembibitan Santri Tahfidz Al-Qur'an.
    - Box Nomor Rekening BSI `7235464297` a.n. Masjid Sophia dengan tombol 1-Click Copy otomatis.
    - Tampilan QRIS Merchant SEDEKAH MAKAN (NMID: `ID2025401816769`) dengan tombol simpan/unduh kode QR.
    - Formulir konfirmasi donasi & doa jamaah instan (Dynamic Incognito Form) dengan validasi nomor WhatsApp Indonesia (+62).
  - [ ] **Modul Fasilitas & Layanan Musafir 24 Jam:**
    - Showcase informasi ruang istirahat musafir, ketersediaan air minum gratis, kebersihan toilet/wudhu, dan rute lokasi samping UMAR Travel.
  - [ ] **Kanal Berita & Artikel (`artikel.html`, `artikel-detail.html`):**
    - Grid feed artikel dakwah dan kegiatan masjid dengan pencarian instan dan filter kategori.
    - Halaman baca artikel dengan estimasi waktu baca, rekomendasi artikel terkait, dan tombol bagikan.

---

### Fase 4: Pengembangan Web Admin DKM & Dashboard Manajemen Tugas
- **Tujuan:** Membangun dashboard terpusat bagi jajaran pengurus DKM dengan fitur manajemen tugas terpadu dan CMS berita.
- **Benchmark Rujukan:** `SIABE-PORTO` (Task Management) & `WEB-UMAR` (CMS Studio & Analytics).
- **Daftar Tugas:**
  - [ ] **Autentikasi & Guard RBAC (`admin.html`):**
    - Halaman login aman dengan validasi sesi JWT Supabase.
    - Sidebar adaptif yang hanya menampilkan menu sesuai kewenangan peran akun (10 peran RBAC).
  - [ ] **Modul Task Management Terpadu:**
    - **Kanban Board:** Papan drag-and-drop tugas (To Do, In Progress, In Review, Done).
    - **Timeline / Gantt View:** Visualisasi jadwal tenggat waktu kerja tim DKM.
    - **Table View:** Tabel interaktif pencarian dan pengurutan tugas berdasarkan PIC dan prioritas.
    - **Archive Task:** Pengarsipan otomatis tugas selesai untuk menjaga kerapihan papan aktif.
    - **Internal Chat System:** Obrolan koordinasi internal per tiket tugas untuk menjaga rekam jejak instruksi.
  - [ ] **Article & Event Studio CMS:**
    - Rich Text Editor untuk penulisan artikel dakwah dan agenda kajian.
    - Pengaturan slug otomatis, pemilihan gambar cover, dan pratinjau cuplikan Google Search (SEO Snippet).
  - [ ] **Panel Kalibrasi Waktu Shalat & Rotasi Petugas:**
    - Pengaturan menit ikhtiyat (tambah/kurang menit) yang langsung memperbarui kalkulasi jadwal di landing page publik.
    - Form penetapan dan rotasi nama Imam, Muadzin, Khatib, dan Penceramah.
  - [ ] **Manajemen Kas, Rekonsiliasi & Donasi:**
    - Verifikasi data donasi masuk via form incognito.
    - Pencatatan pengeluaran harian operasional dapur makan gratis dan pemeliharaan masjid.
    - Fitur ekspor laporan keuangan ke format CSV dan cetak ringkasan kas.

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

---

### Fase 6: Finalisasi Produksi, SEO, Email Routing, DNS Cutover & Go-Live
- **Tujuan:** Peluncuran resmi portal publik dan pengoperasian dashboard admin secara langsung di internet.
- **Daftar Tugas:**
  - [ ] **Optimasi Mesin Pencari (SEO):**
    - Metadata OpenGraph dan Twitter Card di setiap halaman.
    - Data terstruktur Schema.org JSON-LD (`Mosque`, `Organization`, `Article`).
    - Berkas `robots.txt` dan `sitemap.xml` terintegrasi.
  - [ ] **Halaman Error Kustom:**
    - Halaman `404.html` bertema terang resmi Masjid Sophia dengan navigasi kembali ke beranda.
  - [ ] **Email Gateway & Notifikasi (Resend.com):**
    - Konfigurasi DNS domain pengirim (SPF, DKIM, DMARC).
    - Template tanda terima donasi otomatis via email.
  - [ ] **Konfigurasi Routing Vercel (`vercel.json`):**
    - Subdomain routing untuk `progdev.masjidsophiajatiwarna.com` dan `admin.masjidsophiajatiwarna.com`.
    - Header keamanan (CSP, X-Content-Type-Options, X-Frame-Options).
  - [ ] **Pendaftaran Mesin Pencari:**
    - Registrasi properti di Google Search Console dan Bing Webmaster Tools.

---

## 4. Matriks Kewenangan Fitur Berdasarkan Peran (RBAC)

| Modul / Fitur Sistem | Super Admin | Ketua DKM | PJ Media | PJ Logistik | PJ Santri | PJ Musafir | PJ Ibadah | PJ Keuangan | PJ Keamanan | PJ Kebersihan |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Konfigurasi Sistem & API** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Manajemen Pengguna DKM** | Penuh | Baca | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Task Management (Kanban)** | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh | Penuh |
| **Article & Event Studio** | Penuh | Review | Penuh | Tidak | Tidak | Tidak | Input Kajian | Tidak | Tidak | Tidak |
| **Kalibrasi Shalat & Ikhtiyat** | Penuh | Persetujuan | Tidak | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak |
| **Rotasi Petugas & Imam** | Penuh | Persetujuan | Baca | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak |
| **Logistik & Makan Gratis** | Penuh | Laporan | Tidak | Penuh | Tidak | Tidak | Tidak | Laporan | Tidak | Tidak |
| **Data Santri & Tahfidz** | Penuh | Laporan | Tidak | Tidak | Penuh | Tidak | Tidak | Tidak | Tidak | Tidak |
| **Layanan Tamu Musafir** | Penuh | Laporan | Tidak | Tidak | Tidak | Penuh | Tidak | Tidak | Baca | Baca |
| **Laporan Kas & Donasi** | Penuh | Penuh | Tidak | Request | Request | Request | Request | Penuh | Tidak | Request |
| **Log Keamanan & Piket** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh | Tidak |
| **Sanitasi & Kebersihan** | Penuh | Laporan | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Tidak | Penuh |

---

## 5. Rencana Pengujian & Verifikasi

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
   - Uji pengiriman formulir konfirmasi donasi tanpa login ke tabel `form_submissions` Supabase.

4. **Pengujian Keamanan & Kepatuhan Standar:**
   - Verifikasi tidak adanya variabel rahasia atau kunci service-role pada JavaScript publik.
   - Verifikasi kepatuhan seluruh berkas terhadap aturan bebas emoji dan gaya penulisan manusiawi.
