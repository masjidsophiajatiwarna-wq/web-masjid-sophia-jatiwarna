# Catatan Perubahan (Changelog)

Seluruh perubahan penting pada proyek **Web Portal Masjid Musafir Sophia Jatiwarna** dicatat secara berkala dalam berkas ini.

Format penulisan mengacu pada standar [Keep a Changelog](https://keepachangelog.com/id/1.0.0/) dan prinsip [Semantic Versioning](https://semver.org/).

---

## [1.1.0] - 2026-08-21

### Web Portal Publik Resmi (Benchmark Istiqlal) & Pemisahan Portal Admin (Fase 3 Frontend)

#### Penambahan (Added)
- `[FEAT]` Halaman muka publik lengkap (`index.html`) mengadopsi standar arsitektur web masjid besar (Benchmark: Masjid Istiqlal & Salman ITB) bertema terang resmi (*Pure White*, *Soft Cream Sand*, *Charcoal*, dan *Sophia Gold*).
- `[FEAT]` Modul hisab jadwal shalat presisi lokal Jatiwarna (Kemenag RI) dengan *Live Countdown Timer* detik demi detik, penanda visual shalat aktif (*Active Prayer Card Highlight*), dan waktu astronomis Imsak, Subuh, Terbit, Dzuhur, Ashar, Maghrib, Isya.
- `[FEAT]` Modul daftar petugas ibadah dan kajian harian/mingguan (Imam Rawatib, Muadzin, Khatib Shalat Jumat, dan Penceramah Kajian Tematik).
- `[FEAT]` Modul program filantropi terpadu: Makan Berjamaah Gratis ba'da Dzuhur (70+ porsi), Pembinaan Santri Tahfidz Al-Qur'an, Rekening BSI `7235464297` a.n. Masjid Sophia dengan fitur *1-Click Copy*, dan QRIS Merchant SEDEKAH MAKAN (NMID: `ID2025401816769`).
- `[FEAT]` Modul *Dynamic Incognito Form* untuk konfirmasi donasi dan doa jamaah instan tanpa login dengan notifikasi toast konfirmasi interaktif.
- `[FEAT]` Modul fasilitas layanan musafir 24 jam: kamar mandi/wudhu higienis, ruang istirahat, air minum gratis, dan rute strategis samping UMAR Travel.
- `[FEAT]` Grid warta kegiatan dan artikel dakwah dengan kategori, tanggal publikasi, dan estimasi waktu baca.
- `[FEAT]` Mobile-First Navigation & Floating WhatsApp Hotline: Penambahan *off-canvas drawer* sentuh untuk navigasi smartphone dan tombol melayang WhatsApp langsung ke Hotline DKM 24 jam (`0851-8835-2432`).
- `[FEAT]` Penyesuaian tata letak responsif jadwal shalat hisab Kemenag (grid 2 kolom di ponsel dengan sorotan aktif otomatis) dan box salin rekening BSI 1-Click Copy yang ramah sentuhan.
- `[ARCH]` Penegasan pemisahan arsitektur (*Decoupling*): Halaman depan publik murni melayani jamaah dan musafir tanpa mengekspos tombol atau tautan portal admin. Portal Admin DKM diisolasi tertutup melalui subdomain `admin.masjidsophiajatiwarna.com`.

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
