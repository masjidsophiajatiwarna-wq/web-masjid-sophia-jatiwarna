# SPESIFIKASI MODUL: MANUFACTURING, BILL OF MATERIALS (BOM) & WORK ORDERS (MRP)
> Kode Modul: `MOD-24` | Versi: `1.0.0` | Kategori: `Supply Chain & Manufaktur (REC-07)` | Dependensi: `Supabase, MOD-09, MOD-18`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-24-MANUFACTURING-BOM-MRP` |
| **Nama Modul** | Manufacturing, Bill of Materials (BOM) & Work Orders (MRP) |
| **Kategori** | Production Planning & Material Requirements Planning |
| **Level Akses Publik** | Production Manager & Plant Operator (`authenticated`) |
| **Tingkat Decoupling** | High (Mengonsumsi bahan baku dari MOD-09 dan menghasilkan produk jadi ke MOD-06) |
| **Integrasi Pilar** | Supabase (PostgreSQL BOM Recursive Tree & Work Order State Machine) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola proses transformasi bahan baku (*raw materials*) menjadi produk jadi (*finished goods*) melalui struktur formula resep (*Bill of Materials - BOM Multi-Level*), perencanaan kebutuhan bahan (*MRP*), penerbitan Surat Perintah Kerja (*Manufacturing Order / Work Order*), pelacakan tahapan perakitan (*Work Center Stages*), dan kalkulasi akurat Harga Pokok Produksi (*HPP / Cost of Goods Manufactured*).

### Fitur Utama:
1. **Multi-Level Bill of Materials (BOM):** Struktur hierarki komponen bahan baku, scrap rate (persentase sisa limbah), dan biaya tenaga kerja.
2. **Manufacturing Order (MO) Lifecycle:** Alur status produksi (`DRAFT`, `CONFIRMED`, `IN_PRODUCTION`, `COMPLETED`, `CANCELLED`).
3. **Atomic Inventory Unbundling & Bundling:** Pemotongan stok bahan mentah secara otomatis dan penambahan stok produk jadi secara serentak.
4. **Kalkulasi Biaya HPP Nyata:** Menghitung total biaya bahan mentah + overhead operasional per unit produk jadi.

---

## 3. DIAGRAM ALUR PROSES PRODUKSI MANUFAKTUR

```text
[RENCANA PRODUKSI / PESANAN CUSTOM]
     |
     v (1. Buat Manufacturing Order: 100 Unit Meja Kayu)
[BOM Explosion Engine]
     |-- Formula: 1 Meja = 4 Kaki Kayu + 1 Papan Atas + 16 Sekrup
     |-- Kebutuhan Total: 400 Kaki + 100 Papan + 1.600 Sekrup
     |-- Cek Stok di MOD-09: Jika Kurang -> Trigger RFQ ke MOD-23
     |
     v (2. Mulai Produksi di Lantai Pabrik)
[Work Center 1: Pemotongan -> Work Center 2: Perakitan -> Work Center 3: Finishing]
     |-- Potong Stok Bahan Baku dari Gudang (MOD-09 INVENTORY CONSUMPTION)
     |
     v (3. Selesai Produksi & QC)
[Penerimaan Produk Jadi (Finished Goods Ingestion)]
     |-- Tambah 100 Unit Meja Kayu ke Stok Gudang Barang Jadi (MOD-09)
     |-- Rekam Jurnal HPP Produksi ke MOD-18
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL FORMULA RESEP / BILL OF MATERIALS (BOM)
CREATE TABLE IF NOT EXISTS public.mrp_bom_headers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bom_code VARCHAR(60) UNIQUE NOT NULL, -- Contoh: 'BOM-MEJA-01'
    product_id UUID NOT NULL REFERENCES public.products(id), -- Produk Jadi
    quantity_produced INT NOT NULL DEFAULT 1,
    labor_cost_per_unit NUMERIC(15, 2) DEFAULT 0.00,
    overhead_cost_per_unit NUMERIC(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL RINCIAN KOMPONEN BAHAN BAKU BOM
CREATE TABLE IF NOT EXISTS public.mrp_bom_lines (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bom_id UUID NOT NULL REFERENCES public.mrp_bom_headers(id) ON DELETE CASCADE,
    component_product_id UUID NOT NULL REFERENCES public.products(id), -- Bahan Mentah
    quantity_required NUMERIC(10, 3) NOT NULL,
    scrap_percentage NUMERIC(5, 2) DEFAULT 0.00 -- Toleransi sisa material
);

-- TABEL PERINTAH PRODUKSI (MANUFACTURING ORDERS)
CREATE TABLE IF NOT EXISTS public.mrp_manufacturing_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    mo_number VARCHAR(60) UNIQUE NOT NULL, -- Format: MO-YYYYMMDD-XXXX
    bom_id UUID NOT NULL REFERENCES public.mrp_bom_headers(id),
    target_product_id UUID NOT NULL REFERENCES public.products(id),
    target_quantity INT NOT NULL,
    warehouse_raw_id UUID NOT NULL REFERENCES public.warehouses(id), -- Gudang Bahan Baku
    warehouse_finished_id UUID NOT NULL REFERENCES public.warehouses(id), -- Gudang Produk Jadi
    status VARCHAR(30) DEFAULT 'DRAFT', -- 'DRAFT', 'CONFIRMED', 'IN_PRODUCTION', 'COMPLETED', 'CANCELLED'
    total_material_cost NUMERIC(15, 2) DEFAULT 0.00,
    calculated_unit_hpp NUMERIC(15, 2) DEFAULT 0.00,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_bom_prod ON public.mrp_bom_headers (product_id);
CREATE INDEX IF NOT EXISTS idx_mo_status ON public.mrp_manufacturing_orders (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.mrp_bom_headers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mrp_bom_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mrp_manufacturing_orders ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public MRP access" ON public.mrp_manufacturing_orders FOR ALL TO anon USING (false);

-- 2. Tim Produksi memiliki izin kelola
CREATE POLICY "Allow production staff manage MRP" 
ON public.mrp_manufacturing_orders 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: MO EXECUTION ENGINE (JAVASCRIPT)

```javascript
/**
 * MOD-24: Manufacturing Order Execution
 */
async function completeManufacturingOrder(moId) {
    try {
        const { data, error } = await supabaseClient
            .rpc('process_mrp_completion', { p_mo_id: moId });

        if (error) throw error;
        showNotification('[SUCCESS] Perintah kerja selesai! Stok bahan mentah telah dikonsumsi & produk jadi telah ditambahkan.', 'success');
        refreshMODashboard();
    } catch (err) {
        console.error('[MRP_ERROR]', err);
        showNotification('[ERROR] Gagal menyelesaikan proses manufaktur. Cek ketersediaan bahan.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA BOM EXPLORER

```html
<div class="mrp-card">
    <div class="card-header">
        <h3>Struktur Komponen Produksi (Bill of Materials)</h3>
        <span class="badge badge-primary">[PRODUK JADI: KURSI ERGONOMIS]</span>
    </div>
    <table class="data-table">
        <thead>
            <tr><th>SKU Bahan</th><th>Nama Komponen</th><th>Kebutuhan per Unit</th><th>Biaya Satuan</th><th>Subtotal HPP</th></tr>
        </thead>
        <tbody>
            <tr><td><code>RAW-WOD-01</code></td><td>Rangka Kayu Mahoni</td><td>1 Unit</td><td>Rp 120.000</td><td>Rp 120.000</td></tr>
            <tr><td><code>RAW-FAB-02</code></td><td>Kain Busa Premium</td><td>0.8 Meter</td><td>Rp 50.000</td><td>Rp 40.000</td></tr>
            <tr><td><code>RAW-SCR-12</code></td><td>Baut Pengunci Baja</td><td>8 Pcs</td><td>Rp 1.000</td><td>Rp 8.000</td></tr>
            <tr class="total-row"><td colspan="4"><strong>ESTIMASI BIAYA MATERIAL (HPP/UNIT)</strong></td><td><strong>Rp 168.000</strong></td></tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kalkulasi Akurat HPP:** Total HPP per unit terkalkulasi tepat berdasarkan harga bahan mentah terkini.
- [ ] **Pencegahan Stok Minus:** Proses perakitan gagal dimulai jika salah satu komponen bahan baku memiliki saldo < kebutuhan.
- [ ] **Integritas Mutasi Ganda:** Pemotongan bahan baku dan penambahan produk jadi terjadi dalam 1 transaksi atomik.
- [ ] **Strict No-Emoji:** Status dokumen MO dan label BOM bebas emoji.