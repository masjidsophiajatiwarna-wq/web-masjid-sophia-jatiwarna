# Catatan Perubahan (Changelog)

Seluruh perubahan penting pada proyek **Web Portal Masjid Musafir Sophia Jatiwarna** dicatat secara berkala dalam berkas ini.

Format penulisan mengacu pada standar [Keep a Changelog](https://keepachangelog.com/id/1.0.0/) dan prinsip [Semantic Versioning](https://semver.org/).

---

## [1.5.0] - 2026-08-21

### Optimasi Fluid Mobile-First & Pipeline Aplikasi Android APK (Master Roadmap v5.0)

#### Penambahan & Pembaruan (Added & Updated)
- `[ROADMAP]` Rencana induk teknis `implementation-plan.md` diperbarui ke versi v5.0 mencakup:
  - **Fluid Desktop & Mobile-First Touch UI (`admin.html`):** Pengalaman desktop leluasa dan adaptasi fluid di layar HP (navigasi bilah bawah, bottom sheet modal drawer, target sentuh min 48px, gestur swipe).
  - **Fase 7 - Pipeline Aplikasi Mobile Android (.apk) Khusus Pengurus DKM:**
    - *Tingkat 1 (PWA):* Web Manifest (`site.webmanifest`), offline caching Service Worker, dan Add to Homescreen instan.
    - *Tingkat 2 (TWA / WebAPK):* Pembuatan berkas installer mandiri `MasjidSophia-Admin.apk` (Google Bubblewrap / PWABuilder) yang otomatis sinkron pembaruan dari Vercel tanpa perlu instal ulang.
    - *Tingkat 3 (Native Capacitor.js):* Integrasi push notification tugas & chat (Firebase FCM), akses kamera cepat untuk bukti kebersihan/keamanan, dan login biometrik sidik jari.
  - **Modul Pengajuan Izin & Cuti Pengurus DKM (`dkm_leave_requests`):** Formulir izin sakit/keperluan pribadi/cuti bagi seluruh pengurus (Request) dengan alur persetujuan terpusat (*Approval*) khusus Ketua DKM & Super Admin, serta sinkronisasi jadwal tugas otomatis.
- `[DASHBOARD]` Dashboard pelacak progres visual `progress-implementation-plan.html` pada subdomain `progdev.masjidsophiajatiwarna.com` diperbarui ke Total 8 Fase (Fase 0 - Fase 7) lengkap dengan kartu Fase 7, sub-grup permohonan izin pengurus, dan matriks RBAC 10 peran.
- `[DATABASE]` Penambahan tabel `dkm_leave_requests` beserta proteksi RLS dan Realtime Publication WebSocket pada `database/schema.sql`.

---

## [1.4.0] - 2026-08-21

### Suite Modul Operasional Lengkap Seluruh PJ DKM & Master Roadmap v4.0

#### Penambahan & Pembaruan (Added & Updated)
- `[ROADMAP]` Rencana induk teknis `implementation-plan.md` diperbarui ke versi v4.0 dengan spesifikasi skema dan alur kerja lengkap untuk seluruh Penanggung Jawab (PJ) Divisi DKM:
  - **PJ Media & Dakwah:** Content & Article Studio (Quill.js Rich Text, slug generator, cover image ImageKit WebP) dengan standar view publik `artikel.html` & `artikel-detail.html`, serta Dynamic Homepage Media Manager.
  - **PJ Logistik & Sarpras:** Manajemen Makan Berjamaah Gratis ba'da Dzuhur (70+ porsi/hari, logistik dapur) & Manajemen Aset/Inventaris Fisik Masjid (kode inventaris, lokasi, kondisi, servis).
  - **PJ Santri & Pendidikan:** Direktori Santri Tahfidz Al-Qur'an & Log Mutaba'ah Setoran Hafalan Harian (Subuh & Maghrib: Juz/Surat/Ayat/Tajwid) serta rapor perkembangan.
  - **PJ Musafir & Pelayanan:** Buku Tamu Musafir Digital, Izin Menginap / Istirahat 24 Jam, dan Log Penitipan Kendaraan & Loker Barang.
  - **PJ Ibadah & Acara:** Kalibrasi Waktu Shalat & Ikhtiyat, Rotasi Petugas Harian (Imam 5 waktu, Muadzin, Khatib Jumat, Bilal), Kalender Acara/Kajian Tematik & Arsip Khutbah Jumat.
  - **PJ Keuangan:** Modul Akuntansi Lengkap (Buku Kas Masuk, Buku Kas Keluar Operasional, Laporan Arus Kas, Neraca Kas Berkala, dan Ekspor CSV & Cetak PDF Transparan) serta Alur Pengajuan Anggaran (*Budget Request*) & Klaim Nota Bon (*Expense Claim*) terpusat bagi seluruh 7 PJ Divisi.
  - **PJ Keamanan:** Log Piket Keamanan 24 Jam & Formulir Laporan Kejadian/Patroli dengan unggah bukti foto/video ke ImageKit.io CDN (auto WebP/WebM).
  - **PJ Kebersihan:** Checklist Sanitasi Harian (Wudhu, Toilet, Ruang Utama, Halaman) & Formulir Laporan Kebersihan dengan unggah bukti foto/video ke ImageKit.io CDN (auto WebP/WebM).
- `[DASHBOARD]` Sinkronisasi dashboard pelacak progres visual `progress-implementation-plan.html` pada subdomain `progdev.masjidsophiajatiwarna.com` memuat seluruh modul operasional tiap PJ dalam sub-grup visual yang elegan dan mudah dipahami pengurus DKM.

---

## [1.3.0] - 2026-08-21

### Sinkronisasi Master Roadmap v3.0 (Task Management 5 View, Chat Multi-Arah, Self-Sustain CMS & Monitor 7 Pilar)

#### Pembaruan (Updated)
- `[ROADMAP]` Rencana induk teknis `implementation-plan.md` diperbarui ke versi v3.0 mencakup:
  - Arsitektur Task Management 5 View: Kanban, Gantt Timeline (`frappe-gantt`), Calendar Spanning Bars, All Tasks Table (Filter/Sort/Bulk Archive/CSV), dan Archive View per divisi.
  - Riwayat Pengelolaan Realtime (Audit Trail CRUD per PJ 100% tanpa refresh via Supabase CDC WebSocket).
  - Obrolan Koordinasi Internal Multi-Arah (semua PJ, Ketua DKM, dan Super Admin bisa saling chat via WebSocket).
  - CMS Self-Sustain Tim Masjid: Dynamic Homepage Media Manager & Page Builder melalui jalur review Ketua DKM.
  - Dashboard Pemantau Kesehatan Arsitektur 7 Pilar Cloud khusus Super Admin (Zero-Cost Free-Tier Assurance).
  - Rencana Redesign Besar Web Publik `index.html` berstandar Masjid Istiqlal Jakarta (Hero Slider, Quick Cards, Kalender Hijriah, Pengaduan Jamaah, Galeri Multimedia, dan Live Chat Coming Soon).
- `[DASHBOARD]` Sinkronisasi dashboard pelacak progres visual `progress-implementation-plan.html` pada subdomain `progdev.masjidsophiajatiwarna.com` dengan bahasa non-teknis yang mudah dipahami, pembagian sub-grup rapi, dan pelacakan persentase live.

---

## [1.2.0] - 2026-08-21

### Portal Admin DKM, Otomasi 24/7 Keep-Alive & SEO Suite (Fase 4 Admin Core)

#### Penambahan (Added)
- `[FEAT]` Portal Pengurus DKM & Employee Dashboard (`admin.html`) terisolasi di `admin.masjidsophiajatiwarna.com` dengan gerbang autentikasi aman Supabase Auth.
- `[FEAT]` Panel KPI Real-Time: Monitoring volume Sedekah Makan Dzuhur (70+ porsi), agregasi kas donasi masuk, persentase efisiensi tugas (*Task Health Rate*), dan notifikasi aspirasi jamaah.
- `[FEAT]` Task Management DKM: Papan penugasan lintas divisi (Sosial, Sarpras, Media, Santri, Keuangan) dengan penetapan PIC, prioritas, dan tenggat waktu.
- `[FEAT]` Kotak Masuk Pengaduan Jamaah: Panel pemantauan laporan fasilitas rusak dan kotak saran dari tabel `feedback_complaints`.
- `[CI/CD]` Otomasi 24/7 GitHub Actions `.github/workflows/supabase-keepalive.yml` untuk mencegah jeda otomatis pada database Supabase free tier.
- `[SEO]` Pembuatan berkas `robots.txt` dan `sitemap.xml` untuk pengindeksan Google Search Console.

---

## [1.1.0] - 2026-08-21
- `[FEAT]` Halaman muka publik lengkap (`index.html`) mengadopsi standar arsitektur web masjid besar (Benchmark: Masjid Istiqlal & Salman ITB) bertema terang resmi (*Pure White*, *Soft Cream Sand*, *Charcoal*, dan *Sophia Gold*).
- `[FEAT]` Modul hisab jadwal shalat presisi lokal Jatiwarna (Kemenag RI) dengan *Live Countdown Timer* detik demi detik, penanda visual shalat aktif (*Active Prayer Card Highlight*), dan waktu astronomis Imsak, Subuh, Terbit, Dzuhur, Ashar, Maghrib, Isya.
- `[FEAT]` Modul daftar petugas ibadah dan kajian harian/mingguan (Imam Rawatib, Muadzin, Khatib Shalat Jumat, dan Penceramah Kajian Tematik).
- `[FEAT]` Modul program filantropi terpadu: Makan Berjamaah Gratis ba'da Dzuhur (70+ porsi), Pembinaan Santri Tahfidz Al-Qur'an, Rekening BSI `7235464297` a.n. Masjid Sophia dengan fitur *1-Click Copy*, dan QRIS Merchant SEDEKAH MAKAN (NMID: `ID2025401816769`).
- `[FEAT]` Modul *Dynamic Incognito Form* untuk konfirmasi donasi dan doa jamaah instan tanpa login dengan notifikasi toast konfirmasi interaktif.
- `[FEAT]` Modul fasilitas layanan musafir 24 jam: kamar mandi/wudhu higienis, ruang istirahat, air minum gratis, dan rute strategis samping UMAR Travel.
- `[FEAT]` Grid warta kegiatan dan artikel dakwah dengan kategori, tanggal publikasi, dan estimasi waktu baca.
- `[FEAT]` Mobile-First Navigation & Floating WhatsApp Hotline: Penambahan *off-canvas drawer* sentuh untuk navigasi smartphone dan tombol melayang WhatsApp langsung ke Hotline DKM 24 jam (`0851-8835-2432`).
- `[FEAT]` Penyesuaian tata letak responsif jadwal shalat hisab Kemenag (grid 2 kolom di ponsel dengan sorotan aktif otomatis) dan box salin rekening BSI 1-Click Copy yang ramah sentuhan.
- `[MEDIA]` Penyusunan berkas acuan `assets-media-checklist.csv` berisi 18 item kebutuhan foto & video (minimum qty, rasio aspek, format) terhubung ke folder Google Drive sementara.
- `[BACKEND]` Pembuatan master migrasi SQL `database/schema.sql` (8 tabel PostgreSQL: `donations`, `jadwal_petugas`, `artikel_berita`, `team_tasks`, `system_health_logs`, `admin_users`, `media_checklists`) lengkap dengan proteksi Row Level Security (RLS) Zero-Trust dan Realtime Replication.
- `[SERVERLESS]` Implementasi suite Vercel Edge Serverless Functions: `/api/health` (pemantauan kesehatan sistem), `/api/donasi` (pencatatan donasi kode unik), dan `/api/send-receipt` (pengiriman kuitansi instan via Resend).
- `[ARCH]` Integrasi arsitektur 7 Pilar: GitHub, Vercel, Supabase, ImageKit.io (20GB Video CDN), Resend Email Gateway, Gmail Kustom, dan Google Drive.

---

## [1.0.0] - 2026-08-21

### Inisialisasi & Master Roadmap (Fase 1)

#### Penambahan (Added)
- `[INIT]` Berkas `.gitignore` standar pengamanan komprehensif untuk proyek Node.js, Vercel, Supabase local, kredensial rahasia, dan file cache.
- `[INIT]` Berkas `README.md` resmi yang mencakup arsitektur 7 pilar infrastruktur, spesifikasi teknis hisab shalat Kemenag, matriks RBAC 10 divisi pengurus DKM, struktur folder terstandarisasi, dan panduan instalasi lokal.
- `[INIT]` Berkas `implementation-plan.md` yang memuat rencana implementasi teknis lengkap dari Fase 0 (Pipeline Kurasi Aset Dokumentasi) hingga Fase 6 (Go-Live).
- `[INIT]` Berkas `progress-implementation-plan.html` sebagai antarmuka visual pelacak progres interaktif, modern, responsif, dan bebas emoji untuk pemantauan via subdomain `progdev.masjidsophiajatiwarna.com`.
- `[INIT]` Berkas `CHANGELOG.md` untuk pencatatan riwayat rilis dan pembaruan sistem.
- `[ARCH]` Standarisasi koordinat astronomis Masjid Sophia Jatiwarna (Latitude: `-6.310391`, Longitude: `106.921264`, Zona Waktu WIB / UTC+7) dengan metode hisab Kementerian Agama Republik Indonesia (Kemenag RI).
- `[ARCH]` Penetapan kanal rekening resmi Bank Syariah Indonesia (BSI `7235464297` a.n. Masjid Sophia) dan QRIS Merchant SEDEKAH MAKAN (NMID: `ID2025401816769`).
- `[ARCH]` Perancangan arsitektur Role-Based Access Control (RBAC) 10 peran pengurus DKM (Super Admin, Ketua DKM, PJ Media, PJ Logistik, PJ Santri, PJ Musafir, PJ Ibadah, PJ Keuangan, PJ Keamanan, PJ Kebersihan).
- `[CONFIG]` Panduan teknis konfigurasi Redirect 301 Cloudflare untuk pengalihan domain sekunder (`masjidsophia.com` dan `masjidsophiajatiwarna.my.id`) menuju domain utama (`masjidsophiajatiwarna.com`).
- `[CONFIG]` Panduan manual langkah demi langkah Git CLI untuk inisialisasi repositori lokal dan push perdana ke GitHub.

#### Keamanan & Tata Kelola (Security & Governance)
- `[RULES]` Penerapan aturan mutlak bebas emoji (*Strict No-Emoji Rule*) pada seluruh kode, berkas markdown, antarmuka web, dan pesan notifikasi sistem.
- `[RULES]` Penerapan gaya penulisan manusiawi (*Anti-AI Slop*) dengan bahasa Indonesia yang santun, hangat, lugas, dan berbasis fakta riil.
- `[RULES]` Penegakan tema visual terang (*Light, Warm, Clean, Serene*) berbasis palet warna resmi (`#FFFFFF`, `#F8F6F0`, `#1D1D1B`, `#E3C466`, `#C9A84C`).
- `[SECURITY]` Proteksi kredensial sensitif Supabase, Vercel, Resend, dan ImageKit dari pelacakan repositori publik.
