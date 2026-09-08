# Project: Pembaruan Komprehensif Portal Publik Masjid Sophia Jatiwarna

## Architecture
- **Tech Stack**: Vanilla HTML5/CSS3/JavaScript (ES6+), Supabase Realtime Client (PostgreSQL, CDC WebSocket), ImageKit CDN, Font Awesome 6, Vercel Clean URL Hosting.
- **Data Flow**:
  - `admin.html` (Admin DKM Portal) performs CRUD on Supabase tables (`homepage_media`, `artikel_berita`, `jadwal_shalat_petugas`, `kajian_acara_ibadah`, `donations`, `feedback_complaints`).
  - Supabase PostgreSQL emits CDC changes via `supabase_realtime` publication (`REPLICA IDENTITY FULL`).
  - `index.html` (Public Portal) listens to CDC channels and re-renders components immediately without full page reload.
  - `galeri.html` (Istiqlal Photo Stack Gallery & Lightbox) and `artikel.html` / `artikel-detail.html` (UMAR Dakwah Portal) fetch data dynamically from Supabase and render high-performance WebP media via ImageKit.
- **Routing & Deployment**:
  - Hosted on Vercel with `cleanUrls: true`, `trailingSlash: false`, and dynamic URL rewrites in `vercel.json`.

## Code Layout
- `admin.html`: DKM Administration & Visual Web Builder (`#media` tab).
- `index.html`: Public Community Portal (Navbar, Dynamic Hero Slider, Istiqlal Album Highlights, Dakwah News, CDC listeners).
- `galeri.html`: Independent Gallery Portal (Istiqlal standard: Category pills, photo stack, fullscreen lightbox).
- `artikel.html`: Independent Dakwah Articles Archive (UMAR standard: Featured article, category filter, card grid, pagination).
- `artikel-detail.html`: Article Reader Page (UMAR standard: Reading progress bar, author meta, rich-text HTML, social share, related articles).
- `vercel.json`: Clean URL routing & rewrite definitions.
- `database/`: SQL migration files (`migration_milestone1_schema_sync.sql`).
- `scripts/verify_index_compliance.py`: Automated compliance & integrity verification suite.
- `implementation-plan.md`, `progress-implementation-plan.html`, `CHANGELOG.md`: Synchronized 3-file project governance.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Dev Branch Strict Policy | Ensure git branch is `dev`, prevent push/merge to `main` | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Supabase Schema & Realtime | Sync `arabic_quote`, verify 6 CDC tables, create migration file | M1 | ORIGINAL_REQUEST §R1 |
| 3 | ImageKit Typo Correction | Fix `Halaqah_Al_Quran` -> `Halaqah_Al-Quran` (HTTP 200) | M1 | ORIGINAL_REQUEST §R1 |
| 4 | Hero Slider Unlimited CRUD | "+ Tambah Slide Baru", modal editor, ImageKit picker | M2 | ORIGINAL_REQUEST §R2 |
| 5 | ImageKit Media Picker Callback | Fix `selectMediaForTarget` for `hero-slide-media-url` | M2 | ORIGINAL_REQUEST §R2 |
| 6 | Admin CDC & Reordering | Up/down order buttons, active toggle, broadcast event | M2 | ORIGINAL_REQUEST §R2 |
| 7 | Compact Navbar Redesign | Remove "Layanan Cepat", 7 clean menu items, remove dead CSS | M3 | ORIGINAL_REQUEST §R3 |
| 8 | Dynamic Hero Slider & Dots | Supabase dynamic query, Arabic verse with harakat, auto dots | M3 | ORIGINAL_REQUEST §R3 |
| 9 | 8-Aspect Live CDC in Index | Dynamic sync for Hero, Jadwal, Kajian, Donasi, Fasilitas, Galeri, Warta, Pengaduan | M3 | ORIGINAL_REQUEST §R3 |
| 10 | AI Slop Elimination | Clean flexing terms ("Update Realtime Otomatis" -> "Data infaq terverifikasi DKM") | M3 | ORIGINAL_REQUEST §R3 |
| 11 | Istiqlal 4-Album Highlights | 4 Photo stack cards in index linking to `/galeri` | M3 | ORIGINAL_REQUEST §R3 |
| 12 | Warta Active Card Links | Wrap article cards with links to `/artikel/:slug` and `/artikel` | M3 | ORIGINAL_REQUEST §R3 |
| 13 | Standalone Galeri (Istiqlal) | `galeri.html` with breadcrumbs, filter pills, photo stack grid, lightbox viewer | M4 | ORIGINAL_REQUEST §R4 |
| 14 | Standalone Artikel (UMAR) | `artikel.html` with search, category pills, featured card, grid, pagination | M5 | ORIGINAL_REQUEST §R5 |
| 15 | Standalone Artikel Detail (UMAR) | `artikel-detail.html` with progress bar, author bar, rich-text, social share, related posts | M5 | ORIGINAL_REQUEST §R5 |
| 16 | Vercel Clean URL Routing | Configure rewrites in `vercel.json` | M5 | ORIGINAL_REQUEST §R6 |
| 17 | 3-File Documentation Sync | Sync `implementation-plan.md` (v5.8), `progress-implementation-plan.html`, `CHANGELOG.md` ([1.9.18]) | M6 | ORIGINAL_REQUEST §R6 |
| 18 | Strict No-Emoji & Compliance | Pass `python scripts/verify_index_compliance.py` 100% | M6 | ORIGINAL_REQUEST §R6 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Database & Dev Branch Verification | Git branch confirmation, `database/migration_milestone1_schema_sync.sql`, verify Supabase schema | none | DONE |
| 2 | Admin Hero Carousel Slider Manager | `admin.html#media`: unlimited slides, modal editor with `arabic_quote`, ImageKit picker callback fix, CDC broadcast | M1 | PLANNED |
| 3 | Redesign Beranda Publik (index.html) | `index.html`: navbar cleanup, dynamic hero slider, 8-aspect live CDC, AI slop removal, Istiqlal album highlights, warta links | M1 | PLANNED |
| 4 | Halaman Mandiri Galeri (galeri.html) | `galeri.html`: Istiqlal standard photo stack, filter pills, search bar, fullscreen lightbox photo viewer | M1 | PLANNED |
| 5 | Portal Warta Dakwah (artikel.html & artikel-detail.html) | `artikel.html`, `artikel-detail.html`: UMAR standard reader layout, social share, related posts, `vercel.json` rewrites | M1 | PLANNED |
| 6 | E2E Compliance & Documentation Sync | 3-file parallel documentation sync (v5.8 / [1.9.18]), run `scripts/verify_index_compliance.py`, full victory check | M2, M3, M4, M5 | PLANNED |

## Interface Contracts

### Supabase Table: `public.homepage_media`
- `id`: UUID PRIMARY KEY DEFAULT gen_random_uuid()
- `judul`: VARCHAR(255) NOT NULL
- `subjudul`: VARCHAR(255) (Quotes/Terjemahan)
- `arabic_quote`: TEXT (Ayat Al-Qur'an / Hadits berharakat)
- `kategori`: VARCHAR(50) DEFAULT 'BANNER_HERO'
- `media_url`: TEXT NOT NULL (ImageKit CDN WebP URL)
- `media_type`: VARCHAR(20) DEFAULT 'IMAGE'
- `action_link`: VARCHAR(255)
- `action_label`: VARCHAR(100) DEFAULT 'Lihat Selengkapnya'
- `order_index`: INT DEFAULT 0
- `is_active`: BOOLEAN DEFAULT TRUE
- `status_review`: VARCHAR(30) DEFAULT 'APPROVED'
- `reviewer_name`: VARCHAR(150)

### Realtime CDC Broadcast Event
- Channel: `public:homepage_media:broadcast` or `public:homepage_media:index`
- Broadcast Event: `HERO_SLIDE_SYNC`
- Payload: `{ action: 'INSERT'|'UPDATE'|'DELETE'|'TOGGLE'|'REORDER', slideData: object, timestamp: number }`

### URL Routing Contract (`vercel.json`)
- `/galeri` -> `/galeri.html`
- `/artikel` -> `/artikel.html`
- `/artikel/:slug` -> `/artikel-detail.html?slug=:slug`
- `/admin` -> `/admin.html`
- `cleanUrls`: true, `trailingSlash`: false
