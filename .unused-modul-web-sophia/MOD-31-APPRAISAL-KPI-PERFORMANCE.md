# SPESIFIKASI MODUL: EMPLOYEE APPRAISAL & PERFORMANCE REVIEW (KPI/OKR)
> Kode Modul: `MOD-31` | Versi: `1.0.0` | Kategori: `HR & People Operations (REC-14)` | Dependensi: `Supabase, MOD-28`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-31-APPRAISAL-KPI-PERFORMANCE` |
| **Nama Modul** | Employee Appraisal, OKR & Performance Review Engine |
| **Kategori** | Performance Evaluation & Career Development |
| **Level Akses Publik** | Employee (Self-Assessment) / Manager & HR (Reviewer) |
| **Tingkat Decoupling** | High (Menilai kontribusi karyawan pada MOD-28) |
| **Integrasi Pilar** | Supabase (Performance Scorecard & 360 Feedback Matrix) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan kerangka kerja evaluasi kinerja karyawan berkala (Kuartalan / Tahunan) berbasis Target Kunci (*Objectives & Key Results - OKR / Key Performance Indicators - KPI*), penilaian mandiri (*self-assessment*), tinjauan manajer (*manager review*), umpan balik 360 derajat rekan kerja (*peer review*), dan penentuan skor akhir untuk kenaikan gaji/promosi.

### Fitur Utama:
1. **Penyusunan Target OKR / KPI:** Bobot persentase per target capaian (Total 100%).
2. **Evaluasi 360 Derajat:** Penilaian mandiri, penilaian atasan, dan ulasan rekan sejawat.
3. **Kalkulasi Skor Otomatis:** Perhitungan skor berbobot (Skala 1.0 s.d. 5.0 atau Grade A s.d. E).
4. **Matriks 9-Box Talenta:** Pemetaan potensi vs performa untuk perencanaan suksesi kepemimpinan.

---

## 3. DIAGRAM ALUR SIKLUS EVALUASI KINERJA

```text
[AWAL PERIODE (Q1 2026)]
     |
     v (1. Karyawan & Atasan Menetapkan Target KPI/OKR)
[Supabase: public.hr_appraisals & public.hr_appraisal_goals]
     |-- Tetapkan 4 Target Utama (Masing-masing Bobot 25%)
     |
     v (AKHIR PERIODE: Penilaian Diri Sendiri)
[Karyawan Mengisi Self-Assessment & Bukti Capaian]
     |
     v (Tinjauan Atasan Langsung)
[Manajer Memberikan Skor & Catatan Pengembangan]
     |-- Finalisasi Skor Akhir (Misal: 4.6 / Grade A - Sangat Memuaskan)
     |
     v (Hasil Review Dibuka)
[HR Mengarsipkan Hasil untuk Acuan Bonus / Promosi Karir]
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL PERIODE EVALUASI (APPRAISAL PERIODS)
CREATE TABLE IF NOT EXISTS public.hr_appraisal_periods (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- Contoh: 'Evaluasi Tahunan 2026'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'ACTIVE', -- 'DRAFT', 'ACTIVE', 'CLOSED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL LEMBAR EVALUASI KARYAWAN (APPRAISALS)
CREATE TABLE IF NOT EXISTS public.hr_appraisals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    period_id UUID NOT NULL REFERENCES public.hr_appraisal_periods(id),
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    manager_id UUID NOT NULL REFERENCES public.employees(id),
    final_score NUMERIC(4, 2), -- Contoh: 4.75
    performance_grade VARCHAR(10), -- 'A', 'B', 'C', 'D', 'E'
    status VARCHAR(30) DEFAULT 'DRAFT', -- 'DRAFT', 'SELF_REVIEW', 'MANAGER_REVIEW', 'COMPLETED'
    employee_notes TEXT,
    manager_feedback TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL TARGET CAPAIAN KPI (APPRAISAL GOALS)
CREATE TABLE IF NOT EXISTS public.hr_appraisal_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    appraisal_id UUID NOT NULL REFERENCES public.hr_appraisals(id) ON DELETE CASCADE,
    goal_title VARCHAR(255) NOT NULL,
    weight_percentage INT NOT NULL, -- Contoh: 25%
    target_metric VARCHAR(100) NOT NULL,
    actual_achieved VARCHAR(100),
    score NUMERIC(4, 2) DEFAULT 0.00 -- 1.0 s.d 5.0
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_appraisal_emp ON public.hr_appraisals (employee_id, period_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.hr_appraisal_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_appraisals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_appraisal_goals ENABLE ROW LEVEL SECURITY;

-- 1. Karyawan hanya bisa melihat lembar evaluasi miliknya
CREATE POLICY "Employee view own appraisal" 
ON public.hr_appraisals 
FOR SELECT 
TO authenticated 
USING (
    employee_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()) OR
    manager_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()) OR
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'HR_MANAGER')
);
```

---

## 6. LOGIKA KLIEN: FINAL SCORE CALCULATOR (JAVASCRIPT)

```javascript
/**
 * MOD-31: Calculate Weighted Appraisal Score
 */
function calculateWeightedAppraisal(goals) {
    let totalScore = 0;
    let totalWeight = 0;

    goals.forEach(g => {
        totalScore += (parseFloat(g.score) || 0) * (g.weight_percentage / 100);
        totalWeight += g.weight_percentage;
    });

    let grade = 'C';
    if (totalScore >= 4.5) grade = 'A';
    else if (totalScore >= 3.5) grade = 'B';
    else if (totalScore >= 2.5) grade = 'C';
    else if (totalScore >= 1.5) grade = 'D';
    else grade = 'E';

    return { finalScore: totalScore.toFixed(2), performanceGrade: grade };
}
```

---

## 7. SPESIFIKASI ANTARMUKA LEMBAR REVIEW KINERJA

```html
<div class="appraisal-card">
    <div class="header">
        <h3>Evaluasi Kinerja Karyawan: Q3 2026</h3>
        <span class="badge badge-success">[GRADE AKHIR: A - SANGAT MEMUASKAN]</span>
    </div>
    <div class="goals-list">
        <div class="goal-item">
            <strong>Target 1 (Bobot 30%):</strong> Peningkatan Uptime Sistem Web ke 99.95%
            <p>Pencapaian Aktual: 99.98% | <strong>Skor: 5.0 / 5.0</strong></p>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Validasi Bobot 100%:** Total persentase bobot seluruh target KPI wajib bernilai tepat 100%.
- [ ] **Kerahasiaan Feedback:** Karyawan tidak dapat mengedit nilai yang telah ditetapkan oleh atasan.
- [ ] **Strict No-Emoji:** Status review dan label grade performa bebas emoji.