# SPESIFIKASI MODUL: RECRUITMENT & APPLICANT TRACKING SYSTEM (ATS)
> Kode Modul: `MOD-29` | Versi: `1.0.0` | Kategori: `HR & People Operations (REC-12)` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-29-RECRUITMENT-ATS-PIPELINE` |
| **Nama Modul** | Recruitment, Job Portal & Applicant Tracking System (ATS) |
| **Kategori** | Talent Acquisition & Recruitment Operations |
| **Level Akses Publik** | Anonymous Candidate (Portal Karir) / HR Recruiter (ATS Kanban) |
| **Tingkat Decoupling** | High (Menyuplai karyawan baru ke MOD-28) |
| **Integrasi Pilar** | Supabase (ATS Pipeline & Candidate CV Storage), Resend (Interview Invitation) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan portal karir publik (*Public Job Board*), formulir lamaran online dengan unggah CV/Portofolio ke CDN ImageKit, papan Kanban pelacakan kandidat (*Applicant Tracking System - ATS*), evaluasi skor wawancara tim penilai, penjadwalan interview otomatis, dan penerbitan Surat Penawaran Kerja (*Job Offer Letter*).

### Fitur Utama:
1. **Public Job Board:** Halaman lowongan kerja aktif dengan filter departemen, tipe pekerjaan (Fulltime/Remote), dan batas waktu pendaftaran.
2. **Papan Kanban ATS Interaktif:** Tahapan lamaran (`APPLIED`, `SCREENING`, `INTERVIEW_1`, `INTERVIEW_2`, `OFFERED`, `HIRED`, `REJECTED`).
3. **Formulir Penilaian Wawancara (Scorecard):** Input nilai kecakapan teknis, komunikasi, dan kesesuaian budaya kerja.
4. **Auto Onboarding ke MOD-28:** Kandidat berstatus `HIRED` otomatis dapat dibuatkan profil karyawan di MOD-28 dengan satu klik.

---

## 3. DIAGRAM ALUR PROSES REKRUTMEN (ATS PIPELINE)

```text
[PELAMAR KERJA (karir.html)]
     |
     v (1. Pilih Lowongan & Upload Resume CV PDF)
[Supabase: public.job_applications]
     |-- Simpan Data Kandidat & URL CV (Status: APPLIED)
     |
     v (2. HR Screening di ATS Kanban)
[Tahap 1: Lolos Screening -> Jadwalkan Wawancara]
     |-- Kirim Undangan Interview Otomatis via Resend (.ICS)
     |
     v (3. Sesi Wawancara & Evaluasi Scorecard)
[Tim Interviewer Mengisi Nilai]
     |-- Disetujui -> Terbitkan Job Offer Letter
     |
     v (4. Kandidat Menerima Tawaran (HIRED))
[Auto Convert ke Master Karyawan MOD-28]
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL LOWONGAN KERJA (JOB POSTINGS)
CREATE TABLE IF NOT EXISTS public.hr_job_postings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    department_id UUID REFERENCES public.hr_departments(id),
    employment_type VARCHAR(50) DEFAULT 'FULL_TIME', -- 'FULL_TIME', 'PART_TIME', 'CONTRACT', 'INTERNSHIP'
    location_type VARCHAR(50) DEFAULT 'HYBRID', -- 'ONSITE', 'HYBRID', 'REMOTE'
    job_description_html TEXT NOT NULL,
    requirements_html TEXT NOT NULL,
    salary_range_display VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    expires_at DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PELAMAR KERJA (JOB APPLICATIONS)
CREATE TABLE IF NOT EXISTS public.hr_job_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_posting_id UUID NOT NULL REFERENCES public.hr_job_postings(id) ON DELETE CASCADE,
    candidate_name VARCHAR(150) NOT NULL,
    candidate_email VARCHAR(150) NOT NULL,
    candidate_phone VARCHAR(30) NOT NULL,
    resume_file_url TEXT NOT NULL,
    portfolio_url TEXT,
    stage VARCHAR(30) DEFAULT 'APPLIED', -- 'APPLIED', 'SCREENING', 'INTERVIEW', 'OFFERED', 'HIRED', 'REJECTED'
    interviewer_rating INT, -- Skala 1 s.d 10
    interview_notes TEXT,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_job_apps_posting ON public.hr_job_applications (job_posting_id);
CREATE INDEX IF NOT EXISTS idx_job_apps_stage ON public.hr_job_applications (stage);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.hr_job_postings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_job_applications ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh melihat lowongan aktif dan melamar pekerjaan
CREATE POLICY "Allow public read active jobs" 
ON public.hr_job_postings 
FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

CREATE POLICY "Allow public submit job application" 
ON public.hr_job_applications 
FOR INSERT 
TO anon 
WITH CHECK (char_length(trim(candidate_name)) >= 2 AND resume_file_url IS NOT NULL);

-- 2. Khusus HR Recruiter yang boleh membaca data pelamar
CREATE POLICY "Allow HR manage applications" 
ON public.hr_job_applications 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'HR_MANAGER')
);
```

---

## 6. LOGIKA KLIEN: MOVE CANDIDATE STAGE (JAVASCRIPT)

```javascript
/**
 * MOD-29: ATS Drag-and-Drop Stage Updater
 */
async function moveCandidateStage(applicationId, targetStage) {
    try {
        const { error } = await supabaseClient
            .from('hr_job_applications')
            .update({ stage: targetStage })
            .eq('id', applicationId);

        if (error) throw error;
        showNotification(`[SUCCESS] Kandidat dipindahkan ke tahap: ${targetStage}`, 'success');
        refreshATSKanban();
    } catch (err) {
        console.error('[ATS_ERROR]', err);
        showNotification('[ERROR] Gagal memindahkan status kandidat.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA KANBAN ATS

```html
<div class="ats-kanban-wrapper">
    <div class="ats-column">
        <div class="column-title">PELAMAR BARU (APPLIED)</div>
        <div class="applicant-card">
            <h5 class="name">Rian Hidayat</h5>
            <small>Senior Frontend Engineer</small>
            <div class="meta">
                <a href="#" class="link">[LIHAT CV]</a>
                <span class="score">Skor: -</span>
            </div>
        </div>
    </div>
    <div class="ats-column">
        <div class="column-title">WAWANCARA (INTERVIEW)</div>
    </div>
    <div class="ats-column">
        <div class="column-title">DITERIMA (HIRED)</div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Validasi CV Wajib:** Pengajuan lamaran ditolak jika berkas CV PDF tidak terunggah.
- [ ] **Kerahasiaan Data Kandidat:** Publik dilarang mengakses daftar atau data pelamar lain.
- [ ] **Strict No-Emoji:** Status tahapan ATS dan scorecard penilaian bebas emoji.