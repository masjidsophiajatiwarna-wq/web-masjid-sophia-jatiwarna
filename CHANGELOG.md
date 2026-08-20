# Catatan Perubahan (Changelog)

Seluruh perubahan penting pada proyek **Web Portal Masjid Musafir Sophia Jatiwarna** dicatat secara berkala dalam berkas ini.

Format penulisan mengacu pada standar [Keep a Changelog](https://keepachangelog.com/id/1.0.0/) dan prinsip [Semantic Versioning](https://semver.org/).

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
