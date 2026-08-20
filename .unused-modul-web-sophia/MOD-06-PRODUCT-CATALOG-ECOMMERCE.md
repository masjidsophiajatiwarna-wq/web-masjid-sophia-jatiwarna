# SPESIFIKASI MODUL: E-COMMERCE PRODUCT CATALOG & CART CHECKOUT
> Kode Modul: `MOD-06` | Versi: `1.0.0` | Kategori: `Commerce & Sales (Odoo-Grade Suite)` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-06-PRODUCT-CATALOG-ECOMMERCE` |
| **Nama Modul** | E-Commerce Product Catalog & Cart Checkout Engine |
| **Kategori** | Digital Commerce & Order Management |
| **Level Akses Publik** | Anonymous Shopper / Store Manager Admin |
| **Tingkat Decoupling** | High (Bisa berdiri sendiri dengan checkout WhatsApp atau digabung dengan MOD-02 & MOD-07) |
| **Integrasi Pilar** | Supabase (Katalog, Varian & Pesanan), ImageKit (Foto Produk HD/Thumb), Resend (Nota Order) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan etalase produk dan katalog digital dengan varian warna/ukuran/SKU, keranjang belanja *client-side* berbasis LocalStorage/IndexedDB, perhitungan diskon/kupon promo, dan multi-channel checkout (Checkout instan ke WhatsApp Toko atau Pembayaran QRIS).

### Fitur Unggulan:
1. **Manajemen Produk & Multi-Varian:** Pengelolaan harga dasar, harga diskon, berat barang (gram), stok per SKU.
2. **Galeri Gambar ImageKit CDN:** Konversi otomatis thumbnail grid 400x400 dan modal detail HD 1200x1200.
3. **Keranjang Belanja Persisten:** Sinkronisasi keranjang belanja tanpa perlu login pengguna.
4. **Kupon Diskon & Promo:** Validasi kupon berbasis minimum belanja dan kuota pemakaian.

---

## 3. DIAGRAM ALUR PEMBELIAN & CHECKOUT

```text
[PENGUNJUNG / PEMBELI]
     |
     v (1. Telusuri Katalog Produk & Pilih Varian)
[Keranjang Belanja (LocalStorage)]
     |-- Tambah Produk / Ubah Kuantitas
     |-- Terapkan Kode Promo (Kupon Diskon)
     |
     v (2. Halaman Checkout)
[Formulir Pengiriman & Pembayaran]
     |-- Masukkan Nama, No WhatsApp, Alamat Lengkap & Pilihan Kurir
     |
     v (3. Pembuatan Pesanan di Supabase)
[Supabase: public.ecommerce_orders]
     |-- Simpan Ringkasan Pesanan (Status: PENDING_PAYMENT)
     |-- Simpan Rincian Item Pesanan (public.order_items)
     |
     +---> [Opsi A: Bayar QRIS (MOD-02)] -> Buka Canvas QRIS & Verifikasi
     |
     +---> [Opsi B: Checkout WhatsApp Direct] -> Buka Chat Admin dengan Rekap Format Rapi
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL KATEGORI PRODUK
CREATE TABLE IF NOT EXISTS public.product_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    thumbnail_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PRODUK UTAMA
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    sku VARCHAR(60) UNIQUE NOT NULL,
    description_html TEXT,
    base_price NUMERIC(15, 2) NOT NULL,
    discount_price NUMERIC(15, 2),
    stock_quantity INT DEFAULT 0,
    weight_grams INT DEFAULT 500,
    images TEXT[] DEFAULT ARRAY[]::TEXT[], -- Array URL ImageKit
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PESANAN (ORDERS)
CREATE TABLE IF NOT EXISTS public.ecommerce_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number VARCHAR(60) UNIQUE NOT NULL, -- Format: ORD-YYYYMMDD-XXXX
    customer_name VARCHAR(150) NOT NULL,
    customer_email VARCHAR(150),
    customer_phone VARCHAR(30) NOT NULL,
    shipping_address TEXT NOT NULL,
    subtotal_amount NUMERIC(15, 2) NOT NULL,
    discount_amount NUMERIC(15, 2) DEFAULT 0.00,
    shipping_cost NUMERIC(15, 2) DEFAULT 0.00,
    total_amount NUMERIC(15, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'QRIS', -- 'QRIS', 'TRANSFER_MANUAL', 'WHATSAPP_COD'
    payment_status VARCHAR(30) DEFAULT 'UNPAID', -- 'UNPAID', 'PAID', 'CANCELLED'
    fulfillment_status VARCHAR(30) DEFAULT 'UNFULFILLED', -- 'UNFULFILLED', 'PROCESSING', 'SHIPPED', 'DELIVERED'
    tracking_number VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL ITEM RINCIAN PESANAN (ORDER ITEMS)
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.ecommerce_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name VARCHAR(200) NOT NULL,
    sku VARCHAR(60) NOT NULL,
    unit_price NUMERIC(15, 2) NOT NULL,
    quantity INT NOT NULL,
    total_price NUMERIC(15, 2) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_products_slug ON public.products (slug);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products (is_active);
CREATE INDEX IF NOT EXISTS idx_orders_number ON public.ecommerce_orders (order_number);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items (order_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ecommerce_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh melihat produk dan kategori yang aktif
CREATE POLICY "Allow public read active products" 
ON public.products 
FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

CREATE POLICY "Allow public read categories" 
ON public.product_categories 
FOR SELECT 
TO anon, authenticated 
USING (true);

-- 2. Publik boleh membuat pesanan baru (INSERT)
CREATE POLICY "Allow public insert order" 
ON public.ecommerce_orders 
FOR INSERT 
TO anon 
WITH CHECK (total_amount > 0);

CREATE POLICY "Allow public insert order items" 
ON public.order_items 
FOR INSERT 
TO anon 
WITH CHECK (quantity > 0);

-- 3. Admin memiliki kontrol penuh
CREATE POLICY "Allow admin manage products and orders" 
ON public.products 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: CART MANAGEMENT & WHATSAPP CHECKOUT FORMATTER

```javascript
/**
 * MOD-06: Shopping Cart State & WhatsApp Dispatcher
 */
const CART_STORAGE_KEY = 'brand_cart_v1';

function getCartItems() {
    return JSON.parse(localStorage.getItem(CART_STORAGE_KEY) || '[]');
}

function addToCart(product, quantity = 1) {
    let cart = getCartItems();
    const existingIndex = cart.findIndex(item => item.id === product.id);

    if (existingIndex > -1) {
        cart[existingIndex].quantity += quantity;
    } else {
        cart.push({
            id: product.id,
            name: product.name,
            sku: product.sku,
            price: product.discount_price || product.base_price,
            quantity: quantity,
            image: product.images[0] || ''
        });
    }

    localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(cart));
    updateCartBadge();
    showNotification(`[SUCCESS] ${product.name} ditambahkan ke keranjang.`, 'success');
}

// Format Pesanan ke Teks WhatsApp
function dispatchToWhatsApp(orderNumber, customerInfo, cartItems, grandTotal) {
    let itemsText = cartItems.map((item, idx) => 
        `${idx + 1}. ${item.name} (${item.quantity}x) = Rp ${(item.price * item.quantity).toLocaleString('id-ID')}`
    ).join('\n');

    let message = `*FORMAT PESANAN BARU*\n` +
        `------------------------------------\n` +
        `*No. Pesanan:* ${orderNumber}\n` +
        `*Nama Pemesan:* ${customerInfo.name}\n` +
        `*No. WhatsApp:* ${customerInfo.phone}\n` +
        `*Alamat Kirim:* ${customerInfo.address}\n` +
        `------------------------------------\n` +
        `*Rincian Barang:*\n${itemsText}\n` +
        `------------------------------------\n` +
        `*Total Pembayaran:* Rp ${grandTotal.toLocaleString('id-ID')}\n\n` +
        `Mohon konfirmasi ketersediaan stok dan info rekening pembayaran. Terima kasih.`;

    window.open(`https://wa.me/6281234567890?text=${encodeURIComponent(message)}`, '_blank');
}
```

---

## 7. SPESIFIKASI GRID PRODUK & KARTU ITEM

```html
<div class="product-grid">
    <!-- Card Produk -->
    <div class="product-card" data-sku="PRD-001">
        <div class="card-media">
            <img src="https://ik.imagekit.io/brand/tr:w-400,h-400,fo-auto/produk-1.jpg" alt="Nama Produk" loading="lazy">
            <span class="badge-tag">[PROMO]</span>
        </div>
        <div class="card-details">
            <h4 class="product-title">Paket Bundling Premium</h4>
            <div class="pricing">
                <span class="price-discount">Rp 149.000</span>
                <span class="price-original">Rp 199.000</span>
            </div>
            <button type="button" class="btn btn-primary btn-block" onclick="addToCart({id: 'uuid-1', name: 'Paket Bundling Premium', sku: 'PRD-001', base_price: 149000})">
                + Keranjang
            </button>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Persistensi Keranjang:** Isi keranjang belanja tidak hilang saat halaman di-refresh atau tab ditutup.
- [ ] **Kalkulasi Total Akurat:** Perhitungan subtotal, diskon kupon, dan total akhir akurat hingga 2 desimal.
- [ ] **Optimasi CDN Gambar:** Seluruh gambar di-load via ImageKit CDN dengan resolusi proporsional.
- [ ] **Pencegahan Stok Minus:** Transaksi gagal jika jumlah pesanan melebihi stok yang tersedia.
- [ ] **Strict No-Emoji:** Format ringkasan pesanan WhatsApp dan notifikasi bebas emoji.