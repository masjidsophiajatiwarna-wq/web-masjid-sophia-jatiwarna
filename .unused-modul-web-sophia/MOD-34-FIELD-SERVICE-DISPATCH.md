# SPESIFIKASI MODUL: FIELD SERVICE & ONSITE TECHNICIAN DISPATCH
> Kode Modul: `MOD-34` | Versi: `1.0.0` | Kategori: `Layanan & Kolaborasi (REC-17)` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-34-FIELD-SERVICE-DISPATCH` |
| **Nama Modul** | Field Service, Onsite Technician Dispatch & Proof of Work Engine |
| **Kategori** | Field Operations, Mobile Service & Onsite Work Orders |
| **Level Akses Publik** | Field Technician Mobile / Dispatcher Coordinator (`authenticated`) |
| **Tingkat Decoupling** | High (Menangani penugasan servis lapangan dari tiket MOD-16 atau MOD-10) |
| **Integrasi Pilar** | Supabase (Geolokasi GPS & Work Order Lifecycle), ImageKit (Foto Bukti Kerja & Tanda Tangan Canvas) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola penugasan teknisi lapangan ke lokasi pelanggan (instalasi internet/CCTV, servis AC/mesin, reparasi panggilan, kurir logistik khusus) melalui aplikasi web mobile responsif, panduan rute GPS alamat, pencatatan suku cadang yang terpakai di lapangan, foto bukti sebelum/sesudah pengerjaan (*Before/After Photo Proof*), dan tanda tangan digital pelanggan di layar tablet/HP (*Digital E-Sign On-Site*).

### Fitur Utama:
1. **Penugasan Teknisi & Penjadwalan Rute:** Alokasi teknisi terdekat berdasarkan zona wilayah.
2. **Mobile-First Technician Interface:** Tombol aksi sederhana (`MENUJU_LOKASI`, `MULAI_KERJA`, `SELESAI`).
3. **Pencatatan Material Terpakai (Spare Parts):** Potong stok otomatis dari gudang mobil teknisi di MOD-09.
4. **Tanda Tangan Digital Pelanggan (Canvas E-Signature):** Pengesahan Berita Acara Serah Terima (BAST) digital di lokasi.

---

## 3. DIAGRAM ALUR LAYANAN LAPANGAN (FIELD SERVICE LIFECYCLE)

```text
[KOORDINATOR DISPATCHER]
     |
     v (1. Buat Work Order Lapangan: FSO-2026-008 -> Tugaskan ke Teknisi Joko)
[Teknisi Lapangan (Mobile Web App)]
     |-- Klik "Menuju Lokasi" (Navigasi Google Maps)
     |
     v (2. Tiba di Lokasi Pelanggan)
[Foto Kondisi Kerusakan (Before Photo)]
     |-- Lakukan Perbaikan & Input Suku Cadang Terpakai
     |-- Foto Hasil Perbaikan (After Photo)
     |
     v (3. Penyelesaian & Pengesahan Pelanggan)
[Pelanggan Menandatangani di Layar HP (Canvas E-Sign)]
     |-- Simpan Gambar TTD ke ImageKit CDN
     |-- Status Order: "COMPLETED"
     |
     v (4. Auto Receipt ke Email Pelanggan via Resend)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL PERINTAH KERJA LAPANGAN (FIELD SERVICE ORDERS)
CREATE TABLE IF NOT EXISTS public.field_service_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number VARCHAR(60) UNIQUE NOT NULL, -- Format: FSO-YYYYMMDD-XXXX
    customer_name VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(30) NOT NULL,
    service_address TEXT NOT NULL,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    technician_id UUID REFERENCES public.employees(id),
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    issue_reported TEXT NOT NULL,
    work_performed_notes TEXT,
    photo_before_url TEXT,
    photo_after_url TEXT,
    customer_signature_url TEXT, -- URL TTD ImageKit
    status VARCHAR(30) DEFAULT 'ASSIGNED', -- 'ASSIGNED', 'ON_THE_WAY', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_fso_tech ON public.field_service_orders (technician_id, scheduled_time);
CREATE INDEX IF NOT EXISTS idx_fso_status ON public.field_service_orders (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.field_service_orders ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public field service access" ON public.field_service_orders FOR ALL TO anon USING (false);

-- 2. Teknisi hanya bisa melihat dan mengupdate tugas miliknya
CREATE POLICY "Technician manage own field orders" 
ON public.field_service_orders 
FOR ALL 
TO authenticated 
USING (
    technician_id IN (SELECT id FROM public.employees WHERE user_id = auth.uid()) OR
    auth.jwt() ->> 'role' = 'service_role' OR
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'DISPATCHER')
);
```

---

## 6. LOGIKA KLIEN: CANVAS SIGNATURE CAPTURER (JAVASCRIPT)

```javascript
/**
 * MOD-34: Capture Onsite Customer E-Signature
 */
function getCanvasSignatureData(canvasId) {
    const canvas = document.getElementById(canvasId);
    return canvas.toDataURL('image/png'); // Base64 signature
}

async function completeFieldOrder(orderId, signatureBase64, workNotes) {
    try {
        const { error } = await supabaseClient
            .from('field_service_orders')
            .update({
                status: 'COMPLETED',
                work_performed_notes: workNotes,
                customer_signature_url: signatureBase64,
                completed_at: new Date().toISOString()
            })
            .eq('id', orderId);

        if (error) throw error;
        showNotification('[SUCCESS] Servis lapangan selesai & BAST digital berhasil ditandatangani.', 'success');
    } catch (err) {
        console.error('[FIELD_ERROR]', err);
        showNotification('[ERROR] Gagal menyelesaikan penugasan lapangan.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA TEKNISI LAPANGAN (MOBILE VIEW)

```html
<div class="field-mobile-card">
    <div class="top-status">
        <span class="badge badge-warning">[STATUS: IN PROGRESS]</span>
        <h3>Perbaikan Kompresor AC - Gedung B</h3>
    </div>
    <div class="address-box">
        <p><strong>Alamat Klien:</strong> Jl. Gatot Subroto No. 42, Jakarta Selatan</p>
        <a href="https://maps.google.com" target="_blank" class="btn btn-sm btn-secondary">Buka Google Maps</a>
    </div>
    <div class="signature-section">
        <label>Tanda Tangan Pengesahan Pelanggan:</label>
        <canvas id="customer-sig-canvas" width="300" height="150" class="sig-box"></canvas>
        <button type="button" class="btn btn-success btn-block" onclick="completeFieldOrder('uuid-1')">Konfirmasi & Selesai</button>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kelancaran E-Signature Mobile:** Canvas tanda tangan responsif terhadap sentuhan jari di layar HP tanpa delay.
- [ ] **Upload Bukti Kerja:** Foto sebelum dan sesudah tersimpan aman di CDN.
- [ ] **Strict No-Emoji:** Status penugasan teknisi dan BAST digital bebas emoji.