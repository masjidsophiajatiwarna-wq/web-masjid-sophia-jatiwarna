# SPESIFIKASI MODUL: TIME-OFF & LEAVE MANAGEMENT SYSTEM
> Kode Modul: `MOD-30` | Versi: `1.0.0` | Kategori: `HR & People Operations (REC-13)` | Dependensi: `Supabase, MOD-28, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-30-TIME-OFF-LEAVE-MANAGEMENT` |
| **Nama Modul** | Time-Off, Leave Balance & Attendance Exception Management |
| **Kategori** | Leave Administration & Absence Tracking |
| **Level Akses Publik** | Employee Self-Service (Klaim Cuti) / Manager (Approval) |
| **Tingkat Decoupling** | High (Mengatur ketersediaan staf untuk MOD-10 dan MOD-33) |
| **Integrasi Pilar** | Supabase (Leave Balance Ledger & Manager Routing), Resend (Approval Alert) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengotomatisasi alokasi saldo cuti tahunan (*Annual Leave Quota*), pengajuan izin/sakit/cuti melahirkan oleh karyawan secara mandiri, persetujuan bertingkat oleh atasan langsung (*manager approval*), pemotongan saldo cuti otomatis, dan kalender bersama ketersediaan tim (*Team Absence Calendar*).

### Fitur Utama:
1. **Multi-Type Leave Allocation:** Cuti Tahunan (12 hari), Cuti Sakit (dengan lampiran surat dokter), Cuti Menikah, Cuti Duka.
2. **Pengecekan Saldo Atomik:** Mencegah pengajuan cuti jika saldo hari tidak mencukupi.
3. **Persetujuan Otomatis Atasan Langsung:** Permohonan otomatis diteruskan ke email manajer divisi yang tercatat di MOD-28.
4. **Team Availability Calendar:** Tampilan kalender bersama agar staf tidak mengambil cuti serentak di divisi yang sama.

---

## 3. DIAGRAM ALUR PENGAJUAN CUTI KARYAWAN

```text
[KARYAWAN]
     |
     v (1. Pilih Tipe Cuti & Rentang Tanggal: 24 - 26 Agustus 2026 / 3 Hari)
[Pengecekan Saldo Cuti (Supabase Trigger)]
     |-- Sisa Cuti: 8 Hari -> Pengajuan: 3 Hari -> Saldo Cukup!
     |
     v (2. Kirim Notifikasi Email ke Atasan Langsung)
[Manajer Divisi / Atasan]
     |-- Klik "SETUJUI" via Portal / Email Resend
     |
     v (3. Pemotongan Saldo Cuti)
[Supabase: public.hr_leave_allocations]
     |-- Sisa Saldo Baru: 5 Hari
     |-- Status Pengajuan: "APPROVED"
     |-- Tandai Tanggal di Kalender Tim
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL TIPE CUTI (LEAVE TYPES)
CREATE TABLE IF NOT EXISTS public.hr_leave_types (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- 'Cuti Tahunan', 'Izin Sakit', 'Cuti Melahirkan'
    default_days_per_year INT NOT NULL DEFAULT 12,
    requires_attachment BOOLEAN DEFAULT false, -- Wajib upload surat dokter
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL ALOKASI SALDO CUTI KARYAWAN (LEAVE ALLOCATIONS)
CREATE TABLE IF NOT EXISTS public.hr_leave_allocations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    leave_type_id UUID NOT NULL REFERENCES public.hr_leave_types(id),
    year INT NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    total_allocated INT NOT NULL DEFAULT 12,
    used_days INT NOT NULL DEFAULT 0,
    remaining_days INT GENERATED ALWAYS AS (total_allocated - used_days) STORED,
    UNIQUE(employee_id, leave_type_id, year)
);

-- TABEL PENGAJUAN CUTI (LEAVE REQUESTS)
CREATE TABLE IF NOT EXISTS public.hr_leave_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    leave_type_id UUID NOT NULL REFERENCES public.hr_leave_types(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    duration_days INT NOT NULL,
    reason TEXT NOT NULL,
    attachment_url TEXT,
    status VARCHAR(30) DEFAULT 'SUBMITTED', -- 'SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED'
    approved_by UUID REFERENCES public.employees(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_leave_req_emp ON public.hr_leave_requests (employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_req_status ON public.hr_leave_requests (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.hr_leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_leave_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_leave_requests ENABLE ROW LEVEL SECURITY;

-- 1. Karyawan boleh melihat tipe cuti dan saldonya sendiri
CREATE POLICY "Allow read leave types" ON public.hr_leave_types FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow employee read own leave balance" 
ON public.hr_leave_allocations 
FOR SELECT 
TO authenticated 
USING (
    employee_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()) OR
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'HR_MANAGER')
);

CREATE POLICY "Allow employee manage own leave requests" 
ON public.hr_leave_requests 
FOR ALL 
TO authenticated 
USING (
    employee_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()) OR
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'HR_MANAGER')
);
```

---

## 6. LOGIKA KLIEN: LEAVE SUBMISSION HANDLER (JAVASCRIPT)

```javascript
/**
 * MOD-30: Leave Request Submitter
 */
async function submitLeaveRequest(payload) {
    try {
        const { data, error } = await supabaseClient
            .from('hr_leave_requests')
            .insert([payload])
            .select()
            .single();

        if (error) throw error;
        showNotification('[SUCCESS] Permohonan cuti berhasil dikirim untuk persetujuan atasan.', 'success');
    } catch (err) {
        console.error('[LEAVE_ERROR]', err);
        showNotification('[ERROR] Saldo cuti tidak mencukupi atau tanggal tidak valid.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA SALDO CUTI KARYAWAN

```html
<div class="leave-dashboard">
    <div class="balance-cards">
        <div class="card">
            <h4>Cuti Tahunan 2026</h4>
            <h2>8 Hari Tersisa</h2>
            <small>Total Alokasi: 12 Hari | Terpakai: 4 Hari</small>
        </div>
    </div>
    <div class="request-history">
        <h4>Riwayat Permohonan Terakhir</h4>
        <table class="data-table">
            <thead><tr><th>Tanggal</th><th>Tipe</th><th>Durasi</th><th>Status</th></tr></thead>
            <tbody>
                <tr><td>12-14 Juli 2026</td><td>Cuti Tahunan</td><td>3 Hari</td><td><span class="badge badge-success">[DISETUJUI]</span></td></tr>
            </tbody>
        </table>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Pencegahan Saldo Minus:** Pengajuan cuti yang melebihi sisa hari otomatis digagalkan di level database.
- [ ] **Validasi Tanggal:** Tanggal akhir cuti tidak boleh mendahului tanggal awal.
- [ ] **Strict No-Emoji:** Status persetujuan cuti bebas emoji.