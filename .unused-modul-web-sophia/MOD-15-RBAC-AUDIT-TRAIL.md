# SPESIFIKASI MODUL: RBAC GRANULAR PERMISSIONS & AUDIT TRAIL SYSTEM
> Kode Modul: `MOD-15` | Versi: `1.0.0` | Kategori: `Security, Governance & Access Control` | Dependensi: `Supabase Auth, PostgreSQL RLS`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-15-RBAC-AUDIT-TRAIL` |
| **Nama Modul** | Role-Based Access Control (RBAC) & Immutable Audit Trail |
| **Kategori** | Security, Identity Governance & Compliance |
| **Level Akses Publik** | Restricted (Fondasi Keamanan Seluruh Modul Backoffice) |
| **Tingkat Decoupling** | Core Foundation (Menjadi acuan izin otentikasi semua modul) |
| **Integrasi Pilar** | Supabase Auth (JWT Claims), PostgreSQL RLS (Security Context) |

---

## 2. TUJUAN BISNIS & USE CASE

Mencegah penyalahgunaan wewenang internal dan mematuhi standar kepatuhan (*compliance*) data dengan menetapkan hak akses berbasis peran granular (*Role-Based Access Control: Superadmin, Manager, Editor, Finance, Staff*), serta mencatat setiap perubahan data kritis (*INSERT, UPDATE, DELETE*) ke dalam tabel buku audit yang tidak dapat dihapus (*immutable append-only audit trail*).

### Fitur Utama:
1. **Hierarki Peran Fleksibel (RBAC):** Penetapan hak akses per modul (`can_view`, `can_create`, `can_edit`, `can_delete`, `can_export`).
2. **PostgreSQL CDC Trigger Audit:** Mencatat snapshot data lama (*OLD record*) dan data baru (*NEW record*) secara otomatis dalam format JSONB.
3. **Audit Log Forensik:** Melacak siapa yang mengubah data, kapan diubah, dari IP mana, dan nilai apa yang berubah.
4. **Proteksi Anti-Tamper:** Tabel audit tidak memiliki izin `UPDATE` atau `DELETE` bahkan untuk akun admin.

---

## 3. DIAGRAM ARSITEKTUR KEAMANAN & AUDIT TRAIL

```text
[ADMIN / STAFF LOGIN]
     |
     v (1. Ambil JWT Session)
[Evaluasi Izin RBAC di Level RLS]
     |-- Cek Peran Pengguna: auth.jwt() ->> 'email' -> public.admin_users.role
     |-- Validasi Permission: Apakah Role "Editor" punya akses ke modul "Finance"?
     |
     v (2. Operasi Data: INSERT / UPDATE / DELETE)
[PostgreSQL CDC Audit Trigger: trg_audit_trail_logger]
     |-- Ekstrak snapshot data sebelum & sesudah
     |-- Simpan ke public.audit_trail_logs (APPEND ONLY)
     |
     v (3. Selesai)
[Data Tersimpan Bersama Jejak Forensik Penuh]
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL PENGGUNA ADMIN (ADMIN USERS)
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'STAFF', -- 'SUPERADMIN', 'MANAGER', 'EDITOR', 'FINANCE', 'STAFF'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL LOG AUDIT FORENSIK (IMMUTABLE AUDIT TRAIL)
CREATE TABLE IF NOT EXISTS public.audit_trail_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100) NOT NULL,
    action_type VARCHAR(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    old_data JSONB,
    new_data JSONB,
    changed_fields TEXT[],
    actor_email VARCHAR(150),
    actor_ip VARCHAR(45),
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING LOG AUDIT
CREATE INDEX IF NOT EXISTS idx_audit_table_record ON public.audit_trail_logs (table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON public.audit_trail_logs (actor_email);
CREATE INDEX IF NOT EXISTS idx_audit_time ON public.audit_trail_logs (performed_at DESC);

-- GENERIC AUDIT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.log_table_audit_event()
RETURNS TRIGGER AS $$
DECLARE
    v_old JSONB := NULL;
    v_new JSONB := NULL;
    v_record_id VARCHAR := '';
    v_actor VARCHAR := NULL;
BEGIN
    v_actor := auth.jwt() ->> 'email';

    IF (TG_OP = 'DELETE') THEN
        v_old := to_jsonb(OLD);
        v_record_id := OLD.id::TEXT;
        INSERT INTO public.audit_trail_logs (table_name, record_id, action_type, old_data, actor_email)
        VALUES (TG_TABLE_NAME, v_record_id, 'DELETE', v_old, v_actor);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
        v_record_id := NEW.id::TEXT;
        INSERT INTO public.audit_trail_logs (table_name, record_id, action_type, old_data, new_data, actor_email)
        VALUES (TG_TABLE_NAME, v_record_id, 'UPDATE', v_old, v_new, v_actor);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new := to_jsonb(NEW);
        v_record_id := NEW.id::TEXT;
        INSERT INTO public.audit_trail_logs (table_name, record_id, action_type, new_data, actor_email)
        VALUES (TG_TABLE_NAME, v_record_id, 'INSERT', v_new, v_actor);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_trail_logs ENABLE ROW LEVEL SECURITY;

-- 1. Blokir semua akses publik
CREATE POLICY "Deny public admin access" ON public.admin_users FOR ALL TO anon USING (false);
CREATE POLICY "Deny public audit access" ON public.audit_trail_logs FOR ALL TO anon USING (false);

-- 2. Izin Baca Admin Users
CREATE POLICY "Allow authenticated read admin list" 
ON public.admin_users 
FOR SELECT 
TO authenticated 
USING (is_active = true);

-- 3. Tabel Audit: APPEND ONLY (Dilarang UPDATE dan DELETE sama sekali)
CREATE POLICY "Allow read audit log for superadmin only" 
ON public.audit_trail_logs 
FOR SELECT 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE role = 'SUPERADMIN' AND is_active = true)
);

CREATE POLICY "Allow system insert audit log" 
ON public.audit_trail_logs 
FOR INSERT 
TO authenticated 
WITH CHECK (true);
```

---

## 6. LOGIKA KLIEN: RBAC PERMISSION GUARD (JAVASCRIPT)

```javascript
/**
 * MOD-15: Client-Side RBAC Guard
 */
const ROLE_PERMISSIONS = {
    'SUPERADMIN': ['all'],
    'MANAGER': ['view_all', 'edit_all', 'export_all'],
    'EDITOR': ['view_articles', 'edit_articles', 'publish_articles'],
    'FINANCE': ['view_payments', 'verify_payments', 'manage_invoices'],
    'STAFF': ['view_submissions', 'update_ticket_status']
};

function hasPermission(userRole, requiredPermission) {
    if (!ROLE_PERMISSIONS[userRole]) return false;
    if (ROLE_PERMISSIONS[userRole].includes('all')) return true;
    return ROLE_PERMISSIONS[userRole].includes(requiredPermission);
}
```

---

## 7. SPESIFIKASI ANTARMUKA AUDIT LOG VIEWER

```html
<div class="audit-log-container">
    <div class="header-bar">
        <h3>Buku Besar Audit Sistem (Immutable Trail)</h3>
        <span class="badge badge-primary">[PROTEKSI: APPEND-ONLY]</span>
    </div>

    <table class="data-table">
        <thead>
            <tr>
                <th>Waktu</th>
                <th>Tabel</th>
                <th>Aksi</th>
                <th>Pelaksana (Aktor)</th>
                <th>Rincian Perubahan Data</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>2026-08-19 14:20:11</td>
                <td><code>payment_transactions</code></td>
                <td><span class="badge badge-success">[UPDATE]</span></td>
                <td>finance@domain.com</td>
                <td>Status diubah dari <code>WAITING_PAYMENT</code> ke <code>PAID</code></td>
            </tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Anti-Tamper Lock:** Tidak ada perintah SQL `UPDATE` atau `DELETE` yang dapat dijalankan pada tabel `audit_trail_logs`.
- [ ] **Akurasi JSON Snapshot:** Snapshot `old_data` dan `new_data` menangkap seluruh atribut kolom sebelum dan sesudah perubahan.
- [ ] **Pemberian Hak Granular:** Akun dengan peran `EDITOR` tidak bisa mengakses modul pembayaran `FINANCE`.
- [ ] **Strict No-Emoji:** Penanda peran dan tipe aksi audit (`[INSERT]`, `[UPDATE]`, `[DELETE]`) bebas emoji.