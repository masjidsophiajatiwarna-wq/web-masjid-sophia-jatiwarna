# Catatan Perubahan (Changelog)

Seluruh perubahan penting pada proyek **Web Portal Masjid Musafir Sophia Jatiwarna** dicatat secara berkala dalam berkas ini.

Format penulisan mengacu pada standar [Keep a Changelog](https://keepachangelog.com/id/1.0.0/) dan prinsip [Semantic Versioning](https://semver.org/).

## [1.7.2] - 2026-08-22

### Mobile Grabber Table Engine, 3-Tier Activity Presence, Single-Write Login, dan Modal Scroll-Lock

#### Penambahan & Pembaruan (Added & Updated)
- `[TABLE_DRAG_GRABBER]` Menambahkan fungsionalitas **Drag-to-Scroll (Grabber Engine)** pada seluruh kontainer tabel `.table-responsive` dengan kursor interaktif `grab` / `grabbing` serta dukungan *fluid native touch scroll* untuk kenyamanan navigasi perangkat seluler (*Mobile-First UI*).
- `[ACTIVITY_PRESENCE_3TIER]` Mengimplementasikan arsitektur *Activity Event-Listener* berbasis standar SIABE-PORTO (Zero Server Overhead):
  - **🟢 Online:** Pengurus aktif berinteraksi di portal dalam waktu $< 1$ jam.
  - **🟡 Idle (Standby):** Tidak ada interaksi selama $1$ hingga $3$ jam.
  - **⚪ Offline:** Tidak ada aktivitas $> 3$ jam atau belum login.
  - **Inactivity Timeout:** Sesi otomatis diakhiri dan dipaksa logout setelah 3 jam pasif total demi keamanan data DKM.
- `[SINGLE_WRITE_LOGIN_BROADCAST]` Menghilangkan *polling/heartbeat* berulang: Pembaruan `last_login` ke database Supabase hanya dieksekusi 1 kali saat proses login, disertai siaran instan WebSocket `USER_LOGIN_EVENT` yang menyinkronkan status online ke seluruh browser/tab pengurus lain secara instan tanpa *refresh*.
- `[ACTION_BUTTON_SIMPLIFICATION]` Menyederhanakan label tombol aksi tabel akun menjadi **`Edit`** (ikon `fa-user-pen`) untuk tampilan tabel yang lebih ringkas dan proporsional.
- `[MODAL_BODY_SCROLL_LOCK]` Mengunci scroll latar belakang halaman (`overflow: hidden`) secara serempak saat modal popup mana pun terbuka, dan memulihkannya kembali saat seluruh modal ditutup.

---

## [1.7.1] - 2026-08-22

### Perbaikan Modal Dialog Box Account Control, Deteksi Status Online, dan Log Login Terakhir

#### Perbaikan Bug (Fixed)
- `[MODAL_OVERLAY_NESTING]` Memperbaiki penutupan tag HTML `#task-detail-modal` yang sebelumnya menyebabkan seluruh modal dialog box Manajemen Pengguna (`#modal-admin-add-user`, `#modal-admin-edit-user`, `#modal-confirm-reset-user`, `#modal-user-self-profile`) terjebak di dalam kontainer yang tersembunyi. Seluruh popup kini dapat dibuka dan diklik dengan sempurna.
- `[STATUS_ONLINE_DETECTION]` Memperbaiki indikator status keaktifan pengurus: Pengguna yang sedang login aktif ditandai dengan badge hijau **Online** (`live-dot`), sementara akun yang tidak sedang aktif ditampilkan dengan badge abu-abu **Offline** secara presisi.
- `[LOGIN_TIMESTAMP_TRACKING]` Sinkronisasi waktu login terakhir secara realtime: Akun yang sedang aktif otomatis menampilkan log waktu login hari ini (`Sedang Aktif`), serta menghapus teks `(Realtime)` pada kepala kolom tabel sesuai preferensi estetika antarmuka.

---

## [1.7.0] - 2026-08-22

### Modul Manajemen Pengguna DKM (Account Control), Dynamic RBAC Matrix, dan Profil Mandiri Pengurus

#### Penambahan & Pembaruan (Added & Updated)
- `[ACCOUNT_CONTROL]` Menambahkan modul **Manajemen Pengguna DKM (Account Control)** eksklusif untuk **Super Admin (Akses Penuh)** dan **Ketua DKM (Akses Baca & Kelola)**:
  - **Isolasi Ketat:** Akun `SUPER_USER` (Testing/QA) dan seluruh akun PJ Divisi (Media, Logistik, dll.) **terkunci 100%** dari menu dan tabel Manajemen Pengguna, baik via desktop maupun PWA seluler.
  - **Tabel Direktori Master (`public.admin_users`):** Menggunakan tabel database Supabase yang sudah ada (tidak dihapus/replace) dengan live CDC WebSocket untuk melacak status aktif dan waktu login terakhir secara realtime (*zero refresh*).
  - **Fitur Reset Akun ke Default:** Mengembalikan akun target (misal saat PIC lama mengundurkan diri/resign) persis ke kredensial baku awal di `AKUN_PENGURUS_DKM.txt` (`media@masjidsophiajatiwarna.com`, password `SophiaJatiwarna2026!`, nama baku) serta memutus sesi aktif PIC lama seketika (*Force Logout*).
  - **Auto-Pattern Generator Akun Multi-PJ:** Form penambahan akun secara otomatis menghasilkan pola email terstandarisasi (`media2@...`, `logistik2@...`, dst.) dan password default `SophiaJatiwarna2026!`.
  - **Matriks Hak Akses Granular 17 Modul (Gambar 1):** Pengaturan izin per modul (`Penuh`, `Baca`, `Request`, `Review`, `Laporan`, `Kajian`, `Persetujuan`, `Tidak Ada Akses`) yang tersimpan dinamis dalam kolom `permissions` JSONB.
  - **End Session / Paksa Logout Realtime:** Mengirim siaran WebSocket `FORCE_LOGOUT` untuk mengakhiri sesi aktif pengurus secara instan.
- `[SELF_SERVICE_PROFILE]` Menambahkan **Modal Profil & Keamanan Mandiri** (Standar Gambar 5) untuk seluruh pengurus DKM:
  - **Tab General Profile:** Mengubah Nama Lengkap dan Upload Foto Profil (Avatar) yang dikompresi ke WebP 400x400.
  - **Tab Security & Login:** Ganti kata sandi (`UPDATE PASSWORD & LOGOUT`) dan ganti email (`UPDATE EMAIL & LOGOUT`) dengan aturan keamanan wajib: **Sesi otomatis diakhiri dan dialihkan ke layar login**.
- `[ROADMAP_SYNC]` Sinkronisasi paralel ke `implementation-plan.md` dan `progress-implementation-plan.html`.

---

## [1.6.9] - 2026-08-22

### Perbaikan ReferenceError escapeHtml pada Rendering Kalender Bulanan

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[REFERENCE_ERROR FIX]` Menambahkan deklarasi fungsi utilitas sanitasi teks `escapeHtml(str)` di berkas `admin.html` untuk mengamankan judul tugas sebelum disematkan ke dalam elemen `.cal-span-bar`.
- `[CALENDAR RENDERING VERIFICATION]` Memastikan seluruh batang multi-hari (*continuous spanning bars*) dan baris pekan kalender bulan Agustus & September 2026 langsung termuat sempurna tanpa *uncaught exception* di konsol peramban.

---

## [1.6.8] - 2026-08-22

### Implementasi Arsitektur Kalender 2-Layer Matrix & Continuous Spanning Bar Baku (Benchmark: SIABE-PORTO)

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[2-LAYER MATRIX CALENDAR ARCHITECTURE]` Restrukturisasi total antarmuka kalender bulanan mengikuti standar arsitektur teruji dari `SIABE-PORTO`:
  - **Baris Pekan Terpisah (`.cal-week-row`):** Grid bulan kini dipecah menjadi kontainer baris mingguan terpisah (7 hari per baris).
  - **Lapisan Dasar Latar Belakang (`.cal-week-bg-grid`):** Menampilkan nomor tanggal, penanda Hari Ini, batas sel, interaksi klik tanggal, dan seleksi rentang *drag & hold*.
  - **Lapisan Acara & Bar Tugas (`.cal-week-events-layer`):** Lapisan transparan di atas background dengan `pointer-events: none` yang memuat seluruh batang tugas.
- `[SEAMLESS SINGLE-ELEMENT SPANNING BARS]`
  - Tugas berdurasi multi-hari (misal: 3 September – 1 Oktober) dirender sebagai **1 elemen batang solid bersambung (`.cal-span-bar`)** yang melintang langsung melintasi beberapa kolom menggunakan CSS `grid-column: start / end`.
  - Tidak ada lagi pemotongan bar menjadi fragmen kecil atau garis tipis di setiap sel perantara.
- `[COLLISION-FREE VERTICAL SLOTTING ALGORITHM]`
  - Implementasi algoritma pemetaan slot matriks dari `SIABE-PORTO` untuk menyusun tugas-tugas yang beririsan secara bertingkat (*Slot 1, Slot 2, Slot 3*) via `grid-row: slot` tanpa tumpang tindih.
- `[ACROSS-WEEK CONTINUATION INDICATORS]`
  - Tugas yang berlanjut dari pekan sebelumnya secara otomatis menampilkan penanda `&rarr; [PIC] Judul Tugas` dengan sudut kiri rata (`.continues-prev`).
  - Tugas yang berlanjut ke pekan berikutnya menampilkan sudut kanan rata (`.continues-next`).
- `[MASJID SOPHIA THEMED COLORING]`
  - Batang tugas dipadukan dengan palet warna resmi Masjid Sophia (*Pending = Soft Slate #E2E8F0, In Progress/Review = Amber/Gold Gradient, Completed = Emerald Green, Overdue = Crimson Red*).

---

## [1.6.7] - 2026-08-22

### Perbaikan CSS Parser Selector dan Pemulihan Utuh Tampilan Grid Kalender Bulanan

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[CSS SELECTOR SYNTAX CLEANUP]` Menghilangkan selektor duplikat `.gantt-wrapper {` yang tidak tertutup di berkas `admin.html` yang sempat menghentikan parser CSS browser untuk blok-blok gaya setelahnya.
- `[CALENDAR STYLING RESTORATION]` Memulihkan 100% tampilan visual antarmuka **Kalender Tugas Bulanan**:
  - Header navigasi bulan & tahun (`.calendar-header-bar`) kembali rapi dan proporsional.
  - Grid 7 kolom terkunci (`.calendar-grid`) dari Senin hingga Ahad tampil presisi dengan batas garis yang bersih.
  - Sel tanggal, penanda Hari Ini (`.today`), efek seleksi rentang *drag & hold* (`.selected-range`), serta batang *continuous multi-day spanning bars* (`.multi-day-start`, `.multi-day-mid`, `.multi-day-end`) aktif dan berfungsi sempurna.
- `[AUTOMATED CSS SYNTAX VALIDATION]` Menambahkan skrip verifikasi otomatis Node.js untuk memvalidasi keseimbangan seluruh kurung kurawal `{}` dan sintaksis CSS di seluruh blok `<style>`.

---

## [1.6.6] - 2026-08-22

### Split-Pane Gantt Layout, Zero-Leakage Task Sidebar, Interaktif Drag-to-Scroll Pan, dan Auto-Centered Today View

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[SPLIT-PANE GANTT ARCHITECTURE]` Restrukturisasi total tata letak Gantt Chart dari tabel tunggal menjadi arsitektur modern dua panel (*Split-Pane Layout*):
  - **Panel Kiri (Daftar Tugas Tetap / Fixed Sidebar):** Lebar 250px (Desktop) / 140px (Mobile) dengan latar solid putih, menampilkan Judul Tugas, badge divisi, dan PIC. Fisik kolom terpisah penuh dari timeline.
  - **Panel Kanan (Timeline Garis Waktu):** Area horizontal yang dapat digeser secara leluasa tanpa menggeser nama tugas di panel kiri.
- `[ZERO-LEAKAGE FIX]` Menghilangkan bug tembus/bocornya batang timeline (`.gantt-bar`) ke bawah kolom teks PIC & Judul Tugas melalui pemisahan kontainer independen dengan `z-index: 10` dan *solid border barrier*.
- `[COMFORTABLE DAILY COLUMN WIDTH & AUTO-CENTER]`
  - Menghilangkan pemaksaan 31 hari mampat dalam satu layar sempit.
  - Setiap kolom hari kini memiliki lebar proporsional yang lapang dan mudah dibaca (55px di Desktop, 48px di Mobile / Android).
  - Tampilan otomatis memusatkan (*auto-center*) posisi gulir pada **Hari Ini** saat pertama kali dibuka, sehingga pengguna langsung melihat 14–15 hari di sekitar tanggal aktif pada Desktop (atau 7 hari pada Android) tanpa teks terhimpit.
- `[INTERACTIVE DRAG-TO-SCROLL & TOUCH PAN]`
  - Menambahkan interaksi geser kursor halus (*grab-to-scroll*) menggunakan mouse drag di Desktop dan *smooth touch swipe* di Android/HP.
  - Menerapkan `user-select: none;` pada header tanggal dan kisi grid sehingga menggeser timeline tidak lagi memicu seleksi blok biru (*text selection block*) yang mengganggu.

---

## [1.6.5] - 2026-08-22

### Standarisasi ISO 8601 Gantt Timeline, Kalender Continuous Spanning Bar, Drag & Hold Range Selection, dan Validasi Kronologis Tanggal

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[ISO 8601 WEEK NUMBERING GANTT]` Standarisasi perhitungan skala mingguan Gantt Chart menggunakan algoritma baku ISO 8601 (`getISOWeekNumber`):
  - Penomoran pekan dihitung matematis dari 1 Januari (pekan yang memuat hari Kamis pertama / 4 Januari adalah W01).
  - Kolom mingguan berformat standar internasional: `W33 (10 - 16 Agu)`, `W34 (17 - 23 Agu)`, `W35 (24 - 30 Agu)`, `W36 (31 Agu - 6 Sep)`, dst.
- `[GANTT NAVIGATION & AUTO-FIT]` Penambahan kontrol navigasi dan skala fleksibel pada toolbar Gantt:
  - Tombol navigasi periode: `< Prev`, `Hari Ini / Bulan Ini`, dan `Next >`.
  - Tombol **"Auto-Fit Semua Tugas"**: Otomatis mendeteksi tanggal mulai terawal dan tenggat akhir terjauh dari seluruh tugas aktif (September, Desember, maupun tahun depan) sehingga seluruh jadwal langsung terlihat utuh dalam satu layar tanpa terpotong.
  - Tiga pilihan skala waktu: Harian (30/31 hari penuh bulan kalender), Mingguan (12 pekan ISO 8601), dan Bulanan (12 bulan kalender tahun berjalan).
- `[CONTINUOUS MULTI-DAY SPANNING BAR IN CALENDAR]` Restrukturisasi rendering kalender bulanan (Standar Portosiabe Pro):
  - Tugas berdurasi panjang (*multi-day tasks*, seperti rentang 3 September s/d 1 Oktober) dirender sebagai **satu batang horizontal menyambung (*continuous spanning bar*)** di setiap baris pekan yang dilewati dengan sudut melengkung (*pill styling*) di pangkal & ujung, serta penanda kelanjutan tanpa duplikasi badge chip chip berulang.
- `[CALENDAR 7-COLUMN GRID LOCK]` Penguncian CSS `.calendar-grid` menggunakan `grid-template-columns: repeat(7, minmax(0, 1fr))` dan `min-width: 0` pada seluruh sel dan header hari:
  - Menjamin kolom Senin s/d Ahad tampil proporsional 100% (14.28% per kolom) di semua bulan (termasuk Agustus dan September) tanpa ada sel yang tergeser atau terpotong akibat judul tugas yang panjang.
- `[DRAG & HOLD DATE RANGE SELECTION]` Fitur seleksi tanggal interaktif:
  - Pengguna dapat melakukan klik, tahan, dan geser (*drag & hold*) melintasi beberapa tanggal di kalender dengan efek visual *gold highlight* (`.selected-range`).
  - Melepas klik mouse otomatis membuka modal pembuatan tugas dengan *Tanggal Mulai* dan *Tenggat Waktu Selesai* yang langsung terisi sesuai rentang hari yang diseleksi.
- `[STRICT DATE CHRONOLOGICAL VALIDATION]`
  - Sinkronisasi batasan real-time: Memilih *Tanggal Mulai* otomatis menetapkan `min` pada *Tenggat Waktu*, dan menyesuaikan tanggal tenggat jika lebih awal dari tanggal mulai.
  - Pengecekan ketat di `handleSaveTask()` yang menolak penyimpanan dan menampilkan peringatan jika tenggat waktu selesai lebih awal dari tanggal mulai.

---

## [1.6.4] - 2026-08-22

### Penyempurnaan Presisi Ikon Sidebar, Diferensiasi Ikon Kotak Saran, dan Tombol Collapse Internal Chevron

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[ICON CENTERING FIX]` Menghilangkan elemen pembungkus ekstra (*inner div*) pada tombol navigasi **Chat Koordinasi DKM** di sidebar sehingga posisi seluruh ikon menu vertikal sejajar dan terpusat presisi 100% saat sidebar dalam mode *collapsed* (72px).
- `[DIFERENSIASI IKON KOTAK SARAN]` Mengubah ikon **Kotak Saran Jamaah** menjadi `fa-envelope-open-text` (kotak pesan/inbox aspirasi terbuka) sehingga secara visual berbeda tegas dan intuitif dari ikon **Chat Koordinasi DKM** (`fa-comments`).
- `[ELEGANT INTERNAL CHEVRON TOGGLE]` Memindahkan tombol toggle collapse dari top bar luar ke dalam header brand sidebar (`.sidebar-brand`):
  - Menggunakan ikon chevron minimalis bulat (`<` / `fa-chevron-left` saat melebar, dan `>` / `fa-chevron-right` saat mengecil).
  - Menjaga tampilan top app bar tetap bersih, elegan, dan fokus pada informasi panel.

---

## [1.6.3] - 2026-08-22

### Restrukturisasi Navigasi Sidebar, Fitur Collapse Sidebar, dan Tata Letak Fleksibel Toolbar Tugas

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[SIDEBAR COLLAPSE TOGGLE]` Penambahan fitur *collapse / expand* sidebar secara halus (*smooth transition*) dengan tombol toggle hamburger (`fa-bars`) di header utama:
  - **Desktop:** Mengecilkan sidebar menjadi 72px (*icon-only mode*) untuk memperluas ruang kerja, dan menyimpan status preferensi ke `localStorage`.
  - **Mobile:** Berfungsi sebagai laci navigasi responsif (*mobile drawer overlay*).
- `[REORGANISASI MENU UTAMA SIDEBAR]`
  - Menjadikan **Riwayat Portal** (`history`) sebagai menu tab utama tersendiri di sidebar (menggantikan nama lama *"Riwayat Realtime"*) untuk memudahkan pemantauan audit trail dan log CDC secara menyeluruh.
  - Menjadikan **Chat Koordinasi DKM** (`chat`) sebagai menu tab utama mandiri di sidebar lengkap dengan badge jumlah *unread mentions* real-time (`#badge-sidebar-chat-mentions`), memberikan ruang layar percakapan yang lapang setinggi satu layar penuh.
- `[PEMURNIAN TOP BAR MODUL TUGAS]`
  - Menyederhanakan sub-navigasi tugas menjadi 5 tampilan murni: **Papan Kanban**, **Garis Waktu Gantt**, **Kalender Tugas**, **Tabel Seluruh Tugas**, dan **Arsip Selesai**.
- `[FLUID & COMPACT TASK TOOLBAR]`
  - Menata ulang layout `.task-toolbar` agar fleksibel dan tidak patah/turun baris secara canggung pada resolusi layar sedang atau saat DevTools terbuka. Filter judul tugas, divisi, prioritas, status, dan tombol aksi tertata seimbang dan responsif.

---

## [1.6.2] - 2026-08-22

### Penyempurnaan Format Markup WhatsApp & Hapus Pesan untuk Semua (Delete for Everyone)

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[CHAT COMPOSER MULTILINE]` Mengganti elemen single-line `<input>` menjadi `<textarea>` dengan kemampuan *auto-grow* (tinggi otomatis mengembang dinamis 38px s/d 120px) dan perilaku tombol Enter adaptif:
  - **Desktop / PC:** Menekan `Enter` otomatis mengirim pesan, menekan `Shift + Enter` membuat baris baru (*multiline*).
  - **Android / Layar Sentuh:** Menekan `Enter` di keyboard HP otomatis membuat baris baru (loncat ke bawah persis seperti aplikasi WhatsApp), pengiriman pesan dilakukan melalui tombol *Kirim*.
- `[WHATSAPP MARKDOWN PARSER]` Implementasi parser markup teks WhatsApp pada fungsi `formatChatMessageText()`:
  - `*teks*` $\rightarrow$ **Teks Tebal** (*Bold*)
  - `_teks_` $\rightarrow$ *Teks Miring* (*Italic*)
  - `~teks~` $\rightarrow$ ~~Teks Coret~~ (*Strikethrough*)
  - `` `teks` `` $\rightarrow$ `Kode Berderet / Monospace`
  - `\n` $\rightarrow$ Baris baru rapi (*Line Break*)
- `[CURSOR-AWARE MENTION]` Perbaikan total algoritma `insertMention(tag)`:
  - Penempatan mention `@PJ_Nama` kini presisi di posisi kursor aktif (bisa di awal, di tengah, maupun di akhir kalimat), tanpa merusak atau memotong teks yang telah diketik sebelumnya.
- `[DELETE FOR EVERYONE]` Implementasi fitur *Hapus Pesan untuk Semua*:
  - Pengirim pesan dapat menghapus pesannya sendiri secara permanen dari seluruh layar pengurus melalui tombol hapus (`fa-trash`).
  - Pesan yang dihapus berubah menjadi gelembung placeholder resmi WhatsApp (*"Anda telah menghapus pesan ini"* untuk pengirim, dan *"Pesan ini telah dihapus"* untuk penerima).
  - Sinkronisasi realtime instan via WebSocket Broadcast (`CHAT_DELETE`) dan Supabase CDC `UPDATE`.
- `[SERVER-SIDE 7-DAY QUERY FILTER]` Optimasi query Supabase pada `loadAllTaskData()` menggunakan filter `.gte('created_at', sevenDaysAgoISO)` untuk menghemat kuota bandwidth database sehingga hanya pesan 7 hari terakhir yang dimuat.

---

## [1.6.1] - 2026-08-21

### Penyempurnaan Modul Tugas & Chat Koordinasi Pro DKM (WhatsApp-Style Reply, Mention Eksklusif & Skala Dinamis)

#### Peningkatan & Penyempurnaan (Enhanced & Fixed)
- `[SIDEBAR PROFILE]` Mengganti teks email panjang menjadi **Nama Pengguna & Peran Resmi** yang bersih dan santun (misal: *"Super Administrator"*, *"Super User"*, *"Habib Maulana"*, *"Ustadz Ridwan"*, *"Pak Marwan"*), dengan badge peran resmi di bawahnya.
- `[GANTT TIMELINE]`
  - **Diferensiasi Warna Status:** Menambahkan pembeda visual kontras antara `0%` / *Pending* (Slate Gray `#E2E8F0` / `#94A3B8`), `1%-99%` / *In Progress* & *Review* (Amber Gold Gradient), dan `100%` / *Selesai* (Emerald Green `#10B981`).
  - **Skala Waktu Dinamis:** Tombol *Skala Hari* (grid harian 14 hari + penanda *Today* vertikal), *Skala Minggu* (grid 6 pekan W1-W6), dan *Skala Bulan* (grid 3 bulan) aktif 100% menghitung rentang tanggal dan posisi bar secara presisi.
- `[KALENDER TUGAS PRO]`
  - **Gaya Portosiabe & Multi-Day Spanning:** Menampilkan bar tugas memanjang rapi melintasi rentang hari (*multi-day span*) dengan icon `<i class="fa-solid fa-arrows-left-right"></i>`, badge warna 10 divisi, inisial PIC, dan status dot/pill yang kontras.
  - **Navigasi Kalender Interaktif:** Tombol `<` (Bulan Sebelumnya), `>` (Bulan Berikutnya), dan `Hari Ini` aktif memperbarui grid bulan secara dinamis, serta klik tanggal kosong untuk tambah tugas cepat.
- `[MASTER TABLE]` Penambahan tombol aksi masal merah elegan **"Hapus Task Terpilih"** pada toolbar seleksi untuk menghapus tugas terpilih sekaligus dari database Supabase, realtime broadcast, dan local cache.
- `[CHAT KOORDINASI PRO]`
  - **Pembersihan UI:** Menyembunyikan bar pencarian & filter tugas khusus saat berada di panel Chat Koordinasi agar layar percakapan fokus dan lapang.
  - **Fitur Balas Pesan (WhatsApp-Style Reply / Quote):**
    - *Desktop/PC:* Double click pada gelembung chat (atau tombol reply hover) untuk mengutip pesan yang ingin dibalas.
    - *Mobile/Smartphone:* Long-press (tekan tahan 500ms) pada gelembung pesan.
    - *Reply Context Bar:* Muncul bilah kutipan di atas input chat dengan garis vertikal aksen emas dan tombol batalkan (`X`).
    - *Quoted Message Box:* Pesan balasan menampilkan kotak kutipan WhatsApp di dalam bubble. Klik kotak kutipan otomatis melakukan *smooth scroll* dan animasi kedip (*highlight flash*) ke pesan aslinya.
  - **Fitur Mention `@` & Autocomplete:** Mengetik `@` memunculkan autocomplete 10 peran PJ DKM (`@Ketua_DKM`, `@PJ_Media`, `@PJ_Logistik`, dll.) dan me-render tag mention emas di chat bubble.
  - **Bubble Badge Count Eksklusif:** Badge notifikasi mention di tab Chat Koordinasi hanya muncul pada akun pengurus yang di-tag secara spesifik (tidak muncul pada akun lain), dan otomatis reset saat tab chat dibuka.
  - **Lampiran Media ImageKit:** Mendukung upload foto (auto-convert/compress WebP) dan video (WebM/MP4) dengan preview thumbnail di chat.
  - **Retensi 7 Hari:** Pembatasan memori dan query pesan hanya untuk 1 pekan terakhir demi efisiensi kuota dan memori browser.

---

## [1.6.0] - 2026-08-21

### Modul Manajemen Tugas Pengurus (5 Tampilan Kerja + 2 Panel Realtime Terpadu)

#### Penambahan & Implementasi (Added & Implemented)
- `[TASK ENGINE]` Implementasi modul terpadu Manajemen Tugas Pengurus DKM pada `admin.html` mencakup 5 Tampilan Kerja Interaktif:
  - **1. Papan Kanban (Seret & Lepas Antar Kolom):** 4 kolom status (*Menunggu*, *Dikerjakan*, *Review Pak DKM*, *Selesai*), drag-and-drop HTML5, tombol geser sentuh cepat (*Mobile Shift*) untuk smartphone, indikator prioritas (*Critical, High, Medium, Low*), badge warna 10 divisi, dan bar progres visual.
  - **2. Garis Waktu Gantt (Jadwal Kerja Visual):** Visualisasi jadwal tugas per PJ dengan skala waktu fleksibel (Hari, Minggu, Bulan), perhitungan durasi otomatis, dan filter divisi.
  - **3. Kalender Tugas (Bulanan & Agenda):** Grid kalender bulanan dengan *spanning bar* multi-hari, navigasi bulan, klik tanggal untuk tambah tugas cepat, dan toggle *Mode Agenda* kronologis.
  - **4. Tabel Seluruh Tugas (Cari, Saring, Urutkan):** Master data table dengan live multi-field search, filter divisi/prioritas/status, sorting kolom interaktif, multi-select checkboxes dengan toolbar aksi masal (*Arsipkan Masal*, *Tandai Selesai*), dan tombol *Unduh CSV*.
  - **5. Arsip Tugas Selesai (Simpan Rapi & Pulihkan):** Ruang penyimpanan rapi untuk tugas selesai yang diarsipkan dengan fitur 1-klik *Pulihkan Tugas* dan *Hapus Permanen*.
- `[REALTIME HUB]` Peningkatan engine Realtime sinkronisasi instan multi-peran (Superadmin, Superuser, dan PJ Divisi):
  - Dukungan ganda: **Supabase Database CDC (`postgres_changes`)** + **Supabase WebSocket Broadcast (`TASK_SYNC`, `LOG_SYNC`, `CHAT_SYNC`)** untuk pembaruan instan (<50ms) antar seluruh tab/perangkat terbuka tanpa jeda replikasi.
  - Standardisasi ID tugas, log, dan chat ke format valid **RFC4122 UUID** (`gen_random_uuid()`) untuk kompatibilitas penuh tipe data PostgreSQL Supabase.
- `[UI PERSISTENCE]` Implementasi **Browser Navigation Memory & URL Hash Persistence** pada `admin.html`:
  - Menyimpan menu tab aktif (`#overview`, `#donations`, `#tasks`, `#feedback`, `#articles`, `#health`) dan subview tugas (`kanban`, `gantt`, `calendar`, `table`, `archive`, `history`, `chat`) ke `localStorage` dan URL hash browser.
  - Saat halaman di-refresh (F5), browser tidak akan lagi mereset ke menu paling atas melainkan langsung tetap membuka tab dan sub-tampilan terakhir yang sedang dikerjakan pengurus.
- `[DOCS & PROGRESS]` Sinkronisasi paralel pada `implementation-plan.md` dan `progress-implementation-plan.html` (7 item tugas/panel tercatat selesai 100%).

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
