# SPESIFIKASI MODUL: E-LEARNING & LMS COURSE PLATFORM
> Kode Modul: `MOD-35` | Versi: `1.0.0` | Kategori: `E-Learning & Komunitas (REC-18)` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-35-LMS-COURSE-ELEARNING` |
| **Nama Modul** | E-Learning, LMS Course Platform & Certificate Generator |
| **Kategori** | Digital Learning & Training Management (LMS) |
| **Level Akses Publik** | Student / Employee Member (`auth.uid()`) / Course Instructor |
| **Tingkat Decoupling** | High (Bisa dijual via MOD-06 / MOD-02 atau untuk training internal MOD-28) |
| **Integrasi Pilar** | Supabase (Lesson Tree & Progress Tracker), ImageKit (Video/Slide Media), Resend (Auto Certificate PDF) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan platform akademi online / kursus digital mandiri untuk monetisasi materi pelatihan ke publik atau program orientasi (*employee onboarding*) staf internal, lengkap dengan struktur modul/bab/video materi, kuis pilihan ganda interaktif, pelacakan progres kelulusan (*Progress Tracker*), dan penerbitan sertifikat digital otomatis ber-QR verifikasi.

### Fitur Utama:
1. **Hierarki Kursus Multi-Bab:** Kursus -> Bab (Section) -> Pelajaran (Video, Teks, Dokumen Download).
2. **Kuis Evaluasi Pemahaman:** Pilihan ganda dengan passing grade minimum (misal: 80% benar).
3. **Pelacakan Progres Belajar:** Persentase penyelesaian materi tersimpan otomatis per akun siswa.
4. **Auto-Generate Sertifikat Kelulusan:** Penerbitan sertifikat PDF resmi segera setelah lulus 100%.

---

## 3. DIAGRAM ALUR PEMBELAJARAN & KELULUSAN

```text
[SISWA / KARYAWAN (lms-classroom.html)]
     |
     v (1. Tonton Video Pelajaran & Baca Materi)
[Progress Tracker Engine (Supabase Atomic)]
     |-- Tandai Pelajaran 1 Selesai -> Progres: 25%
     |
     v (2. Mengikuti Kuis Akhir)
[Evaluasi Jawaban Kuis]
     |-- Skor: 90 / 100 (Lulus Passing Grade!)
     |-- Progres Kursus: 100% (COMPLETED)
     |
     v (3. Penerbitan Sertifikat)
[Certificate Dispatcher (Resend API)]
     |-- Generate Unique Cert Code: CERT-LMS-2026-9912
     |-- Kirim PDF Sertifikat ke Email Siswa
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL KURSUS (COURSES)
CREATE TABLE IF NOT EXISTS public.lms_courses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    thumbnail_url TEXT NOT NULL,
    description_html TEXT NOT NULL,
    instructor_name VARCHAR(150) NOT NULL,
    price NUMERIC(15, 2) DEFAULT 0.00, -- 0 = Gratis / Internal
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PELAJARAN / MATERI (LESSONS)
CREATE TABLE IF NOT EXISTS public.lms_lessons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID NOT NULL REFERENCES public.lms_courses(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    video_embed_url TEXT,
    content_html TEXT,
    sort_order INT NOT NULL DEFAULT 1,
    duration_minutes INT DEFAULT 10
);

-- TABEL ENROLLMENT & PROGRES BELAJAR (ENROLLMENTS)
CREATE TABLE IF NOT EXISTS public.lms_enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID NOT NULL REFERENCES public.lms_courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    progress_percentage INT DEFAULT 0,
    completed_lessons UUID[] DEFAULT ARRAY[]::UUID[],
    is_completed BOOLEAN DEFAULT false,
    certificate_code VARCHAR(60) UNIQUE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(course_id, user_id)
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_lms_enroll_user ON public.lms_enrollments (user_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.lms_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lms_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lms_enrollments ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh melihat kursus terpublikasi
CREATE POLICY "Allow public read published courses" ON public.lms_courses FOR SELECT TO anon, authenticated USING (is_published = true);

-- 2. Siswa hanya bisa membaca materi jika terdaftar (Enrolled)
CREATE POLICY "Enrolled students read lessons" 
ON public.lms_lessons 
FOR SELECT 
TO authenticated 
USING (
    course_id IN (SELECT course_id FROM public.lms_enrollments WHERE user_id = auth.uid()) OR
    auth.jwt() ->> 'role' = 'service_role'
);

CREATE POLICY "Students manage own progress" 
ON public.lms_enrollments 
FOR ALL 
TO authenticated 
USING (user_id = auth.uid());
```

---

## 6. LOGIKA KLIEN: MARK LESSON COMPLETE (JAVASCRIPT)

```javascript
/**
 * MOD-35: Mark Lesson Complete & Calculate Progress
 */
async function markLessonComplete(courseId, lessonId, totalLessonsCount) {
    const { data: { user } } = await supabaseClient.auth.getUser();

    try {
        const { data: enroll } = await supabaseClient
            .from('lms_enrollments')
            .select('*')
            .eq('course_id', courseId)
            .eq('user_id', user.id)
            .single();

        let completed = enroll.completed_lessons || [];
        if (!completed.includes(lessonId)) {
            completed.push(lessonId);
        }

        const newProgress = Math.round((completed.length / totalLessonsCount) * 100);
        const isDone = newProgress >= 100;

        await supabaseClient
            .from('lms_enrollments')
            .update({
                completed_lessons: completed,
                progress_percentage: newProgress,
                is_completed: isDone,
                completed_at: isDone ? new Date().toISOString() : null,
                certificate_code: isDone ? `CERT-${Date.now()}` : null
            })
            .eq('id', enroll.id);

        showNotification(`[SUCCESS] Pelajaran selesai! Progres kursus: ${newProgress}%`, 'success');
    } catch (err) {
        console.error('[LMS_ERROR]', err);
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA KELAS ONLINE

```html
<div class="lms-classroom-layout">
    <div class="lesson-main">
        <h3>Pelajaran 3: Arsitektur Database Terdistribusi</h3>
        <div class="video-container">
            <iframe src="https://player.vimeo.com/video/12345" frameborder="0"></iframe>
        </div>
        <button type="button" class="btn btn-primary" onclick="markLessonComplete('course-1', 'lesson-3', 10)">
            Tandai Selesai & Lanjut Materi Berikutnya
        </button>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Proteksi Materi:** Pengguna yang belum terdaftar dilarang mengakses video atau konten pelajaran.
- [ ] **Kalkulasi Progres Akurat:** Persentase kelulusan bertambah tepat seiring penyelesaian tiap bab.
- [ ] **Penerbitan Sertifikat:** Sertifikat otomatis diterbitkan hanya jika progres mencapai 100%.
- [ ] **Strict No-Emoji:** Status materi dan sertifikat kelulusan bebas emoji.