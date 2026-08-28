# Web Portal Resmi Masjid Musafir Sophia Jatiwarna

Portal web resmi dan pusat layanan informasi digital terintegrasi untuk Masjid Musafir Sophia Jatiwarna. Dibangun dengan arsitektur modern berbasis performa tinggi, keterbukaan informasi publik, kemudahan akses bagi para musafir dan pejuang nafkah, serta sistem manajemen operasional internal DKM yang komprehensif.

---

## 1. Ikhtisar & Identitas Brand

- **Nama Resmi:** Masjid Musafir Sophia Jatiwarna (Masjid Sophia)
- **Tagline:** Rumah Singgah Ibadah, Ladang Amal Kebaikan
- **Lokasi:** Jl. Raya Hankam, RT.001/RW.011, Jatiwarna, Kec. Pondok Melati, Kota Bekasi, Jawa Barat 17415
- **Titik Koordinat Astronomis:** Latitude `-6.310391`, Longitude `106.921264` (Zona Waktu: WIB / UTC+7)
- **Titik Patokan:** Samping Ruko Gate 2 Kodau / UMAR Travel
- **Hotline WhatsApp:** 0851-8835-2432
- **Email Resmi:** masjidsophiajatiwarna@gmail.com
- **Domain Utama:** [masjidsophiajatiwarna.com](https://masjidsophiajatiwarna.com)
- **Domain Sekunder (Redirect 301):** `masjidsophiajatiwarna.my.id`, `masjidsophia.com`

---

## 2. Arsitektur 7 Pilar Infrastruktur

Sistem portal ini mengadopsi standar arsitektur 7 pilar untuk memastikan keandalan, keamanan, dan skalabilitas jangka panjang:

| Pilar | Komponen / Layanan | Peran & Tanggung Jawab |
| :---: | :--- | :--- |
| **1** | **GitHub** | Manajemen kode sumber terpusat, version control, issue tracking, dan automasi CI/CD. |
| **2** | **Vercel** | Hosting global edge network, automated deployment, zero-downtime release, SSL/TLS, dan routing subdomain. |
| **3** | **Supabase** | Backend Database (PostgreSQL), autentikasi terkelola, Row Level Security (RLS) zero-trust, dan fungsi RPC. |
| **4** | **ImageKit.io** | CDN media global, kompresi otomatis format WebP/AVIF, on-the-fly image resizing, dan secure upload. |
| **5** | **Resend.com** | Gateway pengiriman email transaksional, tanda terima donasi otomatis, dan integrasi DKIM/SPF/DMARC. |
| **6** | **Gmail Integration** | Email bisnis terverifikasi, sistem forwarding terkelola, dan komunikasi resmi DKM. |
| **7** | **Google Drive** | Penyimpanan arsip media resolusi tinggi, rekaman kajian, dan backup berkas database historis. |

---

## 3. Fitur Utama & Spesifikasi Teknis

### A. Portal Publik & Layanan Umat

1. **Jadwal Shalat Presisi Lokal Jatiwarna, Kota Bekasi:**
   - Perhitungan hisab astronomis presisi sesuai titik koordinat Masjid Sophia (`-6.310391, 106.921264`).
   - Mengadopsi standar hisab resmi Kementerian Agama Republik Indonesia (Kemenag RI).
   - Menampilkan waktu Imsak, Subuh, Terbit/Syuruq, Dzuhur, Ashar, Maghrib, dan Isya.
   - Penghitung waktu mundur langsung (*live countdown timer*) menuju jadwal shalat berikutnya.
   - Penanda visual waktu shalat yang sedang berlangsung (*active prayer highlight*).
   - Panel kalibrasi manual menit waktu (*ikhtiyat*) terpusat melalui Admin Panel.

2. **Rotasi Petugas Ibadah & Kajian:**
   - Penjadwalan rotasi harian dan mingguan untuk Imam Rawatib aktif/berikutnya, Muadzin bertugas, Khatib Shalat Jumat, dan Penceramah Kajian Tematik.
   - Pembaruan berkala terstruktur oleh pengurus DKM.

3. **Pusat Informasi Filantropi & Donasi Umat:**
   - **Program Unggulan:** Makan Berjamaah Gratis ba'da Dzuhur (target harian 70+ porsi).
   - **Program Pembinaan:** Santri Penghafal Al-Qur'an (Tahfidz) & Pemakmuran Masjid.
   - **Rekening Bank Resmi:** Bank Syariah Indonesia (BSI) `7235464297` a.n. Masjid Sophia (dilengkapi fitur 1-Click Copy).
   - **Kanal Pembayaran QRIS:** Merchant SEDEKAH MAKAN (NMID: `ID2025401816769`), mendukung seluruh aplikasi e-wallet dan mobile banking.
   - **Formulir Konfirmasi Donasi Dinamis (Incognito):** Pengiriman data donasi dan doa tanpa kewajiban registrasi akun dengan keamanan Supabase RLS.

4. **Layanan & Fasilitas Musafir 24 Jam:**
   - Informasi ketersediaan ruang istirahat, fasilitas air wudhu/toilet bersih 24 jam, air minum gratis, dan titik lokasi strategis berdampingan dengan UMAR Travel.

5. **Kanal Berita, Artikel Dakwah & Informasi Kegiatan:**
   - Publikasi artikel dakwah, panduan ibadah, dokumentasi kegiatan penyaluran donasi, dan pengumuman resmi DKM.

---

### B. Dashboard Operasional DKM & Manajemen Tugas

Diadaptasi dari benchmark sistem tata kelola modern (SIABE-PORTO & WEB-UMAR):

1. **Manajemen Tugas Terpadu (Task Management Engine):**
   - **Kanban Board:** Pengelompokan tugas berdasarkan status (Belum Dimulai, Sedang Berjalan, Dalam Review, Selesai).
   - **Timeline / Gantt View:** Visualisasi jadwal kerja dan batas waktu program operasional.
   - **Table View:** Daftar tugas tabular dengan opsi pencarian, filter penanggung jawab, dan prioritas.
   - **Archive Task:** Pengarsipan otomatis tugas yang telah selesai.
   - **Internal Chat:** Ruang komunikasi koordinasi internal antar-pengurus DKM per tugas.

2. **Article & Event Studio CMS:**
   - Editor teks terstruktur (Rich Text Editor) untuk menyusun berita, rilis kegiatan, dan agenda kajian.
   - Otomasi pembuatan slug URL unik, deskripsi meta SEO, dan upload gambar via CDN ImageKit.

3. **Manajemen Kas & Rekonsiliasi Donasi:**
   - Pencatatan arus kas masuk dan keluar (pembelian bahan makanan, operasional listrik/air, santunan santri).
   - Verifikasi bukti transfer donatur dan ekspor laporan keuangan berkala.

---

## 4. Matriks Akses Pengguna (Role-Based Access Control / RBAC)

Sistem menerapkan pembagian kewenangan ketat berbasis 10 peran pengurus:

| Peran Pengurus | Penanggung Jawab | Cakupan Wewenang Utama |
| :--- | :--- | :--- |
| **Super Admin** | Habib Maulana | Akses penuh sistem, database, konfigurasi API, routing DNS, dan tata kelola akun. |
| **Ketua DKM** | Pak Dicky | Akses eksekutif laporan keuangan, persetujuan program, pengumuman resmi, dan jadwal ibadah. |
| **PJ Media & Publikasi** | Divisi Media | Pengelolaan CMS artikel, dokumentasi foto/video kegiatan, dan informasi publik. |
| **PJ Logistik & Makan Gratis** | Divisi Konsumsi | Manajemen stok bahan makanan, pencatatan porsi harian, dan logistik dapur berkah. |
| **PJ Santri & Tahfidz** | Divisi Pendidikan | Monitoring absensi santri, mutaba'ah hafalan Qur'an, dan kebutuhan operasional asrama. |
| **PJ Layanan Musafir & Fasilitas** | Divisi Pelayanan | Buku tamu digital musafir, kontrol fasilitas 24 jam, dan penanganan masukan jamaah. |
| **PJ Ibadah Harian** | Divisi Peribadatan | Kalibrasi waktu shalat (ikhtiyat), rotasi imam rawatib, muadzin, khatib Jumat, dan penceramah. |
| **PJ Akuntansi & Keuangan** | Divisi Keuangan | Pembukuan kas, rekonsiliasi transfer BSI dan transaksi QRIS, serta ekspor laporan berkala. |
| **PJ Keamanan** | Divisi Keamanan | Jadwal piket jaga malam, pengawasan lingkungan masjid, dan log keamanan 24 jam. |
| **PJ Kebersihan** | Divisi Sanitasi | Checklist sanitasi berkala ruang shalat utama, tempat wudhu, toilet, dan fasilitas sanitasi. |

---

## 5. Struktur Direktori Proyek

```text
masjid-sophia/
|-- .agent/                             # Protokol agentic AI, rules, dan standarisasi ECC
|-- .dummy_html/                        # Berkas acuan tata letak awal dan template rujukan
|-- .unused-modul-web-sophia/           # Katalog modul terstandarisasi untuk ekspansi masa depan
|-- asset/                              # Aset statis terverifikasi
|   |-- favicon/                        # Favicon multi-ukuran (logo-black & logo-white)
|   |-- logo/                           # Logo resmi vektor (.svg) dan raster (.png)
|-- css/                                # Lembar gaya visual (Design System, Light Theme)
|-- js/                                 # Logika modular (Hisab Shalat, Countdown, Supabase Client)
|-- .gitignore                          # Konfigurasi pengabaian berkas rahasia dan cache
|-- BRAND_GUIDE.md                      # Panduan identitas visual resmi dan aturan penulisan
|-- CHANGELOG.md                        # Catatan riwayat versi rilis sistem
|-- Master-Fullstack-Web-App-Services-v1.md # Master blueprint arsitektur layanan web
|-- implementation-plan.md              # Rencana teknis komprehensif dari Fase 0 hingga Go-Live
|-- progress-implementation-plan.html   # Antarmuka web pelacak progres dan roadmap interaktif
|-- index.html                          # Landing page portal publik Masjid Sophia
|-- admin.html                          # Web dashboard terpadu DKM & manajemen tugas
|-- artikel.html                        # Direktori artikel, panduan dakwah, dan kabar kegiatan
|-- artikel-detail.html                 # Halaman baca artikel dengan metadata SEO OpenGraph
|-- 404.html                            # Halaman penanganan rute tidak ditemukan
|-- robots.txt                          # Direktif perayapan mesin pencari
|-- sitemap.xml                         # Peta situs terstruktur untuk indeksasi Google & Bing
|-- vercel.json                         # Konfigurasi edge routing, header keamanan, dan subdomain
`-- README.md                           # Dokumentasi komprehensif repositori (berkas ini)
```

---

## 6. Standar Visual & Penulisan Mutlak

1. **Aturan Bebas Emoji (Strict No-Emoji):**
   Dilarang keras menggunakan emoji grafis pada kode, berkas markdown, teks tombol antarmuka, dan pesan notifikasi sistem. Gunakan ikon vektor SVG profesional (Lucide / Font Awesome) atau badge status formal (`[INFO]`, `[REKENING RESMI]`, `[SELESAI]`, `[AKTIF]`).

2. **Gaya Penulisan Manusiawi (Anti-AI Slop):**
   Seluruh teks disusun menggunakan Bahasa Indonesia yang hangat, santun, lugas, mengalir, dan berbasis data riil tanpa frasa klise atau hiperbolis.

3. **Tema Visual Terang (Light, Warm, Clean & Serene):**
   Menggunakan palet warna terang resmi: Pure White (`#FFFFFF`), Soft Cream Sand (`#F8F6F0`), Charcoal Text (`#1D1D1B`), dan aksen Sophia Gold (`#E3C466` & `#C9A84C`).

4. **Tipografi Modern & Kaligrafi Standar:**
   Menggunakan font `Inter` atau `Plus Jakarta Sans` untuk teks antarmuka dan font `Amiri` untuk teks berbahasa Arab atau dalil doa.

---

## 7. Panduan Instalasi & Pengembangan Lokal

### Prasyarat
- Peramban web modern (Google Chrome, Mozilla Firefox, Microsoft Edge, atau Safari).
- Node.js (versi 18 LTS atau lebih baru) dan `npm` (opsional untuk menjalankan local server atau build tooling).
- Git CLI terkonfigurasi pada mesin lokal.

### Langkah Menjalankan
1. Kloning repositori dari GitHub:
   ```bash
   git clone https://github.com/masjidsophiajatiwarna-wq/web-masjid-sophia-jatiwarna.git
   cd masjid-sophia
   ```

2. Jalankan server lokal:
   - Menggunakan Python:
     ```bash
     python -m http.server 3000
     ```
   - Atau menggunakan Live Server / `npx serve`:
     ```bash
     npx serve .
     ```

3. Buka peramban dan akses alamat `http://localhost:3000`.

---

## 8. Pengujian Otomatis (Automated Testing Suite)

Repositori ini telah dilengkapi dengan testing suite berbasis modul bawaan Node.js (`node:test` & `node:assert/strict`) tanpa dependensi berat eksternal:

### Menjalankan Seluruh Pengujian di Terminal:
```bash
npm test
```

### Menjalankan Pengujian dalam Mode Watch (Otomatis jalan saat file disimpan):
```bash
npm run test:watch
```

### Cakupan Pengujian (Test Suites):
1. **API Contract Verification (`tests/api_contract.test.js`):** Memvalidasi keberadaan `API_CONTRACT.md`, kelengkapan endpoint, dan penguncian isolasi Supabase Project ID `fcwajbemkbhkogwtqcmx`.
2. **Serverless Donasi Ingestion (`tests/api_donasi.test.js`):** Menguji validasi nominal, format nomor WhatsApp, kode unik 3 digit, dan perlindungan incognito.
3. **Serverless Aspirasi & Pengaduan (`tests/api_pengaduan.test.js`):** Menguji sanitasi payload, penolakan input kosong, dan pencatatan ke database.
4. **Serverless Health & Storage Monitor (`tests/api_health.test.js`):** Menguji laporan kesehatan 4 pilar dan penguncian project ref `fcwajbemkbhkogwtqcmx`.
5. **Hisab Shalat & Ikhtiyat Kemenag (`tests/hisab_shalat.test.js`):** Menguji algoritma astronomis jadwal shalat Jatiwarna (-6.310391, 106.921264, WIB) dan akurasi kalibrasi ikhtiyat +2 menit.

---

## 9. Panduan Kontribusi & Alur Rilis

1. Buat branch baru untuk setiap fitur atau perbaikan:
   ```bash
   git checkout -b feat/nama-fitur
   ```
2. Pastikan seluruh pengujian otomatis lulus (`npm test` mengembalikan status hijau / exit code 0).
3. Pastikan kode mematuhi aturan penulisan dan bebas dari emoji.
4. Gunakan format pesan commit terstandarisasi:
   - `feat: [deskripsi fitur baru]`
   - `fix: [deskripsi perbaikan kendala]`
   - `docs: [deskripsi pembaruan dokumentasi]`
   - `test: [deskripsi penambahan atau perbaikan pengujian]`
   - `refactor: [deskripsi restrukturisasi kode]`
5. Buat Pull Request ke branch `main` untuk peninjauan dan integrasi otomatis ke Vercel serta GitHub Actions CI.

---

## 10. Lisensi & Hak Cipta

Seluruh kode sumber, dokumentasi, dan aset visual dalam repositori ini dikembangkan khusus untuk kepentingan operasional dan dakwah sosial **Masjid Musafir Sophia Jatiwarna**. Hak cipta dilindungi oleh DKM Masjid Sophia Jatiwarna dan mitra pengembang.
