# SPESIFIKASI MODUL: POINT OF SALE (POS RETAIL & KASIR OFFLINE)
> Kode Modul: `MOD-20` | Versi: `1.0.0` | Kategori: `Sales & POS Suite (REC-03)` | Dependensi: `Supabase, MOD-02, MOD-09`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-20-POINT-OF-SALE-RETAIL` |
| **Nama Modul** | Point of Sale (POS) Retail & Offline Cashier Engine |
| **Kategori** | Retail Operations & Storefront Checkout |
| **Level Akses Publik** | Cashier & Store Manager (`authenticated`) |
| **Tingkat Decoupling** | High (Sinkronisasi stok dengan MOD-09 dan pembayaran QRIS dengan MOD-02) |
| **Integrasi Pilar** | Supabase (POS Session Ledger & Realtime Order Sync), LocalStorage (Offline Resilience) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan antarmuka kasir toko fisik/outlet ritel yang cepat, responsif, mendukung pemindaian barcode USB/Bluetooth, cetak struk kasir thermal (ESC/POS 58mm/80mm), manajemen sesi kasir buka/tutup laci kas (*Cash Drawer Balancing*), dan operasional offline saat koneksi internet terputus.

### Fitur Utama:
1. **Barcode Scanner Ingestion:** Input cepat via barcode reader (keyboard emulation mode).
2. **Sesi Kasir (Cashier Shift Management):** Pencatatan modal awal kas (*opening cash*) dan rekonsiliasi kas akhir (*closing cash*).
3. **Multi-Payment Split:** Pembayaran Tunai (Cash), Debit/Kartu Kredit EDC, dan QRIS Dinamis (MOD-02).
4. **Thermal Receipt Printing:** Cetak struk instan via Web Bluetooth / WebUSB / Print Dialog.

---

## 3. DIAGRAM ALUR SESI KASIR & TRANSAKSI

```text
[KASIR TOKO (pos-cashier.html)]
     |
     v (1. Buka Sesi Kasir: Input Kas Awal Rp 200.000)
[Supabase: public.pos_sessions (Status: OPEN)]
     |
     v (2. Scan Barcode Barang / Klik Produk Cepat)
[Keranjang Kasir Interaktif (Client Memory)]
     |-- Hitung Total Belanja + PPN
     |-- Pilih Cara Bayar: TUNAI / QRIS (MOD-02)
     |
     v (3. Selesaikan Transaksi)
[Simpan ke public.pos_orders & Kurangi Stok MOD-09]
     |-- Cetak Struk Thermal 58mm
     |
     v (4. Tutup Sesi di Akhir Shift)
[Rekonsiliasi Kas (Status: CLOSED)]
     |-- Hitung Selisih Fisik Kas vs Sistem (Cash Variance Audit)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL SESI KASIR (POS SESSIONS)
CREATE TABLE IF NOT EXISTS public.pos_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_number VARCHAR(60) UNIQUE NOT NULL, -- Format: POS-SES-YYYYMMDD-XXXX
    cashier_id UUID NOT NULL REFERENCES public.admin_users(id),
    warehouse_id UUID NOT NULL REFERENCES public.warehouses(id), -- Gudang/Toko sumber stok
    opening_cash NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    closing_cash NUMERIC(15, 2),
    expected_closing_cash NUMERIC(15, 2),
    cash_difference NUMERIC(15, 2),
    status VARCHAR(30) DEFAULT 'OPEN', -- 'OPEN', 'CLOSED'
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- TABEL TRANSAKSI POS
CREATE TABLE IF NOT EXISTS public.pos_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    receipt_number VARCHAR(60) UNIQUE NOT NULL, -- Format: RCT-YYYYMMDD-XXXX
    session_id UUID NOT NULL REFERENCES public.pos_sessions(id),
    total_amount NUMERIC(15, 2) NOT NULL,
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    discount_amount NUMERIC(15, 2) DEFAULT 0.00,
    amount_tendered NUMERIC(15, 2) NOT NULL, -- Jumlah uang diterima
    change_due NUMERIC(15, 2) NOT NULL DEFAULT 0.00, -- Kembalian
    payment_method VARCHAR(50) NOT NULL, -- 'CASH', 'QRIS', 'EDC_DEBIT', 'EDC_CREDIT'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL RINCIAN ITEM POS
CREATE TABLE IF NOT EXISTS public.pos_order_lines (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.pos_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    unit_price NUMERIC(15, 2) NOT NULL,
    quantity INT NOT NULL,
    subtotal NUMERIC(15, 2) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_pos_session_cashier ON public.pos_sessions (cashier_id);
CREATE INDEX IF NOT EXISTS idx_pos_orders_session ON public.pos_orders (session_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.pos_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_order_lines ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public POS access" ON public.pos_orders FOR ALL TO anon USING (false);

-- 2. Kasir & Manager berhak mengelola transaksi
CREATE POLICY "Allow cashier manage POS orders" 
ON public.pos_orders 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: BARCODE SCANNER LISTENER (JAVASCRIPT)

```javascript
/**
 * MOD-20: Rapid Barcode Scanner Listener
 */
let barcodeBuffer = '';
let lastKeyTime = Date.now();

window.addEventListener('keydown', (e) => {
    const currentTime = Date.now();
    
    // Barcode scanner mengetik karakter sangat cepat (< 50ms per key)
    if (currentTime - lastKeyTime > 100) {
        barcodeBuffer = '';
    }
    lastKeyTime = currentTime;

    if (e.key === 'Enter') {
        if (barcodeBuffer.length >= 3) {
            handleScannedBarcode(barcodeBuffer);
            barcodeBuffer = '';
        }
    } else if (e.key.length === 1) {
        barcodeBuffer += e.key;
    }
});

async function handleScannedBarcode(barcode) {
    const { data: product, error } = await supabaseClient
        .from('products')
        .select('*')
        .eq('sku', barcode)
        .single();

    if (product) {
        addItemToCart(product);
        playAudioBeep('beep');
    } else {
        showNotification(`[WARNING] Produk barcode ${barcode} tidak ditemukan.`, 'warning');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA KASIR POS

```html
<div class="pos-layout">
    <!-- Kolom Kiri: Produk Grid Cepat -->
    <div class="pos-products-grid" id="pos-grid">
        <!-- Render Produk Box -->
    </div>

    <!-- Kolom Kanan: Kasir Terminal & Keranjang -->
    <div class="pos-cart-panel">
        <div class="cart-header">
            <h4>Pesanan Kasir #12</h4>
            <span class="badge badge-success">[SESI AKTIF]</span>
        </div>
        <div class="cart-items-list" id="pos-cart-items"></div>
        <div class="cart-summary">
            <div class="total-line"><span>Total Tagihan:</span><h3 id="pos-grand-total">Rp 0</h3></div>
            <button type="button" class="btn btn-primary btn-block" onclick="openPaymentModal()">Proses Pembayaran (F10)</button>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Responsif Barcode:** Pemindaian barcode menambahkan produk ke daftar belanja dalam waktu < 100ms.
- [ ] **Kalkulasi Uang Kembalian:** Perhitungan selisih nominal uang tunai diterima dan kembalian 100% akurat.
- [ ] **Rekonsiliasi Kasir:** Perhitungan selisih uang kas akhir saat tutup kasir tercatat secara jelas.
- [ ] **Strict No-Emoji:** Tampilan kasir, cetak struk thermal, dan notifikasi bebas emoji.