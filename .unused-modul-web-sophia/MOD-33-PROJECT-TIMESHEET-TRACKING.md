# SPESIFIKASI MODUL: PROJECT TASK & TIMESHEET BILLABLE HOURS MANAGEMENT
> Kode Modul: `MOD-33` | Versi: `1.0.0` | Kategori: `Layanan & Kolaborasi (REC-16)` | Dependensi: `Supabase, MOD-07, MOD-28`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-33-PROJECT-TIMESHEET-TRACKING` |
| **Nama Modul** | Project Task, Timesheet & Billable Hours Management |
| **Kategori** | Professional Services & Project Operations |
| **Level Akses Publik** | Project Manager & Team Member (`authenticated`) |
| **Tingkat Decoupling** | High (Menyuplai jam kerja tagihan ke MOD-07 Invoicing) |
| **Integrasi Pilar** | Supabase (Project Kanban, Task Sub-tree & Timesheet Timer) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola penugasan proyek klien (software development, agensi kreatif, jasa konsultasi hukum/arsitektur) melalui papan Kanban tugas (*Task Board*), pencatatan jam kerja (*Timesheet Logging & Live Timer*), pelacakan jam kerja yang dapat ditagihkan ke klien (*Billable Hours*), dan konversi otomatis menjadi invoice pada MOD-07.

### Fitur Utama:
1. **Papan Tugas Kanban Proyek:** Tahapan pengerjaan (`BACKLOG`, `TO_DO`, `IN_PROGRESS`, `CODE_REVIEW`, `DONE`).
2. **Live Timesheet Stopwatch:** Timer klik-mulai / klik-selesai di browser untuk merekam durasi pengerjaan tugas.
3. **Kalkulasi Biaya Jam Kerja (Billable Rate):** Tarif per jam per karyawan untuk penagihan klien.
4. **Auto-Generate Invoice ke MOD-07:** Konversi 40 jam billable hours menjadi item faktur dalam satu klik.

---

## 3. DIAGRAM ALUR PROYEK & PENAGIHAN TIMESHEET

```text
[PROJECT MANAGER (project-board.html)]
     |
     v (1. Buat Proyek Klien & Bagi Task Sub-tugas)
[Supabase: public.project_tasks]
     |
     v (2. Anggota Tim Mengerjakan Task)
[Timesheet Live Timer (Stopwatch JS)]
     |-- Klik "Start Work" -> 2 Jam 30 Menit -> Klik "Stop & Log"
     |-- Tandai: is_billable = true (Tarif: Rp 250.000 / Jam)
     |
     v (3. Akhir Bulan / Milestone Selesai)
[Generate Faktur Klien (MOD-07 Invoicing)]
     |-- Tarik Total Billable Hours: 40 Jam x Rp 250.000 = Rp 10.000.000
     |-- Terbitkan Nomor Invoice Resmi
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL PROYEK (PROJECTS)
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    client_email VARCHAR(150),
    hourly_rate NUMERIC(15, 2) DEFAULT 0.00,
    budget_amount NUMERIC(15, 2) DEFAULT 0.00,
    status VARCHAR(30) DEFAULT 'ACTIVE', -- 'PLANNING', 'ACTIVE', 'ON_HOLD', 'COMPLETED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL TUGAS PROYEK (PROJECT TASKS)
CREATE TABLE IF NOT EXISTS public.project_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    assigned_to UUID REFERENCES public.employees(id),
    stage VARCHAR(30) DEFAULT 'TO_DO', -- 'BACKLOG', 'TO_DO', 'IN_PROGRESS', 'REVIEW', 'DONE'
    estimated_hours NUMERIC(6, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL LOG JAM KERJA (TIMESHEETS)
CREATE TABLE IF NOT EXISTS public.project_timesheets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    task_id UUID NOT NULL REFERENCES public.project_tasks(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES public.employees(id),
    work_date DATE NOT NULL DEFAULT CURRENT_DATE,
    duration_hours NUMERIC(6, 2) NOT NULL,
    description TEXT NOT NULL,
    is_billable BOOLEAN DEFAULT true,
    is_invoiced BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_tasks_proj ON public.project_tasks (project_id, stage);
CREATE INDEX IF NOT EXISTS idx_timesheet_emp ON public.project_timesheets (employee_id, work_date);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_timesheets ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public project access" ON public.projects FOR ALL TO anon USING (false);

-- 2. Staff memiliki akses kelola
CREATE POLICY "Allow authenticated manage projects" 
ON public.projects 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: LIVE TIMESHEET TIMER (JAVASCRIPT)

```javascript
/**
 * MOD-33: Live Stopwatch Task Timer
 */
let timerInterval = null;
let timerStart = null;

function startTaskTimer(taskId) {
    timerStart = Date.now();
    timerInterval = setInterval(() => {
        const elapsedSeconds = Math.floor((Date.now() - timerStart) / 1000);
        const hours = String(Math.floor(elapsedSeconds / 3600)).padStart(2, '0');
        const mins = String(Math.floor((elapsedSeconds % 3600) / 60)).padStart(2, '0');
        const secs = String(elapsedSeconds % 60).padStart(2, '0');
        document.getElementById('timer-display').innerText = `${hours}:${mins}:${secs}`;
    }, 1000);
}

async function stopAndLogTimer(taskId, empId, desc) {
    clearInterval(timerInterval);
    const durationHours = ((Date.now() - timerStart) / (1000 * 3600)).toFixed(2);

    await supabaseClient.from('project_timesheets').insert([{
        task_id: taskId,
        employee_id: empId,
        duration_hours: parseFloat(durationHours),
        description: desc,
        is_billable: true
    }]);

    showNotification(`[SUCCESS] Waktu kerja ${durationHours} jam berhasil dicatat.`, 'success');
}
```

---

## 7. SPESIFIKASI ANTARMUKA KANBAN PROYEK

```html
<div class="project-card">
    <div class="header">
        <h3>Papan Tugas Proyek: Redesign Website Korporat</h3>
        <div class="timer-widget">
            <span id="timer-display">00:00:00</span>
            <button type="button" class="btn btn-sm btn-primary" onclick="startTaskTimer('task-1')">Mulai Kerja</button>
        </div>
    </div>
    <div class="kanban-grid">
        <div class="column">
            <h4>DALAM PENGERJAAN (IN PROGRESS)</h4>
            <div class="task-box">
                <h5>Integrasi API Payment Gateway</h5>
                <small>PIC: Ahmad Fauzan | Est: 8 Jam</small>
            </div>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Akurasi Stopwatch:** Durasi jam kerja terhitung presisi hingga 2 desimal.
- [ ] **Pencegahan Double-Billing:** Item timesheet yang sudah ditagihkan (`is_invoiced = true`) tidak dapat ditarik ulang ke faktur baru.
- [ ] **Strict No-Emoji:** Status tugas dan label timesheet bebas emoji.