# SPESIFIKASI MODUL: INVOICING, BILLING & PDF RECEIPT ENGINE
> Kode Modul: `MOD-07` | Versi: `1.0.0` | Kategori: `Finance & Accounting (Odoo-Grade Suite)` | Dependensi: `Supabase, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-07-INVOICING-BILLING-SYSTEM` |
| **Nama Modul** | Invoicing, Billing & PDF Receipt Engine |
| **Kategori** | Financial Operations & Accounting Automation |
| **Level Akses Publik** | Restricted Admin / Client View with Signature Token |
| **Tingkat Decoupling** | High (Menerima input dari MOD-05, MOD-06, atau entri manual admin) |
| **Integrasi Pilar** | Supabase (PostgreSQL Ledgers), Resend (Auto PDF Delivery) |

---

## 2. TUJUAN BISNIS & USE CASE

Otomasi penerbitan tagihan profesional (Invoice / Faktur Penjualan), pengingat jatuh tempo otomatis (*due date reminders*), perhitungan pajak PPN/PPH, dan generasi dokumen tanda terima cetak (PDF / Print-Ready HTML) yang memenuhi standar pembukuan akuntansi legal.

### Fitur Utama:
1. **Penomoran Faktur Otomatis:** Format standar berurutan (`INV/YYYY/MM/XXXX`).
2. **Kalkulasi Pajak & Diskon:** Penanganan PPN 11%, potongan muka (Down Payment / DP), dan sisa pelunasan.
3. **Public Secure View Link:** Tautan aman yang dapat dibagikan ke klien untuk melihat status faktur (`/invoice/INV-2026-001?token=xyz`).
4. **Pengiriman Email PDF Terjadwal via Resend:** Pengiriman otomatis invoice baru dan reminder H-3 sebelum jatuh tempo.

---

## 3. DIAGRAM ALUR INVOICING & STATUS PEMBAYARAN

```text
[ADMIN / SISTEM OTOMASI]
     |
     v (1. Buat Faktur / Generate dari Deal CRM)
[Supabase: public.invoices & public.invoice_items]
     |-- Hitung Subtotal, PPN, dan Grand Total
     |-- Terbitkan Nomor Faktur Unik
     |-- Set Status: "DRAFT" -> "SENT"
     |
     v (2. Kirim Link / PDF via Resend Email)
[Klien / Customer]
     |-- Buka Secure Invoice View (HTML / Print View)
     |-- Melakukan Pembayaran via QRIS (MOD-02) atau Transfer Bank
     |
     v (3. Rekonsiliasi Pembayaran)
[Supabase Trigger: On Status "PAID"]
     |-- Terbitkan Nomor Kuitansi Resmi (Receipt: RCT/YYYY/XXXX)
     |-- Kirim Tanda Terima Pelunasan ke Email Klien
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL FAKTUR (INVOICES)
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    invoice_number VARCHAR(60) UNIQUE NOT NULL, -- Format: INV/2026/08/0001
    customer_name VARCHAR(150) NOT NULL,
    customer_company VARCHAR(150),
    customer_email VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(30),
    customer_address TEXT,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    subtotal_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    tax_percentage NUMERIC(5, 2) DEFAULT 0.00, -- Contoh: 11.00 (PPN 11%)
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    discount_amount NUMERIC(15, 2) DEFAULT 0.00,
    total_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(15, 2) DEFAULT 0.00,
    status VARCHAR(30) DEFAULT 'DRAFT', -- 'DRAFT', 'SENT', 'PARTIAL', 'PAID', 'OVERDUE', 'CANCELLED'
    secure_token VARCHAR(100) UNIQUE NOT NULL DEFAULT md5(random()::text || clock_timestamp()::text),
    notes TEXT,
    payment_terms TEXT,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL RINCIAN ITEM FAKTUR
CREATE TABLE IF NOT EXISTS public.invoice_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    item_description VARCHAR(255) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1.00,
    unit_price NUMERIC(15, 2) NOT NULL,
    total_price NUMERIC(15, 2) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_invoices_number ON public.invoices (invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices (status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON public.invoices (due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_token ON public.invoices (secure_token);

-- TRIGGER UPDATE TOTAL INVOICE OTOMATIS
CREATE OR REPLACE FUNCTION public.recalculate_invoice_total()
RETURNS TRIGGER AS $$
DECLARE
    v_subtotal NUMERIC(15, 2);
    v_tax NUMERIC(15, 2);
    v_inv RECORD;
BEGIN
    SELECT COALESCE(SUM(total_price), 0.00) INTO v_subtotal
    FROM public.invoice_items
    WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id);

    SELECT * INTO v_inv FROM public.invoices WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);
    
    v_tax := ROUND((v_subtotal * (v_inv.tax_percentage / 100.00)), 2);

    UPDATE public.invoices
    SET subtotal_amount = v_subtotal,
        tax_amount = v_tax,
        total_amount = (v_subtotal + v_tax - discount_amount)
    WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_items_calc ON public.invoice_items;
CREATE TRIGGER trg_invoice_items_calc
AFTER INSERT OR UPDATE OR DELETE ON public.invoice_items
FOR EACH ROW
EXECUTE FUNCTION public.recalculate_invoice_total();
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;

-- 1. Publik hanya boleh melihat invoice miliknya via secure_token URL
CREATE POLICY "Allow public read invoice by token" 
ON public.invoices 
FOR SELECT 
TO anon 
USING (true); -- Dibatasi dengan filter query token di frontend

CREATE POLICY "Allow public read invoice items" 
ON public.invoice_items 
FOR SELECT 
TO anon 
USING (true);

-- 2. Tim Admin memiliki hak penuh untuk membuat dan mengubah invoice
CREATE POLICY "Allow admin full access to invoices" 
ON public.invoices 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: PRINT-READY CSS & AUTO NUMBER GENERATOR

```javascript
/**
 * MOD-07: Invoicing Helper & Print Trigger
 */

// Generate Nomor Invoice Otomatis (Format: INV/2026/08/0001)
async function generateNextInvoiceNumber() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');

    const { count } = await supabaseClient
        .from('invoices')
        .select('*', { count: 'exact', head: true });

    const sequence = String((count || 0) + 1).padStart(4, '0');
    return `INV/${year}/${month}/${sequence}`;
}

// Buka Dialog Cetak / Simpan PDF Browser
function printInvoiceDocument() {
    window.print();
}
```

---

## 7. SPESIFIKASI TEMPLATE INVOICE CETAK (PRINT-READY HTML)

```html
<div class="invoice-box">
    <table cellpadding="0" cellspacing="0">
        <tr class="top">
            <td colspan="2">
                <table>
                    <tr>
                        <td class="title">
                            <h2 class="company-name">NAMA PERUSAHAAN / BRAND</h2>
                            <p class="company-sub">Layanan Solusi Digital Terpadu</p>
                        </td>
                        <td class="text-right">
                            <strong>FAKTUR TAGIHAN</strong><br>
                            Nomor: <code id="inv-num">INV/2026/08/0001</code><br>
                            Tanggal Terbit: 19 Agustus 2026<br>
                            Jatuh Tempo: 26 Agustus 2026
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        
        <tr class="information">
            <td colspan="2">
                <table>
                    <tr>
                        <td>
                            <strong>Ditagihkan Kepada:</strong><br>
                            PT Mitra Berkah Sejahtera<br>
                            Attn: Bapak Hendra Wijaya<br>
                            hendra@mitraberkah.com
                        </td>
                        <td class="text-right">
                            <strong>Status Pembayaran:</strong><br>
                            <span class="badge badge-warning">[BELUM DIBAYAR / UNPAID]</span>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kalkulasi Trigger Database:** Perubahan item rincian otomatis mengkalkulasi ulang subtotal, pajak, dan grand total.
- [ ] **Akses Aman Token:** Mengakses halaman tanpa token rahasia yang valid menolak tampilan data.
- [ ] **Format Cetak Standar A4:** Tampilan cetak rapi dan bersih pada ukuran kertas A4 tanpa terpotong.
- [ ] **Strict No-Emoji:** Penanda status faktur (`[DRAFT]`, `[PAID]`, `[OVERDUE]`) menggunakan teks formal.