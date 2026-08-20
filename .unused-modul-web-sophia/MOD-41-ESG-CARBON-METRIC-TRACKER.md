# SPESIFIKASI MODUL: ESG SUSTAINABILITY & CARBON METRIC TRACKER
> Kode Modul: `MOD-41` | Versi: `1.0.0` | Kategori: `Produktivitas & Dokumen (REC-24)` | Dependensi: `Supabase`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-41-ESG-CARBON-METRIC-TRACKER` |
| **Nama Modul** | ESG Sustainability, Carbon Footprint & Energy Metric Tracker |
| **Kategori** | Environmental, Social & Governance (ESG) Compliance |
| **Level Akses Publik** | Restricted (Sustainability Officer & Executive `authenticated`) |
| **Tingkat Decoupling** | High (Menghitung emisi dari MOD-32 Armada & konsumsi listrik fasilitas) |
| **Integrasi Pilar** | Supabase (Carbon Emission Conversion Factors & Compliance Ledger) |

---

## 2. TUJUAN BISNIS & USE CASE

Membantu perusahaan mematuhi regulasi keberlanjutan lingkungan dan pelaporan emisi karbon (*ESG Compliance Reporting*) melalui pencatatan emisi Scope 1 (BBM armada kendaraan MOD-32), Scope 2 (Konsumsi listrik PLN fasilitas/gudang), dan Scope 3 (Limbah/Kertas), kalkulasi otomatis ekuivalen CO2 (*kgCO2e Conversion Factors*), dan ekspor laporan keberlanjutan tahunan.

### Fitur Utama:
1. **Pencatatan Emisi Scope 1, 2, 3:** Pembagian kategori sesuai protokol GHG (*Greenhouse Gas Protocol*).
2. **Kalkulator Emisi Terstandarisasi:** Konversi liter BBM bensin/solar dan kWh listrik ke metrik ton CO2e.
3. **Pencatatan Inisiatif Pengurangan Emisi (Carbon Offsets):** Proyek penanaman pohon, penggunaan panel surya.
4. **Ekspor Laporan Kepatuhan ESG:** Laporan tahunan siap audit untuk pemangku kepentingan (*stakeholders*).

---

## 3. DIAGRAM ALUR PELACAKAN EMISI KARBON (ESG WORKFLOW)

```text
[SUMBER KONSUMSI OPERASIONAL]
   |-- Scope 1: Liter BBM Kendaraan MOD-32 (Faktor: 2.31 kgCO2e/Liter Bensin)
   |-- Scope 2: Tagihan Listrik kWh Fasilitas (Faktor: 0.85 kgCO2e/kWh)
   |
   v
[PostgreSQL ESG Calculation Engine (Supabase RPC)]
   |-- Hitung Total Emisi = (Qty * Faktor Konversi)
   |-- Simpan ke public.esg_carbon_logs
   |
   v
[Dashboard Keberlanjutan Lingkungan]
   |-- Total Jejak Karbon Tahun Berjalan: 14.8 Ton CO2e
   |-- Grafik Tren Penghematan Energi Per Bulan
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL FAKTOR KONVERSI EMISI (EMISSION FACTORS)
CREATE TABLE IF NOT EXISTS public.esg_emission_factors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_category VARCHAR(100) NOT NULL, -- 'ELECTRICITY_GRID', 'GASOLINE', 'DIESEL', 'WATER_CONSUMPTION'
    scope_level VARCHAR(20) NOT NULL, -- 'SCOPE_1', 'SCOPE_2', 'SCOPE_3'
    unit_name VARCHAR(30) NOT NULL, -- 'kWh', 'Liter', 'm3'
    co2e_kg_per_unit NUMERIC(10, 4) NOT NULL, -- Contoh: 0.8500 untuk listrik
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL LOG PENCATATAN EMISI (CARBON LOGS)
CREATE TABLE IF NOT EXISTS public.esg_carbon_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    factor_id UUID NOT NULL REFERENCES public.esg_emission_factors(id),
    activity_period DATE NOT NULL,
    consumed_quantity NUMERIC(12, 2) NOT NULL,
    total_co2e_kg NUMERIC(15, 2) NOT NULL,
    facility_location VARCHAR(150),
    notes TEXT,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_esg_period ON public.esg_carbon_logs (activity_period DESC);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.esg_emission_factors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.esg_carbon_logs ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public ESG access" ON public.esg_carbon_logs FOR ALL TO anon USING (false);

-- 2. Staff Sustainability memiliki izin kelola
CREATE POLICY "Allow sustainability staff manage ESG" 
ON public.esg_carbon_logs 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: LOG CARBON EMISSION (JAVASCRIPT)

```javascript
/**
 * MOD-41: Record Emission Activity
 */
async function logCarbonActivity(factorId, co2ePerUnit, quantity, facility) {
    const totalCO2 = (quantity * co2ePerUnit).toFixed(2);

    try {
        const { error } = await supabaseClient
            .from('esg_carbon_logs')
            .insert([{
                factor_id: factorId,
                activity_period: new Date().toISOString().slice(0, 10),
                consumed_quantity: quantity,
                total_co2e_kg: parseFloat(totalCO2),
                facility_location: facility
            }]);

        if (error) throw error;
        showNotification(`[SUCCESS] Aktivitas tercatat: ${totalCO2} kg CO2e.`, 'success');
    } catch (err) {
        console.error('[ESG_ERROR]', err);
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA DASHBOARD EMISI

```html
<div class="esg-card">
    <div class="header">
        <h3>Laporan Jejak Karbon & Keberlanjutan (ESG Metrics)</h3>
        <span class="badge badge-success">[STATUS: TARGET NET-ZERO 2030]</span>
    </div>
    <div class="metrics-grid">
        <div class="box">
            <h4>Total Emisi Tahun 2026</h4>
            <h2>14.2 Ton CO2e</h2>
            <small>Scope 1: 35% | Scope 2: 65%</small>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Akurasi Konversi Faktor:** Perhitungan total kgCO2e tepat mengalikan kuantitas dengan koefisien faktor emisi.
- [ ] **Kepatuhan Protokol GHG:** Pengelompokan Scope 1, 2, dan 3 terpisah secara transparan.
- [ ] **Strict No-Emoji:** Status metrik keberlanjutan dan label laporan bebas emoji.