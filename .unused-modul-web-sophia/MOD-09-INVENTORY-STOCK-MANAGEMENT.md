# SPESIFIKASI MODUL: MULTI-WAREHOUSE INVENTORY & STOCK MANAGEMENT
> Kode Modul: `MOD-09` | Versi: `1.0.0` | Kategori: `Operations & Logistics (Odoo-Grade Suite)` | Dependensi: `Supabase`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-09-INVENTORY-STOCK-MANAGEMENT` |
| **Nama Modul** | Multi-Warehouse Inventory & Stock Movement Management |
| **Kategori** | Supply Chain, Warehouse & Inventory Control |
| **Level Akses Publik** | Restricted (Khusus Tim Gudang / Admin `authenticated`) |
| **Tingkat Decoupling** | High (Menyediakan sinkronisasi stok master untuk MOD-06) |
| **Integrasi Pilar** | Supabase (PostgreSQL Atomic Double-Entry Stock Ledger) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola ketersediaan stok fisik barang di berbagai lokasi gudang (*multi-warehouse / multi-branch*), melacak mutasi stok masuk (*incoming shipment*), mutasi keluar (*sales delivery*), transfer antar-gudang, dan penyesuaian stok opname (*stock adjustment*) dengan sistem pencatatan mutasi ganda yang tidak dapat diubah (*immutable audit log*).

### Fitur Utama:
1. **Multi-Warehouse Support:** Manajemen stok per gudang (Gudang Pusat, Toko Cabang A, Gudang Transit).
2. **Peringatan Minimum Stok (Low Stock Alert):** Peringatan otomatis jika kuantitas barang mendekati titik *reorder point*.
3. **Pencatatan Mutasi Ganda (Double-Entry Ledger):** Setiap pergerakan stok dicatat dengan referensi jelas (PO, SO, Adjustment, Transfer).
4. **Stok Opname & Adjustment Tool:** Form penyesuaian selisih stok fisik vs sistem dengan pencatatan alasan audit.

---

## 3. DIAGRAM ALUR PERGERAKAN STOK (STOCK MOVEMENT)

```text
[SUMBER MUTASI]
   |-- Penerimaan Barang dari Supplier (IN)
   |-- Pengiriman Pesanan Pelanggan MOD-06 (OUT)
   |-- Transfer Antar-Gudang (INTERNAL TRANSFER)
   |-- Penyesuaian Selisih Opname (ADJUSTMENT)
   |
   v
[PostgreSQL Atomic Trigger: log_stock_movement]
   |-- 1. Catat ke tabel public.stock_movements (Immutable Log)
   |-- 2. Update saldo stok di tabel public.warehouse_stock
   |-- 3. Hitung ulang total stok produk di tabel public.products
   |
   v
[Evaluasi Minimum Stock]
   |-- Jika stok < reorder_point -> Kirim notifikasi [WARNING: LOW STOCK]
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL LOKASI GUDANG (WAREHOUSES)
CREATE TABLE IF NOT EXISTS public.warehouses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL, -- Contoh: 'GDG-PUSAT', 'CAB-JAKSEL'
    name VARCHAR(150) NOT NULL,
    address TEXT,
    manager_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL SALDO STOK PER GUDANG
CREATE TABLE IF NOT EXISTS public.warehouse_stock (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    warehouse_id UUID NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity_on_hand INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0, -- Stok yang sedang dalam pesanan aktif
    reorder_point INT DEFAULT 10,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(warehouse_id, product_id)
);

-- TABEL MUTASI STOK (IMMUTABLE STOCK MOVEMENTS)
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    movement_number VARCHAR(60) UNIQUE NOT NULL, -- Format: MOV-YYYYMMDD-XXXX
    product_id UUID NOT NULL REFERENCES public.products(id),
    from_warehouse_id UUID REFERENCES public.warehouses(id), -- NULL jika barang masuk dari luar
    to_warehouse_id UUID REFERENCES public.warehouses(id),   -- NULL jika barang keluar ke konsumen
    movement_type VARCHAR(50) NOT NULL, -- 'INCOMING', 'OUTGOING', 'TRANSFER', 'ADJUSTMENT'
    quantity INT NOT NULL,
    reference_document VARCHAR(100), -- No PO, No Order ORD-xxx, atau No Opname
    notes TEXT,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_stock_prod_wh ON public.warehouse_stock (warehouse_id, product_id);
CREATE INDEX IF NOT EXISTS idx_movements_prod ON public.stock_movements (product_id);
CREATE INDEX IF NOT EXISTS idx_movements_created ON public.stock_movements (created_at DESC);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

-- 1. Publik dilarang mengakses data inventori
CREATE POLICY "Deny public inventory access" 
ON public.warehouse_stock 
FOR ALL 
TO anon 
USING (false);

-- 2. Staff Gudang & Admin memiliki akses kelola
CREATE POLICY "Allow warehouse staff manage stock" 
ON public.warehouse_stock 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);

-- 3. Tabel log pergerakan stok bersifat APPEND ONLY (Dilarang UPDATE / DELETE)
CREATE POLICY "Allow staff append stock movements" 
ON public.stock_movements 
FOR INSERT 
TO authenticated 
WITH CHECK (true);

CREATE POLICY "Allow staff read stock movements" 
ON public.stock_movements 
FOR SELECT 
TO authenticated 
USING (true);
```

---

## 6. LOGIKA KLIEN: MUTASI STOK ATOMIK (JAVASCRIPT)

```javascript
/**
 * MOD-09: Stock Adjustment & Transfer Dispatcher
 */
async function recordStockMovement(payload) {
    const now = new Date();
    const movementNumber = `MOV-${now.getFullYear()}${String(now.getMonth()+1).padStart(2,'0')}${String(now.getDate()).padStart(2,'0')}-${Math.floor(1000 + Math.random() * 9000)}`;

    try {
        const { data, error } = await supabaseClient
            .from('stock_movements')
            .insert([{
                movement_number: movementNumber,
                product_id: payload.productId,
                from_warehouse_id: payload.fromWarehouseId || null,
                to_warehouse_id: payload.toWarehouseId || null,
                movement_type: payload.movementType,
                quantity: payload.quantity,
                reference_document: payload.referenceDoc,
                notes: payload.notes
            }])
            .select()
            .single();

        if (error) throw error;
        showNotification(`[SUCCESS] Mutasi stok ${movementNumber} berhasil dicatat.`, 'success');
        refreshStockTable();
    } catch (err) {
        console.error('[STOCK_ERROR]', err);
        showNotification('[ERROR] Gagal memproses mutasi stok.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA TABEL STOK GUDANG

```html
<div class="inventory-table-container">
    <div class="table-actions">
        <h3 class="section-title">Monitoring Stok Real-Time</h3>
        <button type="button" class="btn btn-primary" onclick="openStockAdjustmentModal()">+ Catat Mutasi Baru</button>
    </div>

    <table class="data-table">
        <thead>
            <tr>
                <th>SKU</th>
                <th>Nama Produk</th>
                <th>Gudang</th>
                <th>Stok Fisik</th>
                <th>Alokasi Pesanan</th>
                <th>Status Ketersediaan</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><code>PRD-001</code></td>
                <td>Paket Bundling Premium</td>
                <td>Gudang Pusat</td>
                <td>145 Unit</td>
                <td>12 Unit</td>
                <td><span class="badge badge-success">[AMAN]</span></td>
            </tr>
            <tr>
                <td><code>PRD-002</code></td>
                <td>Koleksi Edisi Terbatas</td>
                <td>Cabang Jakarta</td>
                <td>4 Unit</td>
                <td>2 Unit</td>
                <td><span class="badge badge-danger">[PERINGATAN: LOW STOCK]</span></td>
            </tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Integritas Log:** Data riwayat mutasi di tabel `stock_movements` tidak dapat diedit atau dihapus oleh siapapun.
- [ ] **Kalkulasi Selisih:** Pergerakan transfer otomatis mengurangi gudang asal dan menambah gudang tujuan secara atomik.
- [ ] **Peringatan Minimum:** Produk dengan stok < titik reorder memunculkan indikator status `[PERINGATAN: LOW STOCK]`.
- [ ] **Strict No-Emoji:** Notifikasi audit dan status inventori menggunakan label teks formal.