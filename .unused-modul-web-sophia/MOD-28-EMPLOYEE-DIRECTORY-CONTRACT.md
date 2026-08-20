# SPESIFIKASI MODUL: EMPLOYEE DIRECTORY, ORG CHART & CONTRACTS
> Kode Modul: `MOD-28` | Versi: `1.0.0` | Kategori: `HR & People Operations (REC-11)` | Dependensi: `Supabase, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-28-EMPLOYEE-DIRECTORY-CONTRACT` |
| **Nama Modul** | Employee Directory, Organizational Chart & Contract Management |
| **Kategori** | Human Resources Management (HRIS Core) |
| **Level Akses Publik** | Restricted (HR Manager & Employee Self-View `authenticated`) |
| **Tingkat Decoupling** | High (Fondasi master data karyawan untuk MOD-19, MOD-30, MOD-31, MOD-33) |
| **Integrasi Pilar** | Supabase (Employee Database & Hierarchical Org Chart Tree) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola data induk karyawan (*Employee Master Data*), pohon struktur organisasi (*Organizational Chart & Reporting Lines*), status hubungan kerja & kontrak kerja (PKWT/PKWTT/Magang), riwayat posisi/jabatan, dan dokumen legalitas karyawan secara terpusat dan aman.

### Fitur Utama:
1. **Master Profil Karyawan Lengkap:** NIK KTP, NIP Karyawan, Kontak Darurat, Rekening Penggajian, NPWP/BPJS.
2. **Pohon Struktur Organisasi Visual:** Relasi atasan langsung (*manager_id*) untuk perutean alur approval otomatis.
3. **Peringatan Masa Berakhir Kontrak:** Notifikasi otomatis H-30 sebelum kontrak PKWT karyawan berakhir.
4. **Histori Karir Internal:** Catatan mutasi, promosi, dan perubahan grade gaji.

---

## 3. DIAGRAM HIERARKI ORGANISASI & SIKLUS KARYAWAN

```text
[REKRUTMEN SUKSES (MOD-29)]
     |
     v (1. Onboarding & Pembuatan NIP Baru)
[Supabase: public.employees & public.employee_contracts]
     |-- Simpan Data Personal, Divisi & Atasan Langsung (manager_id)
     |-- Tentukan Status: PKWT (Kontrak 1 Tahun)
     |
     v (2. Operasional Harian)
[Karyawan Mengakses Modul HR]
     |-- Pengajuan Cuti (MOD-30) -> Rute Approval ke Atasan Langsung
     |-- Pengajuan Biaya (MOD-19) -> Rute Approval ke Manajer Divisi
     |-- Evaluasi Kinerja Tahunan (MOD-31)
     |
     v (3. Monitoring Kontrak)
[Cron Alert: H-30 Sebelum Kontrak Berakhir]
     |-- Kirim Notifikasi Review Kontrak ke HR Manager
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL DEPARTEMEN / DIVISI
CREATE TABLE IF NOT EXISTS public.hr_departments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    manager_id UUID, -- Kepala Divisi
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL DATA INDUK KARYAWAN (EMPLOYEES)
CREATE TABLE IF NOT EXISTS public.employees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_nip VARCHAR(30) UNIQUE NOT NULL, -- Contoh: 'EMP-2026-0042'
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    full_name VARCHAR(150) NOT NULL,
    work_email VARCHAR(150) UNIQUE NOT NULL,
    phone_number VARCHAR(30) NOT NULL,
    department_id UUID REFERENCES public.hr_departments(id),
    job_title VARCHAR(100) NOT NULL,
    manager_id UUID REFERENCES public.employees(id), -- Atasan Langsung
    employment_status VARCHAR(30) DEFAULT 'ACTIVE', -- 'ACTIVE', 'ON_LEAVE', 'SUSPENDED', 'RESIGNED', 'TERMINATED'
    hire_date DATE NOT NULL,
    birth_date DATE,
    id_card_number VARCHAR(30), -- NIK KTP
    tax_id VARCHAR(30), -- NPWP
    bank_account_number VARCHAR(50),
    bank_name VARCHAR(50),
    emergency_contact JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL KONTRAK KERJA KARYAWAN (CONTRACTS)
CREATE TABLE IF NOT EXISTS public.employee_contracts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    contract_number VARCHAR(60) UNIQUE NOT NULL,
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    contract_type VARCHAR(30) NOT NULL, -- 'PERMANENT_PKWTT', 'CONTRACT_PKWT', 'INTERNSHIP'
    start_date DATE NOT NULL,
    end_date DATE, -- NULL jika karyawan tetap (PKWTT)
    wage_monthly NUMERIC(15, 2) NOT NULL,
    document_file_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_emp_nip ON public.employees (employee_nip);
CREATE INDEX IF NOT EXISTS idx_emp_dept ON public.employees (department_id);
CREATE INDEX IF NOT EXISTS idx_emp_manager ON public.employees (manager_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.hr_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_contracts ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public HR access" ON public.employees FOR ALL TO anon USING (false);

-- 2. Karyawan boleh melihat data profilnya sendiri
CREATE POLICY "Employee view own profile" 
ON public.employees 
FOR SELECT 
TO authenticated 
USING (
    user_id = auth.uid() OR 
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'HR_MANAGER')
);

-- 3. HR Manager memiliki akses penuh
CREATE POLICY "HR Manager full access" 
ON public.employees 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'HR_MANAGER')
);
```

---

## 6. LOGIKA KLIEN: ORG CHART TREE BUILDER (JAVASCRIPT)

```javascript
/**
 * MOD-28: Hierarchy Org Tree Builder
 */
function buildOrgTree(employees) {
    const map = {};
    const roots = [];

    employees.forEach(emp => {
        map[emp.id] = { ...emp, subordinates: [] };
    });

    employees.forEach(emp => {
        if (emp.manager_id && map[emp.manager_id]) {
            map[emp.manager_id].subordinates.push(map[emp.id]);
        } else {
            roots.push(map[emp.id]);
        }
    });

    return roots;
}
```

---

## 7. SPESIFIKASI ANTARMUKA POHON STRUKTUR ORGANISASI

```html
<div class="org-chart-container">
    <div class="header">
        <h3>Struktur Organisasi & Hierarki Pelaporan</h3>
    </div>
    <div class="tree-root-node">
        <div class="employee-card manager">
            <h4 class="name">Ir. Bambang Setyadi</h4>
            <span class="role-badge">[DIREKTUR UTAMA]</span>
            <small>Divisi: Direksi Eksekutif</small>
        </div>
        <div class="subordinates-branch">
            <div class="employee-card">
                <h4 class="name">Ahmad Fauzan</h4>
                <span class="role-badge">[KEPALA TEKNOLOGI]</span>
                <small>Divisi: Engineering</small>
            </div>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kerahasiaan Gaji:** Nominal gaji pada kontrak hanya dapat dilihat oleh pemilik akun dan tim HR.
- [ ] **Perutean Approval:** Perubahan atasan langsung otomatis mengalihkan rute persetujuan modul cuti dan klaim.
- [ ] **Strict No-Emoji:** Status kepegawaian dan badge struktur organisasi bebas emoji.