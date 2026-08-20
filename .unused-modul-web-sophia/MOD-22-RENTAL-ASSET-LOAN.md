# SPESIFIKASI MODUL: RENTAL & ASSET LOAN MANAGEMENT
> Kode Modul: `MOD-22` | Versi: `1.0.0` | Kategori: `Sales & POS Suite (Rental / REC-05)` | Dependensi: `Supabase, MOD-02, MOD-07`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-22-RENTAL-ASSET-LOAN` |
| **Nama Modul** | Rental, Equipment Leasing & Asset Loan Engine |
| **Kategori** | Asset Rental & Equipment Loan Management |
| **Level Akses Publik** | Customer View (Katalog Sewa) / Rental Officer (Admin) |
| **Tingkat Decoupling** | High (Menangani jadwal booking sewa, deposit jaminan, dan pengembalian unit) |
| **Integrasi Pilar** | Supabase (Rental Timeline Matrix), Resend (Overdue Return Reminders) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola model bisnis penyewaan barang, alat berat/kamera/peralatan pesta, rental mobil/kendaraan, atau peminjaman inventaris internal dengan pemantauan jadwal sewa (*Rental Gantt Timeline*), pengelolaan uang deposit jaminan (*security deposit*), pemeriksaan kondisi barang sebelum/sesudah sewa (*inspection checklist*), dan kalkulasi otomatis denda keterlambatan (*late return fees*).

### Fitur Utama:
1. **Visual Rental Timeline:** Matriks ketersediaan unit barang per tanggal sewa.
2. **Kalkulasi Biaya Durasi Sewa:** Tarif per jam, per hari, atau per minggu dengan perhitungan otomatis.
3. **Manajemen Deposit Jaminan:** Pencatatan uang deposit dan pengembalian (*refund*) setelah inspeksi unit selesai.
4. **Pemeriksaan Kondisi Barang (Inspection Log):** Upload foto kondisi sebelum diambil dan saat dikembalikan.

---

## 3. DIAGRAM ALUR SIKLUS PENYEWAAN BARANG

```text
[PENYEWA / KLIEN]
     |
     v (1. Pilih Unit Barang & Tanggal Sewa: 20-22 Agustus 2026)
[Pengecekan Ketersediaan Jadwal]
     |-- Validasi Konflik Booking: WHERE unit_id = X AND date_range OVERLAPS
     |
     v (2. Pembayaran Biaya Sewa + Deposit Jaminan)
[Supabase: public.rental_contracts]
     |-- Simpan Kontrak Sewa (Status: RESERVED)
     |
     v (3. Pengambilan Unit (Pickup))
[Inspeksi Awal (Inspection Out)]
     |-- Rekam checklist fisik & foto unit -> Status: ACTIVE_RENTAL
     |
     v (4. Pengembalian Unit (Return))
[Inspeksi Akhir (Inspection In)]
     |-- Cek Tepat Waktu / Terlambat -> Hitung Denda jika ada
     |-- Kondisi Baik -> Refund Deposit Jaminan -> Status: RETURNED_COMPLETED
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL UNIT BARANG SEWA (RENTAL ASSETS)
CREATE TABLE IF NOT EXISTS public.rental_assets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    asset_code VARCHAR(60) UNIQUE NOT NULL, -- Contoh: 'CAM-SONY-A7IV-01'
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    daily_rate NUMERIC(15, 2) NOT NULL,
    deposit_required NUMERIC(15, 2) DEFAULT 0.00,
    late_fee_per_day NUMERIC(15, 2) DEFAULT 50000.00,
    status VARCHAR(30) DEFAULT 'AVAILABLE', -- 'AVAILABLE', 'RENTED', 'MAINTENANCE', 'RETIRED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL KONTRAK SEWA (RENTAL CONTRACTS)
CREATE TABLE IF NOT EXISTS public.rental_contracts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    contract_number VARCHAR(60) UNIQUE NOT NULL, -- Format: RNT-YYYYMMDD-XXXX
    asset_id UUID NOT NULL REFERENCES public.rental_assets(id),
    customer_name VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(30) NOT NULL,
    customer_id_card_number VARCHAR(50) NOT NULL, -- No KTP/SIM
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    expected_return_date TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_return_date TIMESTAMP WITH TIME ZONE,
    rental_fee NUMERIC(15, 2) NOT NULL,
    deposit_amount NUMERIC(15, 2) NOT NULL,
    late_fee_charged NUMERIC(15, 2) DEFAULT 0.00,
    status VARCHAR(30) DEFAULT 'RESERVED', -- 'RESERVED', 'ACTIVE', 'OVERDUE', 'RETURNED', 'CANCELLED'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_rental_asset_dates ON public.rental_contracts (asset_id, start_date, expected_return_date);
CREATE INDEX IF NOT EXISTS idx_rental_status ON public.rental_contracts (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.rental_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_contracts ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh melihat aset sewa yang berstatus AVAILABLE
CREATE POLICY "Allow public view available rental assets" 
ON public.rental_assets 
FOR SELECT 
TO anon, authenticated 
USING (status = 'AVAILABLE');

-- 2. Staf Rental memiliki kontrol penuh
CREATE POLICY "Allow rental staff manage contracts" 
ON public.rental_contracts 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: KALKULASI BIAYA & DENDA (JAVASCRIPT)

```javascript
/**
 * MOD-22: Rental Fee & Overdue Calculator
 */
function calculateRentalCosts(dailyRate, deposit, startDate, returnDate) {
    const start = new Date(startDate);
    const end = new Date(returnDate);
    const diffTime = Math.abs(end - start);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) || 1;

    const totalRentalFee = diffDays * dailyRate;
    const grandTotalInitial = totalRentalFee + deposit;

    return {
        durationDays: diffDays,
        rentalFee: totalRentalFee,
        depositRequired: deposit,
        totalInitial: grandTotalInitial
    };
}
```

---

## 7. SPESIFIKASI ANTARMUKA TIMELINE JADWAL SEWA

```html
<div class="rental-dashboard">
    <div class="header">
        <h3>Matriks Ketersediaan Unit Sewa</h3>
        <button type="button" class="btn btn-primary" onclick="openNewRentalModal()">+ Buat Kontrak Sewa Baru</button>
    </div>
    <div class="timeline-wrapper">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Kode Unit</th>
                    <th>Nama Barang</th>
                    <th>Status Saat Ini</th>
                    <th>Jadwal Sewa Berjalan</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><code>CAM-SONY-01</code></td>
                    <td>Sony Alpha A7 IV Kit Lens</td>
                    <td><span class="badge badge-warning">[SEDANG DISEWA]</span></td>
                    <td>19 Ags - 22 Ags 2026 (Penyewa: Reza Pratama)</td>
                    <td><button type="button" class="btn btn-sm" onclick="processReturn('uuid-1')">Proses Kembali</button></td>
                </tr>
            </tbody>
        </table>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Pencegahan Double-Booking:** Unit barang tidak dapat disewa oleh 2 penyewa pada rentang tanggal yang saling tumpang tindih.
- [ ] **Kalkulasi Denda Otomatis:** Keterlambatan pengembalian unit otomatis mengkalkulasi denda harian secara presisi.
- [ ] **Pencatatan Deposit:** Alur pengembalian uang deposit terekam jelas dalam histori kontrak.
- [ ] **Strict No-Emoji:** Status sewa dan label denda bebas emoji.