# SPESIFIKASI MODUL: ARTICLE & CONTENT STUDIO (BENCHMARK: WEB-UMAR)
> Kode Modul: `MOD-03` | Versi: `1.0.0` | Kategori: `Core & Public Content / CMS` | Dependensi: `Supabase, ImageKit`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-03-CONTENT-ARTICLE-STUDIO` |
| **Nama Modul** | Article & Content Studio CMS (Benchmark WEB-UMAR) |
| **Kategori** | Content Management System & SEO Publishing |
| **Level Akses Publik** | Public Reader (`anon`) / Editorial Admin (`authenticated`) |
| **Tingkat Decoupling** | High (Bisa dipasang pada landing page atau portal berita penuh) |
| **Integrasi Pilar** | Supabase (Database + Full-Text Search), ImageKit (Cover & Body Media CDN) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan mesin publikasi artikel, wawasan bisnis, siaran pers, dan dokumentasi kegiatan brand dengan performa tinggi, skor SEO Google 100, dan panel manajemen konten (CMS) yang intuitif tanpa dependensi WordPress yang berat.

### Fitur Unggulan:
1. **Trinitas Antarmuka:**
   - `admin.html`: Studio penulisan, upload cover, manajemen slug otomatis, auto calculation reading time.
   - `artikel.html`: Portal daftar artikel dengan filter kategori, pencarian real-time instan, dan pagination.
   - `artikel-detail.html`: Halaman baca artikel dengan OpenGraph, Twitter Card, Schema.org Article, tombol share, dan artikel terkait.
2. **Kalkulasi Otomatis Reading Time:** Menghitung estimasi menit baca berdasarkan jumlah kata (`words / 200`).
3. **Full-Text Search PostgreSQL:** Pencarian cepat berbasis judul, excerpt, dan konten HTML.

---

## 3. DIAGRAM ALUR ARTIKEL PUBLISHING & SEO INGESTION

```text
[EDITOR / ADMIN (admin.html)]
     |
     v (1. Tulis Judul, Konten HTML, Kategori, Tags)
[ImageKit CDN Ingestion]
     |-- Upload Gambar Cover (Auto Resize & WebP Optimization)
     |-- Simpan URL Media ke Supabase
     |
     v (2. Auto Slug & Reading Time Calculation)
[Supabase Database (public.articles)]
     |-- Set is_published = true
     |-- Set published_at = NOW()
     |
     v (3. Public Discovery (artikel.html & artikel-detail.html))
[Pengunjung Publik / Google Bot]
     |-- Render Serverless / Edge Page dengan OpenGraph & Schema.org JSON-LD
     |-- Trigger Increment View Count via RPC Atomic Function
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL KATEGORI ARTIKEL
CREATE TABLE IF NOT EXISTS public.article_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL ARTIKEL LENGKAP (STANDAR WEB-UMAR)
CREATE TABLE IF NOT EXISTS public.articles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    category_id UUID REFERENCES public.article_categories(id) ON DELETE SET NULL,
    category VARCHAR(100) NOT NULL, -- Denormalized untuk query cepat
    cover_image_url TEXT NOT NULL,
    excerpt TEXT NOT NULL,
    content_html TEXT NOT NULL,
    author_name VARCHAR(100) DEFAULT 'Tim Redaksi',
    author_avatar_url TEXT,
    reading_time_minutes INT DEFAULT 3,
    is_published BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    view_count BIGINT DEFAULT 0,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    meta_title VARCHAR(150),
    meta_description VARCHAR(200),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING PERFORMA TINGGI
CREATE INDEX IF NOT EXISTS idx_articles_slug ON public.articles (slug);
CREATE INDEX IF NOT EXISTS idx_articles_published ON public.articles (is_published, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_category ON public.articles (category);
CREATE INDEX IF NOT EXISTS idx_articles_tags ON public.articles USING gin (tags);

-- FULL TEXT SEARCH INDEX (GIST / GIN)
CREATE INDEX IF NOT EXISTS idx_articles_fts ON public.articles 
USING gin (to_tsvector('indonesian', title || ' ' || excerpt || ' ' || content_html));

-- STORED PROCEDURE: INCREMENT VIEW COUNT SECARA ATOMIK
CREATE OR REPLACE FUNCTION public.increment_article_views(target_article_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.articles
    SET view_count = view_count + 1
    WHERE id = target_article_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_categories ENABLE ROW LEVEL SECURITY;

-- 1. Publik hanya diizinkan membaca artikel berstatus PUBLISHED
CREATE POLICY "Allow public read published articles" 
ON public.articles 
FOR SELECT 
TO anon, authenticated 
USING (is_published = true AND published_at <= timezone('utc'::text, now()));

-- 2. Publik boleh membaca seluruh kategori artikel
CREATE POLICY "Allow public read categories" 
ON public.article_categories 
FOR SELECT 
TO anon, authenticated 
USING (true);

-- 3. Admin memiliki hak penuh untuk membuat, mengedit, dan menghapus artikel
CREATE POLICY "Allow admin full access to articles" 
ON public.articles 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);

CREATE POLICY "Allow admin full access to categories" 
ON public.article_categories 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: SLUG GENERATOR & AUTO READING TIME

```javascript
/**
 * MOD-03: Content Studio Utilities
 */

// Otomasi Pembuatan Slug Ramah SEO
function generateSlug(text) {
    return text
        .toString()
        .toLowerCase()
        .trim()
        .replace(/&/g, '-dan-')
        .replace(/[\s\W-]+/g, '-')
        .replace(/^-+|-+$/g, '');
}

// Otomasi Kalkulasi Menit Baca (Rata-rata 200 kata/menit)
function calculateReadingTime(htmlContent) {
    const textOnly = htmlContent.replace(/<[^>]*>?/gm, ' ');
    const wordCount = textOnly.trim().split(/\s+/).filter(Boolean).length;
    const minutes = Math.ceil(wordCount / 200);
    return minutes < 1 ? 1 : minutes;
}

// Handler Simpan Artikel dari Form Admin
async function saveArticleHandler(event) {
    event.preventDefault();
    const title = document.getElementById('article-title').value.trim();
    const content = document.getElementById('article-content').innerHTML;
    const isPublished = document.getElementById('is-published-toggle').checked;

    const payload = {
        title: title,
        slug: document.getElementById('article-slug').value.trim() || generateSlug(title),
        category: document.getElementById('article-category').value,
        cover_image_url: document.getElementById('cover-image-url').value,
        excerpt: document.getElementById('article-excerpt').value.trim(),
        content_html: content,
        author_name: document.getElementById('author-name').value.trim() || 'Tim Redaksi',
        reading_time_minutes: calculateReadingTime(content),
        is_published: isPublished,
        published_at: isPublished ? new Date().toISOString() : null,
        meta_description: document.getElementById('meta-description').value.trim()
    };

    const { data, error } = await supabaseClient
        .from('articles')
        .upsert([payload])
        .select();

    if (error) {
        console.error('[ARTICLE_SAVE_ERROR]', error);
        showNotification('[ERROR] Gagal menyimpan artikel.', 'error');
    } else {
        showNotification('[SUCCESS] Artikel berhasil disimpan.', 'success');
    }
}
```

---

## 7. SPESIFIKASI METADATA HEAD SEO (OPENGRAPH & SCHEMA.ORG)

```html
<!-- STANDAR HEAD METADATA PADA artikel-detail.html -->
<title>Strategi Pertumbuhan Bisnis Modern - Nama Brand</title>
<meta name="description" content="Panduan komprehensif implementasi teknologi web terdistribusi untuk percepatan skala bisnis.">
<link rel="canonical" href="https://domainbrand.com/artikel/strategi-pertumbuhan-bisnis-modern">

<!-- OpenGraph Protocol -->
<meta property="og:type" content="article">
<meta property="og:title" content="Strategi Pertumbuhan Bisnis Modern">
<meta property="og:description" content="Panduan komprehensif implementasi teknologi web terdistribusi.">
<meta property="og:image" content="https://ik.imagekit.io/brand/cover-strategi.jpg">
<meta property="og:url" content="https://domainbrand.com/artikel/strategi-pertumbuhan-bisnis-modern">
<meta property="og:site_name" content="Nama Brand Media">

<!-- JSON-LD Structured Data Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Strategi Pertumbuhan Bisnis Modern",
  "image": ["https://ik.imagekit.io/brand/cover-strategi.jpg"],
  "datePublished": "2026-08-19T00:00:00+07:00",
  "dateModified": "2026-08-19T10:00:00+07:00",
  "author": {
    "@type": "Person",
    "name": "Tim Redaksi"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Nama Brand",
    "logo": {
      "@type": "ImageObject",
      "url": "https://domainbrand.com/assets/logo/logo-main.png"
    }
  }
}
</script>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Akurasi Slug:** Karakter khusus dan spasi otomatis dikonversi ke format URL aman (`kebab-case`).
- [ ] **Proteksi DRAFT:** Artikel dengan status `is_published = false` tidak dapat diakses atau di-scrape oleh publik.
- [ ] **SEO Rich Results:** Pengujian URL pada Google Rich Results Test menghasilkan validitas Schema Article 100%.
- [ ] **Pencarian Cepat:** Pencarian kata kunci mengembalikan hasil dalam waktu < 200ms menggunakan index Full-Text Search.
- [ ] **Strict No-Emoji:** Penulisan status editorial dan notifikasi menggunakan badge formal `[DRAFT]`, `[PUBLISHED]`, `[ARCHIVED]`.