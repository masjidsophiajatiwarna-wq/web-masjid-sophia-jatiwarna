# Rencana Implementasi: Fitur Sakelar Maintenance Mode (Under Maintenance) Terpadu

Berkas ini mendokumentasikan spesifikasi logika penalaran, arsitektur data, dan tahapan implementasi fitur **Sakelar Status Live / Under Maintenance** pada modul Visual Web Builder Beranda.

---

## 1. Logika Penalaran & Analisis Kebutuhan Sistem

### A. Latar Belakang Masalah
Pengurus DKM dan tim pengembang saat ini aktif melakukan pengujian data operasional riil (seperti jadwal petugas shalat, kajian ibadah, dan artikel) langsung di lingkungan produksi (`masjidsophiajatiwarna.com`). Konten draf uji coba seperti *"TESTING 1"* atau *"TESTING 6"* dapat terlihat oleh jamaah dan musafir umum sebelum dinyatakan siap rilis.

### B. Solusi Arsitektur
Membangun sakelar kendali status publikasi website terpadu yang dapat diatur langsung dari halaman Admin DKM (menu **Visual Web Builder Beranda**), didukung oleh basis data Supabase Realtime CDC dan halaman dedikasi pemeliharaan (`maintenance.html`).

### C. Matriks Hak Akses (RBAC)
Sakelar status situs ini bersifat sangat krusial, sehingga izin modifikasi secara ketat dibatasi hanya untuk:
- `SUPER_ADMIN` (Super Administrator Sophia)
- `SUPER_USER` (Pimpinan DKM)
- `KETUA_DKM` (Ketua DKM)
- `PJ_MEDIA` (Penanggung Jawab Media & Warta Masjid)

Peran lain (seperti PJ Keuangan, PJ Kebersihan, PJ Keamanan, dll) tidak memiliki akses untuk mengubah sakelar ini (*disabled* atau tersembunyi).

### D. Alur Intersepsi Pengunjung & Jaminan Akses Admin
1. **Penyimpanan Status:** Nilai status situs (`LIVE` atau `MAINTENANCE`) disimpan ke dalam record master Supabase `homepage_media` (kunci: `HOMEPAGE_CONFIG_MASTER`, kolom: `meta_json.site_status`).
2. **Intersepsi Jamaah Publik (`index.html`, `galeri.html`, `artikel.html`):**
   - Saat halaman dibuka, skrip membaca status konfigurasi master langsung dari Supabase (SSOT).
   - Menghilangkan ketergantungan pada `localStorage` agar tidak terjadi peramban pengunjung terjebak di mode pemeliharaan.
   - Jika status adalah `MAINTENANCE` dan pengguna **bukan tim peninjau**, peramban langsung mengalihkan pengunjung ke `/maintenance.html` via `window.location.replace('/maintenance.html')`.
   - Prinsip *Fail-Open*: jika koneksi Supabase terputus, portal default terbuka secara normal (Live).
3. **Bypass Khusus Tim Mandiri via Tombol "Buka Web Publik" (`?preview=[role]`):**
   - Tombol "Buka Web Publik" di panel admin secara dinamis menambahkan parameter peran peninjau aktif (contoh: `/?preview=pj_media`).
   - Parameter ini secara otomatis disimpan ke `sessionStorage` pada peramban peninjau sehingga tim dapat berpindah ke halaman Galeri atau Artikel tanpa terlempar ke `maintenance.html`.
   - Menampilkan baris penanda mengambang: *"Mode Pemeliharaan Aktif (Pratinjau [ROLE]): Pengunjung umum dialihkan ke maintenance.html. Anda melihat halaman ini sebagai Pratinjau Pengurus DKM. [Kelola di Admin]"*.
4. **Isolasi Portal Admin:**
   - Halaman `admin.html` (dan subdomain `admin.masjidsophiajatiwarna.com`) sepenuhnya kebal dari pengalihan ini, memastikan pengurus tidak akan pernah terkunci (*locked-out*) dan dapat mengaktifkan kembali status `LIVE` kapan pun diinginkan.

---

## 2. Rencana Implementasi Bertahap (Tabel Kerja)

| Fase | Rincian Pekerjaan | Pelaksana | Kriteria Keberhasilan (DoD) | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Phase 1** | Pembuatan Halaman Kustom `maintenance.html` | Agent (MCP) | Berkas `maintenance.html` selesai dibangun dengan identitas visual Masjid Sophia (bebas emoji, responsif, elegan, memuat maklumat santun, kontak DKM, dan auto-redirect seketika saat status LIVE). | **Selesai (100%)** |
| **Phase 2** | Penambahan Kontrol Sakelar Status di `admin.html` | Agent (MCP) | Dropdown ringkas `Live` vs `Under Maintenance` terpasang di bar aksi lebar penuh, bebas kata berulang, dilengkapi tombol pratinjau `?preview=[role]` dan indikator dot berdenyut di pojok kanan, dilindungi RBAC. | **Selesai (100%)** |
| **Phase 3** | Integrasi Logika Intersepsi & Realtime di `env-loader.js` (Supabase SSOT) | Agent (MCP) | Menggunakan Supabase murni sebagai SSOT (tanpa locking localStorage), mendukung bypass tim berbasis parameter `?preview=[role]` & `sessionStorage`. | **Selesai (100%)** |
| **Phase 4** | Audit Integritas & Pengujian Kepatuhan Sintaksis | Agent (MCP) | Pengujian `verify_index_compliance.py` lolos 100% (zero emoji, zero secret leak, clean routing). | **Selesai (100%)** |
| **Phase 5** | Sinkronisasi Paralel & Rilis ke Branch `dev` dan `main` | Agent (Git MCP) | Kode di-commit dan di-push ke branch `dev`, lalu di-merge dan di-push ke `main` untuk auto-deploy Vercel. | **Selesai (100%)** |

---

*Dokumen ini diperbarui untuk mencerminkan arsitektur final Supabase SSOT dan fitur pratinjau tim.*
