# SPESIFIKASI MODUL: FLEET & VEHICLE OPERATIONS MANAGEMENT
> Kode Modul: `MOD-32` | Versi: `1.0.0` | Kategori: `HR & People Operations (Logistics / REC-15)` | Dependensi: `Supabase, MOD-19, MOD-26`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-32-FLEET-VEHICLE-OPERATIONS` |
| **Nama Modul** | Fleet, Vehicle Logistics & Fuel Operations Engine |
| **Kategori** | Fleet Management, Logistics Dispatch & Vehicle Maintenance |
| **Level Akses Publik** | Driver / Logistics Dispatcher / Fleet Manager (`authenticated`) |
| **Tingkat Decoupling** | High (Menangani armada kurir pengiriman MOD-06 & operasional internal) |
| **Integrasi Pilar** | Supabase (Odometer Log & Vehicle Service Lifecycle) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola armada kendaraan operasional perusahaan (mobil dinas, motor kurir pengiriman, truk logistik) melalui pencatatan kilometer (*Odometer / Mileage Tracking*), pengisian bahan bakar minyak (BBM), jadwal uji KIR / STNK tahunan, asuransi kendaraan, dan riwayat penugasan pengemudi (*driver assignment*).

### Fitur Utama:
1. **Master Data Kendaraan:** Nomor Plat Polisi, Nomor Rangka/Mesin, Merk/Tipe, Masa Berlaku Pajak STNK.
2. **Log Pengisian BBM & Odometer:** Perhitungan rasio konsumsi bahan bakar (Km/Liter).
3. **Peringatan Masa Berlaku Dokumen Kendaraan:** Alert H-30 sebelum jatuh tempo STNK/KIR/Asuransi.
4. **Log Penugasan Pengemudi (Driver Log):** Riwayat perjalanan dinas dan pengiriman logistik.

---

## 3. DIAGRAM ALUR LOGISTIK ARMADA KENDARAAN

```text
[PENGEMUDI / DRIVER (driver-portal.html)]
     |
     v (1. Catat Kilometer Awal & Isi Bensin: Rp 150.000)
[Supabase: public.fleet_fuel_logs]
     |-- Simpan Foto Odometer & Struk SPBU (MOD-19)
     |
     v (2. Menjalankan Rute Pengiriman Logistik (MOD-06 / MOD-34))
[Selesai Pengantaran]
     |-- Catat Kilometer Akhir
     |-- Hitung Efisiensi Konsumsi BBM (Km/Liter)
     |
     v (3. Monitoring Fleet Manager)
[Dashboard Armada: Pemantauan Servis Rutin & Jadwal STNK]
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL ARMADA KENDARAAN (FLEET VEHICLES)
CREATE TABLE IF NOT EXISTS public.fleet_vehicles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    license_plate VARCHAR(20) UNIQUE NOT NULL, -- Contoh: 'B 1234 XYZ'
    vehicle_model VARCHAR(100) NOT NULL, -- Contoh: 'Toyota Avanza 1.5 G'
    vehicle_type VARCHAR(50) DEFAULT 'CAR', -- 'MOTORCYCLE', 'CAR', 'VAN', 'TRUCK'
    assigned_driver_id UUID REFERENCES public.employees(id),
    current_odometer_km INT NOT NULL DEFAULT 0,
    stnk_expiry_date DATE NOT NULL,
    kir_expiry_date DATE,
    insurance_policy_number VARCHAR(100),
    status VARCHAR(30) DEFAULT 'ACTIVE', -- 'ACTIVE', 'IN_SERVICE', 'REPAIRED', 'RETIRED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL LOG BBM & JARAK TEMPUH (FUEL & ODOMETER LOGS)
CREATE TABLE IF NOT EXISTS public.fleet_fuel_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vehicle_id UUID NOT NULL REFERENCES public.fleet_vehicles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES public.employees(id),
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    odometer_km INT NOT NULL,
    fuel_liters NUMERIC(8, 2) NOT NULL,
    total_cost NUMERIC(15, 2) NOT NULL,
    receipt_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_fleet_plate ON public.fleet_vehicles (license_plate);
CREATE INDEX IF NOT EXISTS idx_fleet_stnk ON public.fleet_vehicles (stnk_expiry_date);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.fleet_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_fuel_logs ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public fleet access" ON public.fleet_vehicles FOR ALL TO anon USING (false);

-- 2. Driver & Fleet Manager memiliki izin kelola
CREATE POLICY "Allow fleet staff manage vehicles" 
ON public.fleet_vehicles 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: FUEL CONSUMPTION CALCULATOR (JAVASCRIPT)

```javascript
/**
 * MOD-32: Calculate Fuel Efficiency (Km/L)
 */
function calculateFuelEfficiency(startKm, endKm, fuelLiters) {
    const distanceTraveled = endKm - startKm;
    if (distanceTraveled <= 0 || fuelLiters <= 0) return 0;
    return (distanceTraveled / fuelLiters).toFixed(2); // Hasil: Km/Liter
}
```

---

## 7. SPESIFIKASI ANTARMUKA MONITORING KENDARAAN

```html
<div class="fleet-card">
    <div class="header">
        <h3>Pusat Operasional Armada Kendaraan</h3>
    </div>
    <table class="data-table">
        <thead>
            <tr><th>No. Plat</th><th>Tipe Unit</th><th>Pengemudi</th><th>Odometer</th><th>Jatuh Tempo Pajak STNK</th><th>Status</th></tr>
        </thead>
        <tbody>
            <tr>
                <td><code>B 1824 SJA</code></td>
                <td>Blind Van Pengiriman</td>
                <td>Mulyono (Kurir)</td>
                <td>48.210 Km</td>
                <td>15 Oktober 2026</td>
                <td><span class="badge badge-success">[OPERASIONAL]</span></td>
            </tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Validasi Odometer:** Odometer baru tidak boleh bernilai lebih kecil dari nilai log terakhir.
- [ ] **Peringatan Pajak STNK:** Notifikasi otomatis terkirim jika STNK mendekati batas jatuh tempo.
- [ ] **Strict No-Emoji:** Status operasional armada dan log BBM bebas emoji.