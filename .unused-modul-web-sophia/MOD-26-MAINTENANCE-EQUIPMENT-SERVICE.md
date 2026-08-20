# SPESIFIKASI MODUL: EQUIPMENT MAINTENANCE & WORK CENTER REPAIR
> Kode Modul: `MOD-26` | Versi: `1.0.0` | Kategori: `Supply Chain & Manufaktur (REC-09)` | Dependensi: `Supabase, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-26-MAINTENANCE-EQUIPMENT-SERVICE` |
| **Nama Modul** | Equipment Maintenance & Work Center Repair Engine |
| **Kategori** | Asset Maintenance & Preventive Service Management |
| **Level Akses Publik** | Maintenance Technician & Plant Supervisor (`authenticated`) |
| **Tingkat Decoupling** | High (Menjaga kesiapan mesin kerja untuk MOD-24 Manufaktur) |
| **Integrasi Pilar** | Supabase (Equipment State & Maintenance Calendar), Resend (Service Alert) |

---

## 2. TUJUAN BISNIS & USE CASE

Memaksimalkan masa pakai alat operasional (*Overall Equipment Effectiveness - OEE*) dan mencegah terhentinya lini produksi (*downtime*) melalui penjadwalan pemeliharaan rutin pencegahan (*Preventive Maintenance*), penanganan perbaikan insidental (*Corrective Maintenance Work Request*), dan pelacakan suku cadang terpakai.

### Fitur Utama:
1. **Pencatatan Master Mesin/Peralatan:** Nomor seri, tanggal beli, masa garansi, interval jam operasi.
2. **Preventive Maintenance Scheduler:** Pemicu servis berkala berbasis kalender (bulanan) atau jam operasi.
3. **Corrective Repair Ticket:** Form pelaporan kerusakan mesin dari operator lantai kerja.
4. **Log Riwayat Servis:** Rekam jejak penggantian suku cadang dan teknisi penanggung jawab.

---

## 3. DIAGRAM ALUR PEMELIHARAAN ALAT & SERVIS

```text
[PEMICU PEMELIHARAAN]
   |-- Opsi A: Jadwal Rutin Preventif (Setiap 500 Jam Operasi)
   |-- Opsi B: Laporan Kerusakan dari Operator Lantai Pabrik (Breakdown)
   |
   v
[Supabase: public.maintenance_requests]
   |-- Terbitkan Tiket Servis: MNT-20260819-0008
   |-- Tetapkan Tingkat Urgensi: "HIGH" / "MACHINE_STOPPED"
   |
   v
[Teknisi Melakukan Servis & Penggantian Suku Cadang]
   |-- Catat Jam Pengerjaan & Komponen Sparepart dari MOD-09
   |
   v
[Mesin Kembali Operasional (Status: REPAIRED / OPERATIONAL)]
   |-- Kirim Notifikasi ke Supervisor Pabrik
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL ASET MESIN / PERALATAN (EQUIPMENT)
CREATE TABLE IF NOT EXISTS public.maintenance_equipment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    equipment_code VARCHAR(60) UNIQUE NOT NULL, -- Contoh: 'MCH-CNC-01'
    name VARCHAR(200) NOT NULL,
    work_center_zone VARCHAR(100),
    serial_number VARCHAR(100),
    maintenance_interval_days INT DEFAULT 30, -- Servis rutin setiap 30 hari
    last_serviced_date DATE,
    next_service_due DATE,
    status VARCHAR(30) DEFAULT 'OPERATIONAL', -- 'OPERATIONAL', 'MAINTENANCE', 'BREAKDOWN', 'RETIRED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PERMINTAAN SERVIS (MAINTENANCE REQUESTS)
CREATE TABLE IF NOT EXISTS public.maintenance_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_number VARCHAR(60) UNIQUE NOT NULL, -- Format: MNT-YYYYMMDD-XXXX
    equipment_id UUID NOT NULL REFERENCES public.maintenance_equipment(id),
    maintenance_type VARCHAR(30) NOT NULL, -- 'PREVENTIVE', 'CORRECTIVE'
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    issue_description TEXT NOT NULL,
    technician_id UUID REFERENCES public.admin_users(id),
    status VARCHAR(30) DEFAULT 'NEW', -- 'NEW', 'IN_PROGRESS', 'REPAIRED', 'SCRAPPED'
    serviced_at TIMESTAMP WITH TIME ZONE,
    parts_cost NUMERIC(15, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_equip_status ON public.maintenance_equipment (status);
CREATE INDEX IF NOT EXISTS idx_maint_req_status ON public.maintenance_requests (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.maintenance_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_requests ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public maintenance access" ON public.maintenance_requests FOR ALL TO anon USING (false);

-- 2. Staff Teknisi & Admin memiliki akses kelola
CREATE POLICY "Allow maintenance staff manage requests" 
ON public.maintenance_requests 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: COMPLETE MAINTENANCE HANDLER (JAVASCRIPT)

```javascript
/**
 * MOD-26: Maintenance Service Completion
 */
async function completeMaintenanceWork(requestId, equipmentId) {
    try {
        await supabaseClient
            .from('maintenance_requests')
            .update({
                status: 'REPAIRED',
                serviced_at: new Date().toISOString()
            })
            .eq('id', requestId);

        await supabaseClient
            .from('maintenance_equipment')
            .update({
                status: 'OPERATIONAL',
                last_serviced_date: new Date().toISOString().slice(0, 10)
            })
            .eq('id', equipmentId);

        showNotification('[SUCCESS] Pemeliharaan mesin selesai & status unit kembali operasional.', 'success');
    } catch (err) {
        console.error('[MAINTENANCE_ERROR]', err);
        showNotification('[ERROR] Gagal mengupdate status pemeliharaan.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA STATUS MESIN

```html
<div class="equipment-card">
    <div class="header">
        <h3>Pusat Pemantauan Kesehatan Mesin Operasional</h3>
    </div>
    <table class="data-table">
        <thead>
            <tr><th>Kode Mesin</th><th>Nama Mesin</th><th>Lokasi Lini</th><th>Jadwal Servis Berikutnya</th><th>Status</th></tr>
        </thead>
        <tbody>
            <tr>
                <td><code>MCH-CNC-01</code></td>
                <td>Mesin CNC Router 3-Axis</td>
                <td>Lantai Perakitan 1</td>
                <td>28 Agustus 2026</td>
                <td><span class="badge badge-success">[OPERATIONAL]</span></td>
            </tr>
            <tr>
                <td><code>MCH-LSR-02</code></td>
                <td>Mesin Laser Cutting Baja</td>
                <td>Lantai Pemotongan</td>
                <td>Jatuh Tempo Kemarin</td>
                <td><span class="badge badge-danger">[PERLU SERVIS PREVENTIF]</span></td>
            </tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Pencegahan Penggunaan Mesin Rusak:** Mesin berstatus `BREAKDOWN` tidak dapat dipilih pada Work Order MOD-24.
- [ ] **Pengingat Servis Rutin:** Muncul peringatan otomatis jika tanggal servis berikutnya telah tercapai.
- [ ] **Strict No-Emoji:** Status mesin dan label prioritas servis bebas emoji.