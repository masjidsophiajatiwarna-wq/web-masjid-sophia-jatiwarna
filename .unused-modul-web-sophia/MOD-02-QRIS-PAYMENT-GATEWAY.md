# SPESIFIKASI MODUL: PAYMENT & DONATION VIA QR (QRIS / EMVCO)
> Kode Modul: `MOD-02` | Versi: `1.0.0` | Kategori: `Core & Public Interaction / Payment` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-02-QRIS-PAYMENT-GATEWAY` |
| **Nama Modul** | Payment & Donation via QR (QRIS / EMVCo Standard) |
| **Kategori** | Digital Payments & Invoicing |
| **Level Akses Publik** | Anonymous / Authenticated |
| **Tingkat Decoupling** | High (Bisa berdiri sendiri atau dipicu oleh MOD-01 / MOD-06 / MOD-07) |
| **Integrasi Pilar** | Supabase (Database & RLS), ImageKit (Upload Bukti Bayar), Resend (Invoice Email) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan penerimaan pembayaran donasi, pembelian produk, atau tagihan jasa secara instan dan tanpa biaya integrasi gateway yang mahal, menggunakan standarisasi QRIS Nasional (Bank Indonesia / ASPI) dan EMVCo.

### Fitur Utama:
1. **Dynamic / Static QRIS Generator:** Menghasilkan string payload QRIS dengan nominal dinamis atau statis.
2. **Sistem 3-Digit Unique Code:** Menambahkan 3 digit angka unik (misal Rp 100.342) untuk verifikasi mutasi bank otomatis/manual.
3. **Canvas QR Renderer Klien:** Merender QR langsung di peramban tanpa membebani server backend.
4. **Unggah Bukti Transfer Aman:** Upload gambar bukti transaksi langsung ke ImageKit CDN.
5. **Auto Invoice Generator via Resend:** Mengirimkan tanda terima resmi berformat HTML ke email pembayar.

---

## 3. DIAGRAM ALUR TRANSAKSI & VERIFIKASI

```text
[PENGUNJUNG]
     |
     v (1. Masukkan Nominal Donasi/Pesanan)
[Client QR Engine (JS)]
     |-- Generate 3-Digit Unique Code (misal: 100.000 + 412 = 100.412)
     |-- Buat String Standar EMVCo / QRIS
     |-- Render Canvas QR Code (QRCode.js)
     |-- Simpan Status Transaksi "WAITING_PAYMENT" ke Supabase
     |
     v (2. Pengunjung Scan & Bayar via BCA/Mandiri/GoPay/OVO/ShopeePay)
[Unggah Bukti Transfer (Opsional)]
     |-- Upload Gambar Bukti ke ImageKit CDN (Secure Upload Signature)
     |-- Update Record Transaksi dengan URL Bukti & Status "PENDING_VERIFICATION"
     |
     v (3. Verifikasi Mutasi)
[Admin Dashboard / Bank Webhook Listener]
     |-- Admin memeriksa kecocokan 3-digit kode unik
     |-- Status diubah menjadi "PAID" / "VERIFIED"
     |
     v (4. Auto Receipt)
[Resend Notification Dispatcher]
     |-- Kirim Kuitansi Resmi & Notifikasi WhatsApp/Email
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL TRANSAKSI PEMBAYARAN & DONASI
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reference_number VARCHAR(60) UNIQUE NOT NULL, -- Format: TRX-YYYYMMDD-XXXX
    submission_id UUID REFERENCES public.form_submissions(id) ON DELETE SET NULL,
    payer_name VARCHAR(150) NOT NULL,
    payer_email VARCHAR(150),
    payer_phone VARCHAR(30) NOT NULL,
    base_amount NUMERIC(15, 2) NOT NULL,
    unique_code INT DEFAULT 0, -- 3 digit unik verifikasi (0 - 999)
    total_amount NUMERIC(15, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'QRIS', -- 'QRIS', 'BANK_TRANSFER', 'MANUAL'
    qris_payload TEXT,
    proof_image_url TEXT, -- CDN URL dari ImageKit.io
    status VARCHAR(30) DEFAULT 'WAITING_PAYMENT', -- 'WAITING_PAYMENT', 'PENDING_VERIFICATION', 'PAID', 'EXPIRED', 'CANCELLED'
    verified_by UUID, -- ID Admin yang memverifikasi
    verified_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_payment_ref ON public.payment_transactions (reference_number);
CREATE INDEX IF NOT EXISTS idx_payment_status ON public.payment_transactions (status);
CREATE INDEX IF NOT EXISTS idx_payment_expires ON public.payment_transactions (expires_at);

-- TRIGGER UPDATE TIMESTAMP
DROP TRIGGER IF EXISTS trg_payment_transactions_updated_at ON public.payment_transactions;
CREATE TRIGGER trg_payment_transactions_updated_at
BEFORE UPDATE ON public.payment_transactions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- 1. Publik (Anon) boleh membuat transaksi baru
CREATE POLICY "Allow public insert payment" 
ON public.payment_transactions 
FOR INSERT 
TO anon 
WITH CHECK (base_amount > 0 AND total_amount >= base_amount);

-- 2. Publik boleh melihat status transaksinya sendiri menggunakan reference_number unik
CREATE POLICY "Allow public read own payment by reference" 
ON public.payment_transactions 
FOR SELECT 
TO anon 
USING (true); -- Dibatasi dengan select filter spesifik di sisi API

-- 3. Publik boleh mengunggah bukti bayar (UPDATE proof_image_url & status)
CREATE POLICY "Allow public upload proof" 
ON public.payment_transactions 
FOR UPDATE 
TO anon 
USING (status = 'WAITING_PAYMENT')
WITH CHECK (status = 'PENDING_VERIFICATION');

-- 4. Admin otentikasi memiliki kontrol penuh untuk verifikasi
CREATE POLICY "Allow admin manage all payments" 
ON public.payment_transactions 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. IMPLEMENTASI JAVASCRIPT: EMVCO CRC16 & CANVAS RENDERER

```javascript
/**
 * MOD-02: QRIS Dynamic Payload Generator & Canvas Renderer
 */

// Menghitung Checksum CRC16 CCITT (Standar EMVCo QRIS)
function calculateCRC16(str) {
    let crc = 0xFFFF;
    for (let c = 0; c < str.length; c++) {
        crc ^= str.charCodeAt(c) << 8;
        for (let i = 0; i < 8; i++) {
            if (crc & 0x8000) {
                crc = (crc << 1) ^ 0x1021;
            } else {
                crc = crc << 1;
            }
        }
    }
    let hex = (crc & 0xFFFF).toString(16).toUpperCase();
    return hex.padStart(4, '0');
}

// Menghasilkan Dynamic QRIS dari Static QRIS Base
function makeDynamicQRIS(staticQRIS, nominal) {
    // Menghapus Tag 58 (Country), Tag 53 (Currency), dan Tag 63 (CRC) dari ujung static
    let base = staticQRIS.slice(0, -4);
    let step1 = base.replace("010211", "010212"); // Ubah flag jadi dynamic
    let parts = step1.split("5802ID");
    
    let nominalStr = nominal.toString();
    let nominalTag = "54" + nominalStr.length.toString().padStart(2, "0") + nominalStr;
    let fullPayload = parts[0] + nominalTag + "5802ID" + parts[1];
    
    // Hitung ulang CRC
    let finalCRC = calculateCRC16(fullPayload);
    return fullPayload + finalCRC;
}

// Render ke elemen canvas
function renderQRToCanvas(canvasId, payloadString) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    
    QRCode.toCanvas(canvas, payloadString, {
        width: 280,
        margin: 2,
        color: {
            dark: '#0f172a',
            light: '#ffffff'
        }
    }, function (error) {
        if (error) console.error('[QR_RENDER_ERROR]', error);
        else console.log('[QR_RENDER_SUCCESS] QR code successfully generated.');
    });
}
```

---

## 7. SPESIFIKASI ANTARMUKA KASIR / MODAL PEMBAYARAN

```html
<div class="payment-modal-card">
    <div class="modal-header">
        <h3 class="title">Pembayaran QRIS Instan</h3>
        <p class="subtitle">Pindai QR menggunakan aplikasi perbankan atau e-wallet apa pun.</p>
    </div>

    <div class="qr-presentation-area">
        <div class="canvas-wrapper">
            <canvas id="qr-payment-canvas"></canvas>
        </div>
        <div class="amount-badge">
            <span class="label">Total Pembayaran:</span>
            <span class="value" id="display-total-amount">Rp 100.412</span>
            <small class="notice">[PERHATIAN] Transfer tepat hingga 3 digit terakhir untuk verifikasi instan.</small>
        </div>
    </div>

    <div class="payment-timer">
        <span>Batas Waktu Pembayaran: <strong id="countdown-timer">14:59</strong></span>
    </div>

    <div class="proof-upload-section">
        <label for="proof-file">Sudah transfer? Unggah bukti pembayaran:</label>
        <input type="file" id="proof-file" accept="image/png, image/jpeg, image/webp" class="file-input">
        <button type="button" onclick="uploadPaymentProof()" class="btn btn-secondary">Kirim Bukti Pembayaran</button>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Validasi Payload EMVCo:** Checksum CRC16 berhasil dipindai oleh minimal 3 aplikasi bank berbeda (BCA Mobile, Livin Mandiri, GoPay).
- [ ] **Kode Unik Otomatis:** Sistem konsisten menghasilkan 3-digit kode unik yang tidak bertabrakan pada jam sibuk.
- [ ] **Batas Kadaluarsa:** Transaksi otomatis ditandai `EXPIRED` setelah lewat batas waktu 15/30 menit.
- [ ] **Upload CDN ImageKit:** Bukti pembayaran terkompresi otomatis ke format WebP dan tersimpan di CDN.
- [ ] **Strict No-Emoji:** Tampilan invoice dan status bayar bebas dari karakter emoji visual.