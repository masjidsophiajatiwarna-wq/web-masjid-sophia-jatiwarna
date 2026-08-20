# SPESIFIKASI MODUL: PURCHASE & VENDOR PROCUREMENT MANAGEMENT
> Kode Modul: `MOD-23` | Versi: `1.0.0` | Kategori: `Supply Chain & Manufaktur (REC-06)` | Dependensi: `Supabase, MOD-09, MOD-18`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-23-PURCHASE-VENDOR-PROCUREMENT` |
| **Nama Modul** | Purchase & Vendor Procurement Management |
| **Kategori** | Procurement, Supplier Relations & Goods Ingestion |
| **Level Akses Publik** | Procurement Officer & Purchasing Manager (`authenticated`) |
| **Tingkat Decoupling** | High (Menyuplai penerimaan barang ke MOD-09 dan tagihan utang ke MOD-18) |
| **Integrasi Pilar** | Supabase (Procurement State & 3-Way Matching Engine) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengotomatisasi alur pengadaan barang dari pemasok/vendor (*procurement lifecycle*), mulai dari Permintaan Penawaran (*Request for Quotation - RFQ*), penerbitan Surat Pesanan (*Purchase Order - PO*), pencatatan tanda terima barang di gudang (*Goods Receipt Note - GRN*), hingga verifikasi tagihan vendor (*Vendor Bill 3-Way Matching: PO vs GRN vs Bill*).

### Fitur Utama:
1. **RFQ & Vendor Comparison:** Membandingkan harga dan estimasi waktu kirim (*lead time*) antar-pemasok.
2. **Otorisasi Purchase Order (PO):** Persetujuan bertingkat untuk pembelian bernilai tinggi.
3. **Goods Receipt Ingestion:** Sinkronisasi langsung menambah saldo stok fisik di MOD-09 saat barang tiba di gudang.
4. **3-Way Matching:** Mencegah overpayment dengan memvalidasi kesesuaian kuantitas PO, barang diterima fisik, dan faktur vendor.

---

## 3. DIAGRAM ALUR PENGADAAN (PROCUREMENT PIPELINE)

```text
[TIM PENGADAAN / PURCHASING]
     |
     v (1. Buat Permintaan Penawaran: RFQ-2026-001 ke 3 Vendor)
[Pilih Penawaran Terbaik -> Konversi ke Purchase Order (PO)]
     |-- Status PO: "CONFIRMED"
     |
     v (2. Vendor Mengirimkan Barang ke Gudang)
[Tim Gudang Menerima Barang (Goods Receipt / GRN)]
     |-- Catat Kuantitas Fisik yang Diterima
     |-- Update Saldo Stok Masuk di MOD-09 (Inventory Ingestion)
     |
     v (3. Vendor Mengirimkan Faktur Tagihan)
[Verifikasi 3-Way Matching oleh Tim Finance]
     |-- Cek: Qty Dipesan == Qty Diterima Fisik == Qty Ditagihkan
     |-- Terbitkan Utang Usaha (Accounts Payable) ke MOD-18
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL PEMASOK (VENDORS)
CREATE TABLE IF NOT EXISTS public.procurement_vendors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL, -- Contoh: 'VND-001'
    name VARCHAR(200) NOT NULL,
    contact_person VARCHAR(150),
    email VARCHAR(150) NOT NULL,
    phone_number VARCHAR(30) NOT NULL,
    address TEXT,
    tax_id VARCHAR(50), -- NPWP
    payment_terms VARCHAR(50) DEFAULT 'NET_30', -- 'COD', 'NET_14', 'NET_30', 'NET_60'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PURCHASE ORDER (PO)
CREATE TABLE IF NOT EXISTS public.purchase_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    po_number VARCHAR(60) UNIQUE NOT NULL, -- Format: PO-YYYYMMDD-XXXX
    vendor_id UUID NOT NULL REFERENCES public.procurement_vendors(id),
    warehouse_id UUID NOT NULL REFERENCES public.warehouses(id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    subtotal_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    total_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(30) DEFAULT 'DRAFT', -- 'DRAFT', 'RFQ', 'ORDERED', 'PARTIAL_RECEIVED', 'RECEIVED', 'BILLED', 'CANCELLED'
    notes TEXT,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL RINCIAN ITEM PO
CREATE TABLE IF NOT EXISTS public.purchase_order_lines (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    po_id UUID NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity_ordered INT NOT NULL,
    quantity_received INT NOT NULL DEFAULT 0,
    unit_cost NUMERIC(15, 2) NOT NULL,
    subtotal NUMERIC(15, 2) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_po_vendor ON public.purchase_orders (vendor_id);
CREATE INDEX IF NOT EXISTS idx_po_status ON public.purchase_orders (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.procurement_vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_order_lines ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public purchase access" ON public.purchase_orders FOR ALL TO anon USING (false);

-- 2. Staff Purchasing & Finance memiliki izin penuh
CREATE POLICY "Allow purchasing staff manage POs" 
ON public.purchase_orders 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: GOOD RECEIPT INGESTION (JAVASCRIPT)

```javascript
/**
 * MOD-23: Receive Goods & Sync with MOD-09 Stock
 */
async function processGoodsReceipt(poId, receivedLines, warehouseId) {
    try {
        for (let item of receivedLines) {
            // 1. Update status penerimaan di PO lines
            await supabaseClient
                .from('purchase_order_lines')
                .update({ quantity_received: item.qtyReceived })
                .eq('id', item.lineId);

            // 2. Tambah stok fisik di MOD-09 Inventory
            await supabaseClient.rpc('record_stock_movement', {
                p_product_id: item.productId,
                p_warehouse_id: warehouseId,
                p_movement_type: 'INCOMING',
                p_quantity: item.qtyReceived,
                p_ref_doc: `PO-${poId}`
            });
        }

        showNotification('[SUCCESS] Penerimaan barang berhasil dicatat & stok telah bertambah.', 'success');
    } catch (err) {
        console.error('[RECEIPT_ERROR]', err);
        showNotification('[ERROR] Gagal memproses penerimaan barang.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA PURCHASE ORDER VIEWER

```html
<div class="procurement-card">
    <div class="card-header">
        <h3>Surat Pesanan Pembelian (Purchase Order)</h3>
        <span class="badge badge-info">[STATUS: ORDERED]</span>
    </div>
    <div class="po-details">
        <p><strong>Nomor PO:</strong> <code>PO-20260819-0045</code></p>
        <p><strong>Nama Vendor:</strong> PT Suplai Material Utama</p>
        <p><strong>Gudang Tujuan:</strong> Gudang Pusat Distribusi</p>
    </div>
    <table class="data-table">
        <thead>
            <tr><th>SKU</th><th>Nama Barang</th><th>Kuantitas Dipesan</th><th>Kuantitas Tiba</th><th>Harga Satuan</th><th>Total</th></tr>
        </thead>
        <tbody>
            <tr><td><code>RAW-001</code></td><td>Biji Plastik Polimer</td><td>500 Kg</td><td>500 Kg</td><td>Rp 25.000</td><td>Rp 12.500.000</td></tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Sinkronisasi Stok Otomatis:** Penerimaan barang pada PO otomatis mengupdate saldo stok fisik di gudang tujuan.
- [ ] **Validasi 3-Way Matching:** Mencegah pelunasan jika kuantitas faktur berbeda dari kuantitas fisik yang diterima.
- [ ] **Pemberian Izin:** Hanya staf berwenang yang dapat mengubah status PO menjadi `CONFIRMED`.
- [ ] **Strict No-Emoji:** Status dokumen PO dan label verifikasi bebas emoji.