# SPESIFIKASI MODUL: QUALITY CONTROL & ASSURANCE (QC/QA INSPECTION)
> Kode Modul: `MOD-27` | Versi: `1.0.0` | Kategori: `Supply Chain & Manufaktur (REC-10)` | Dependensi: `Supabase, MOD-09, MOD-23, MOD-24`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-27-QUALITY-CONTROL-ASSURANCE` |
| **Nama Modul** | Quality Control & Assurance (QC/QA) Inspection Engine |
| **Kategori** | Quality Management & Compliance Inspection |
| **Level Akses Publik** | Quality Inspector & Plant QC Manager (`authenticated`) |
| **Tingkat Decoupling** | High (Titik gerbang inspeksi pada penerimaan barang MOD-23 & hasil produksi MOD-24) |
| **Integrasi Pilar** | Supabase (QC Checklist Matrix & Quarantine Ledger) |

---

## 2. TUJUAN BISNIS & USE CASE

Menjamin standar mutu produk tetap konsisten sesuai spesifikasi toleransi teknis melalui titik inspeksi mutu (*Quality Control Points - QCP*) pada saat penerimaan bahan mentah dari pemasok, selama proses perakitan, dan sebelum pengiriman barang jadi ke pelanggan, lengkap dengan penanganan barang cacat (*Quarantine & Scrap Management*).

### Fitur Utama:
1. **Titik Inspeksi Fleksibel (QC Points):** Inspeksi Penerimaan (*Incoming*), Inspeksi Proses (*In-Process*), dan Inspeksi Akhir (*Final Pre-Shipment*).
2. **Kriteria Lolos / Gagal (Pass / Fail Criteria):** Pengukuran dimensi (mm), uji berat (gram), uji visual kecacatan, dan toleransi deviasi.
3. **Karantina Produk Gagal (Quarantine Isolation):** Pemindahan otomatis item cacat ke area karantina khusus agar tidak terkirim ke konsumen.
4. **Sertifikat Kelayakan Mutu (Certificate of Analysis - CoA):** Ringkasan hasil uji inspeksi siap cetak.

---

## 3. DIAGRAM ALUR INSPEKSI MUTU (QC WORKFLOW)

```text
[TITIK INSPEKSI MUTU (QCP)]
   |-- Incoming Material dari MOD-23
   |-- Finished Goods dari MOD-24
   |
   v
[Supabase: public.qc_inspections]
   |-- Pengujian Sampel: Cek Dimensi, Cacat Visual, dan Fungsi
   |
   +---> [Lolos Uji: PASS]  -> Barang Masuk ke Stok Siap Jual (MOD-09 / MOD-06)
   |
   +---> [Gagal Uji: FAIL]  -> Masuk ke Gudang Karantina (Status: QUARANTINE)
         |
         +---> Retur ke Vendor Pemasok (MOD-23)
         |
         +---> Daur Ulang / Hapus Buku (Scrap Write-Off)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL TITIK INSPEKSI (QUALITY CONTROL POINTS)
CREATE TABLE IF NOT EXISTS public.qc_control_points (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    product_id UUID NOT NULL REFERENCES public.products(id),
    inspection_type VARCHAR(50) NOT NULL, -- 'INCOMING', 'IN_PROCESS', 'FINAL'
    test_instructions TEXT NOT NULL,
    tolerance_min NUMERIC(10, 3),
    tolerance_max NUMERIC(10, 3),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL HASIL INSPEKSI (QC INSPECTIONS)
CREATE TABLE IF NOT EXISTS public.qc_inspections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    inspection_number VARCHAR(60) UNIQUE NOT NULL, -- Format: QCI-YYYYMMDD-XXXX
    control_point_id UUID NOT NULL REFERENCES public.qc_control_points(id),
    lot_batch_number VARCHAR(100) NOT NULL,
    sample_size INT NOT NULL DEFAULT 1,
    measured_value NUMERIC(10, 3),
    result VARCHAR(20) NOT NULL, -- 'PASS', 'FAIL', 'QUARANTINE'
    defect_notes TEXT,
    inspector_id UUID REFERENCES public.admin_users(id),
    inspected_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_qc_prod_type ON public.qc_control_points (product_id, inspection_type);
CREATE INDEX IF NOT EXISTS idx_qc_inspections_res ON public.qc_inspections (result);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.qc_control_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qc_inspections ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public QC access" ON public.qc_inspections FOR ALL TO anon USING (false);

-- 2. Staff QC & Plant Manager memiliki akses kelola
CREATE POLICY "Allow QC staff manage inspections" 
ON public.qc_inspections 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: QC TEST RECORDER (JAVASCRIPT)

```javascript
/**
 * MOD-27: Record QC Inspection Result
 */
async function submitQCResult(payload) {
    const isPass = (payload.measuredValue >= payload.tolMin && payload.measuredValue <= payload.tolMax);
    const resultStatus = isPass ? 'PASS' : 'FAIL';

    try {
        const { data, error } = await supabaseClient
            .from('qc_inspections')
            .insert([{
                inspection_number: `QCI-${Date.now()}`,
                control_point_id: payload.controlPointId,
                lot_batch_number: payload.batchNo,
                sample_size: payload.sampleSize,
                measured_value: payload.measuredValue,
                result: resultStatus,
                defect_notes: isPass ? 'Sesuai standar toleransi.' : payload.defectNotes
            }])
            .select()
            .single();

        if (error) throw error;
        showNotification(`[SUCCESS] Hasil QC berhasil dicatat: ${resultStatus}`, isPass ? 'success' : 'warning');
    } catch (err) {
        console.error('[QC_ERROR]', err);
        showNotification('[ERROR] Gagal menyimpan log inspeksi QC.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA LEMBAR UJI QC

```html
<div class="qc-card">
    <div class="card-header">
        <h3>Lembar Hasil Inspeksi Mutu (Quality Inspection Sheet)</h3>
        <span class="badge badge-info">[BATCH: LOT-2026-B81]</span>
    </div>
    <div class="qc-metrics">
        <p><strong>Parameter Uji:</strong> Ketebalan Rangka Kayu</p>
        <p><strong>Batas Toleransi:</strong> 24.50 mm s.d. 25.50 mm</p>
        <p><strong>Hasil Pengukuran Aktual:</strong> 25.10 mm</p>
        <div class="verdict-box">
            <span class="badge badge-success">[STATUS: LOLOS UJI / PASS]</span>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Karantina Otomatis:** Nilai pengukuran di luar batas toleransi otomatis menetapkan status `[FAIL]` dan mengisolasi stok.
- [ ] **Audit Lot Batch:** Setiap riwayat pengujian terikat pada nomor lot/batch produksi untuk penelusuran balik (*traceability*).
- [ ] **Strict No-Emoji:** Status inspeksi dan kriteria lolos uji bebas emoji.