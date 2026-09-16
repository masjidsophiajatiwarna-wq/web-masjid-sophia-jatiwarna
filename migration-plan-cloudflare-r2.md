# Rencana Implementasi: Koreksi ImageKit, Merge Produksi & Migrasi Infrastruktur Opsional

Berkas ini mendokumentasikan urutan eksekusi (Implementation Plan) untuk membenahi kendala limitasi tampilan UI ImageKit, melakukan *cutover* rilis ke `main`, dan merencanakan migrasi lanjutan ke Cloudflare R2 secara kondisional (ditangguhkan).

Sesuai dengan protokol keselamatan, **setiap fase harus diselesaikan dan diverifikasi (bebas *bug*) oleh Pengguna** sebelum berpindah ke fase berikutnya.

---

## Phase 1: Koreksi Parameter Limitasi & Sinkronisasi Metrik ImageKit (Selesai)
**Status**: Selesai
**Deskripsi**: Mengatasi ketidaksesuaian data antara Galeri Media (1.90 MB), Cloud Monitor (2.1 GB), dan Analytics ImageKit Riil (34.40 MB / 121.46 MB Bandwidth). Mengubah seluruh batas kuota statis dari 20 GB storage menjadi 3 GB (DAM Storage) dan bandwidth menjadi 20 GB/bulan. Menyambungkan DOM binding dinamis pada `admin.html` dan `api/cloud-usage.js` agar metrik tidak lagi beku (hardcoded).
**Pelaksana**: Agent (Otomatis via MCP)
**Kriteria Keberhasilan (DoD)**:
- [x] Angka batas penyimpanan `20.480 MB` diubah menjadi `3.072 MB` (3 GB) pada seluruh badge dan kalkulasi progress bar.
- [x] Metrik ImageKit di Cloud Monitor disinkronkan dengan data riil ImageKit Analytics: Bandwidth 121.5 MB / 20 GB (0.6%), Storage 34.4 MB / 3 GB (1.1%), dan Transformations 716 / 20.000 (3.6%).
- [x] Backend `/api/cloud-usage.js` diperbarui agar menyajikan data dasar ImageKit yang akurat.
- [x] ID dinamis disematkan pada kartu ImageKit di `admin.html` dan diikat ke fungsi `refreshCloudMonitorMetrics()` serta `updateStorageBarStats()`.

---

## Phase 2: Persiapan Rilis & Merge ke Branch `main` (Selesai)
**Status**: Selesai (100%)
**Deskripsi**: Seluruh perbaikan (Keamanan RBAC, Keuangan Laba Rugi ISAK 35, eliminasi refresh hardcoded, dan sinkronisasi ImageKit) telah dipublikasikan ke branch `main` dan di-push ke GitHub (`origin/main`), dan telah aktif di lingkungan produksi live.
**Pelaksana**: Agent (Git Commands) & User (Review)
**Kriteria Keberhasilan (DoD)**:
- [x] Melakukan operasi `git commit` untuk perubahan UI ImageKit (commit `fd1b1a9`).
- [x] Melakukan penggabungan (*merge*) branch `dev` ke branch `main`.
- [x] Melakukan `git push origin main`.
- [x] Pengguna mengonfirmasi bahwa produksi di `masjidsophiajatiwarna.com` berjalan lancar tanpa error/regresi.

---

## Phase 3: Eksekusi Migrasi Domain Utama (`masjidsophia.com`) & Setup Email Profesional (Aktif)
**Status**: Sedang Dijalankan (Protokol Grill-Me & Penyelarasan)
**Deskripsi**: Menghubungkan arsitektur web portal ke domain baru yang lebih singkat dan resmi (`masjidsophia.com`), membangun infrastruktur email profesional gratis (inbound via Cloudflare Email Routing & outbound via Resend SMTP), menyelaraskan Supabase Auth, serta mengaktifkan 301 redirect permanen dari domain lama.
**Pelaksana**: User (Operasi Dashboard) & Agent (Panduan 1-by-1 Coaching & Codebase)
**Kriteria Keberhasilan (DoD)**:
- [ ] Verifikasi domain `masjidsophia.com` aktif di Cloudflare dengan DNS proxied ke Vercel (`cname.vercel-dns.com`).
- [ ] Domain `masjidsophia.com`, `admin.masjidsophia.com`, `progdev.masjidsophia.com`, dan `dev.masjidsophia.com` ditambahkan ke Vercel.
- [ ] Setup Cloudflare Email Routing: inbound `aspirasi@masjidsophia.com`, `info@masjidsophia.com`, `pengaduan@masjidsophia.com`, dan `saran@masjidsophia.com` otomatis diteruskan ke `masjidsophiajatiwarna@gmail.com`.
- [ ] Setup Resend SMTP: domain `masjidsophia.com` diverifikasi (DKIM, SPF, MX) di DNS Cloudflare, sender email disetel ke `info@masjidsophia.com`.
- [ ] Penyelarasan basis kode: footer `index.html`, formulir kotak aspirasi, `api/send-receipt.js`, `api/pengaduan.js`, `vercel.json`, `robots.txt`, dan `sitemap.xml`.
- [ ] Konfigurasi Supabase Authentication: update Site URL dan allow list Redirect URLs ke domain baru.
- [ ] Setup Cloudflare 301 Permanent Redirect dari `masjidsophiajatiwarna.com/*` ke `masjidsophia.com/$1`.
- [ ] Verifikasi login Admin DKM di `admin.masjidsophia.com` sukses tanpa error CORS/redirect.
- [ ] Verifikasi kirim dan terima email profesional berjalan lancar.

---

## Phase 4: Migrasi Media Storage ke Cloudflare R2 (Ditangguhkan / Opsional)
**Status**: DITANGGUHKAN (Menunggu Metode Pembayaran Cloudflare)
**Deskripsi**: Rencana awal untuk memindahkan aset gambar dari ImageKit ke Cloudflare R2 terhambat karena R2 mewajibkan penautan metode pembayaran kartu kredit/debit untuk mencegah penyalahgunaan tier gratis (10 GB). Oleh karena itu, langkah ini diletakkan di akhir dan bersifat opsional hingga persyaratan tersebut terpenuhi.
**Pelaksana**: User & Agent
**Kriteria Keberhasilan (DoD)**:
- [ ] Pengguna telah mendaftarkan *Payment Method* di Cloudflare.
- [ ] Kredensial *S3 Access Key* untuk Bucket R2 telah diserahkan kepada Agent.
- [ ] Agent membangun *script* migrasi Python dan memindahkan aset dari ImageKit ke R2 (beserta pembaruan referensi URL di HTML & Database).
