# SPESIFIKASI MODUL: FORUM & COMMUNITY Q&A DISCUSSION PLATFORM
> Kode Modul: `MOD-36` | Versi: `1.0.0` | Kategori: `E-Learning & Komunitas (REC-19)` | Dependensi: `Supabase, MOD-08`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-36-FORUM-COMMUNITY-DISCUSS` |
| **Nama Modul** | Forum, Community Q&A & Knowledge Base Engine |
| **Kategori** | Community Engagement & Peer-to-Peer Discussion |
| **Level Akses Publik** | Anonymous Reader / Authenticated Contributor (`auth.uid()`) |
| **Tingkat Decoupling** | High (Menambah ruang interaksi audiens pada MOD-08 atau MOD-03) |
| **Integrasi Pilar** | Supabase (Thread Nested Hierarchy & Vote Counting Ledger) |

---

## 2. TUJUAN BISNIS & USE CASE

Membangun keterikatan pengguna (*User Engagement*) dan basis pengetahuan mandiri (*Self-Service Community FAQ*) melalui forum diskusi berbasis utas (*Threaded Posts*), sistem tanya-jawab (*Q&A Upvote/Downvote*), penandaan jawaban terbaik (*Best Answer Solved*), moderasi komentar spam, dan poin reputasi kontributor.

### Fitur Utama:
1. **Kategori & Saluran Diskusi:** Pemisahan topik (Teknis, Pengumuman, Tanya-Jawab Produk, Saran Fitur).
2. **Sistem Voting & Ranking:** Upvote / Downvote untuk menaikkan jawaban paling relevan ke posisi teratas.
3. **Pin Jawaban Solusi (Mark as Solved):** Pembuat pertanyaan dapat menandai satu jawaban sebagai solusi resmi.
4. **Alat Moderasi Komunitas:** Flag postingan tidak pantas, ban user spammer, dan kunci utas diskusi (*Lock Thread*).

---

## 3. DIAGRAM ALUR FORUM & DISKUSI KOMUNITAS

```text
[ANGGOTA KOMUNITAS]
     |
     v (1. Buat Utas Baru: "Bagaimana cara integrasi webhook QRIS?")
[Supabase: public.forum_threads]
     |-- Simpan Pertanyaan & Tag Kategori
     |
     v (2. Anggota Lain Menjawab)
[Supabase: public.forum_posts]
     |-- Komunitas memberikan Upvote (+1 Poin Reputasi)
     |
     v (3. Pemilik Pertanyaan Memilih Solusi Terbaik)
[Tandai: is_best_answer = true]
     |-- Thread ditandai status [TERSELESAIKAN / SOLVED]
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL KATEGORI FORUM
CREATE TABLE IF NOT EXISTS public.forum_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL UTAS PERTANYAAN (FORUM THREADS)
CREATE TABLE IF NOT EXISTS public.forum_threads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category_id UUID NOT NULL REFERENCES public.forum_categories(id),
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content_html TEXT NOT NULL,
    upvotes_count INT DEFAULT 0,
    answers_count INT DEFAULT 0,
    is_solved BOOLEAN DEFAULT false,
    is_locked BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL JAWABAN / KOMENTAR (FORUM POSTS)
CREATE TABLE IF NOT EXISTS public.forum_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    thread_id UUID NOT NULL REFERENCES public.forum_threads(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content_html TEXT NOT NULL,
    upvotes_count INT DEFAULT 0,
    is_best_answer BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_forum_thread_cat ON public.forum_threads (category_id, is_solved);
CREATE INDEX IF NOT EXISTS idx_forum_posts_thread ON public.forum_posts (thread_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.forum_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh membaca seluruh forum
CREATE POLICY "Allow public read forum threads" ON public.forum_threads FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow public read forum posts" ON public.forum_posts FOR SELECT TO anon, authenticated USING (true);

-- 2. Member terotentikasi boleh memposting pertanyaan dan jawaban
CREATE POLICY "Members create threads" ON public.forum_threads FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Members create posts" ON public.forum_posts FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
```

---

## 6. LOGIKA KLIEN: UPVOTE THREAD HANDLER (JAVASCRIPT)

```javascript
/**
 * MOD-36: Upvote Post Handler
 */
async function upvoteForumPost(postId) {
    try {
        const { error } = await supabaseClient.rpc('increment_post_upvote', { p_post_id: postId });
        if (error) throw error;
        showNotification('[SUCCESS] Terima kasih atas apresiasi Anda!', 'success');
        refreshPostVotes(postId);
    } catch (err) {
        console.error('[FORUM_ERROR]', err);
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA THREAD DISKUSI

```html
<div class="forum-thread-view">
    <div class="thread-header">
        <span class="badge badge-success">[STATUS: TERSELESAIKAN / SOLVED]</span>
        <h2>Integrasi Webhook QRIS Supabase</h2>
        <small>Ditanyakan oleh: Ahmad Fauzan | 4 Jawaban</small>
    </div>
    <div class="best-answer-box">
        <div class="badge-tag">[JAWABAN TERBAIK]</div>
        <p>Gunakan Supabase Database Webhook pada tabel payment_transactions...</p>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Akurasi Solusi:** Hanya pembuat pertanyaan atau moderator yang dapat menandai `is_best_answer`.
- [ ] **Pencegahan Spam:** Rate-limit membatasi pembuatan maksimal 3 pertanyaan per 10 menit per user.
- [ ] **Strict No-Emoji:** Status thread dan badge reputasi forum bebas emoji.