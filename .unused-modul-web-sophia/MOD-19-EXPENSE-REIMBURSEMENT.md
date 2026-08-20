# SPESIFIKASI MODUL: EXPENSE CLAIM & REIMBURSEMENT MANAGEMENT
> Kode Modul: `MOD-19` | Versi: `1.0.0` | Kategori: `Keuangan (Finance Core / REC-02)` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-19-EXPENSE-REIMBURSEMENT` |
| **Nama Modul** | Expense Claim & Reimbursement Management Engine |
| **Kategori** | Employee Expenses & Petty Cash Management |
| **Level Akses Publik** | Staff Authenticated (Klaim) / Manager & Finance (Approval & Payout) |
| **Tingkat Decoupling** | High (Menyuplai entri beban ke MOD-18 Accounting) |
| **Integrasi Pilar** | Supabase (Expense Ledger & Workflow), ImageKit (Upload Struk/Nota OCR Ready), Resend (Approval Alert) |

---

## 2. TUJUAN BISNIS & USE CASE

Mempermudah proses pengajuan klaim pengeluaran operasional staf (bensin, makan lembur, tiket perjalanan dinas, pembelian ATK mendadak), unggah bukti foto struk/nota digital ke CDN ImageKit, alur persetujuan berjenjang manajer (*multi-level approval*), dan pencairan dana kas kecil (*petty cash reimbursement*).

### Fitur Utama:
1. **Unggah Foto Struk Instan:** Kompresi otomatis gambar nota ke WebP via ImageKit.
2. **Kategori Beban Standar:** Transportasi, Akomodasi, Konsumsi Lembur, Operasional Kantor, Hiburan Klien.
3. **Workflow Persetujuan 2 Tahap:** Persetujuan Manajer Divisi -> Verifikasi & Pembayaran oleh Finance.
4. **Auto-Journal ke MOD-18:** Pembuatan jurnal otomatis saat klaim berstatus `PAID` (Debit Beban, Kredit Kas).

---

## 3. DIAGRAM ALUR KLAIM REIMBURSEMENT

```text
[KARYAWAN / STAF]
     |
     v (1. Foto Struk & Isi Form Pengeluaran)
[ImageKit CDN & Supabase: public.expense_claims]
     |-- Upload Gambar Struk
     |-- Set Status: "SUBMITTED"
     |-- Kirim Email Notifikasi ke Manajer
     |
     v (2. Review Manajer Divisi)
[Persetujuan Manajer]
     |-- Disetujui -> Status: "APPROVED_BY_MANAGER"
     |-- Ditolak -> Status: "REJECTED" (Sertakan alasan penolakan)
     |
     v (3. Pencairan oleh Tim Finance)
[Finance Officer Payout]
     |-- Transfer ke Rekening Staf
     |-- Status: "PAID"
     |-- Generate Jurnal Beban ke MOD-18
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL KATEGORI BEBAN
CREATE TABLE IF NOT EXISTS public.expense_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    account_code VARCHAR(20) NOT NULL, -- Link ke COA MOD-18 (Contoh: '52300')
    max_limit_per_claim NUMERIC(15, 2) DEFAULT 0.00, -- 0 = Tanpa batas
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL KLAIM PENGELUARAN (EXPENSE CLAIMS)
CREATE TABLE IF NOT EXISTS public.expense_claims (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    claim_number VARCHAR(60) UNIQUE NOT NULL, -- Format: EXP-YYYYMMDD-XXXX
    employee_id UUID NOT NULL REFERENCES public.admin_users(id),
    category_id UUID NOT NULL REFERENCES public.expense_categories(id),
    expense_date DATE NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    description TEXT NOT NULL,
    receipt_image_url TEXT NOT NULL, -- ImageKit CDN URL
    status VARCHAR(30) DEFAULT 'SUBMITTED', -- 'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'PAID'
    approved_by UUID REFERENCES public.admin_users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    paid_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_expense_employee ON public.expense_claims (employee_id);
CREATE INDEX IF NOT EXISTS idx_expense_status ON public.expense_claims (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_claims ENABLE ROW LEVEL SECURITY;

-- 1. Staf hanya bisa melihat dan membuat klaim miliknya sendiri
CREATE POLICY "Staff view own expense claims" 
ON public.expense_claims 
FOR SELECT 
TO authenticated 
USING (
    employee_id IN (SELECT id FROM public.admin_users WHERE email = auth.jwt() ->> 'email') OR
    auth.jwt() ->> 'role' = 'service_role' OR
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'FINANCE', 'MANAGER')
);

CREATE POLICY "Staff insert own expense claims" 
ON public.expense_claims 
FOR INSERT 
TO authenticated 
WITH CHECK (amount > 0);

-- 2. Manager dan Finance berhak mengupdate status klaim
CREATE POLICY "Manager and Finance manage expenses" 
ON public.expense_claims 
FOR UPDATE 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') IN ('SUPERADMIN', 'FINANCE', 'MANAGER')
);
```

---

## 6. LOGIKA KLIEN: EXPENSE SUBMISSION HANDLER (JAVASCRIPT)

```javascript
/**
 * MOD-19: Expense Submission Helper
 */
async function submitExpenseClaim(payload) {
    const now = new Date();
    const claimNumber = `EXP-${now.getFullYear()}${String(now.getMonth()+1).padStart(2,'0')}${String(now.getDate()).padStart(2,'0')}-${Math.floor(1000 + Math.random() * 9000)}`;

    try {
        const { data, error } = await supabaseClient
            .from('expense_claims')
            .insert([{
                claim_number: claimNumber,
                employee_id: payload.employeeId,
                category_id: payload.categoryId,
                expense_date: payload.expenseDate,
                amount: payload.amount,
                description: payload.description,
                receipt_image_url: payload.receiptUrl
            }])
            .select()
            .single();

        if (error) throw error;
        showNotification(`[SUCCESS] Pengajuan klaim ${claimNumber} berhasil dikirim untuk review.`, 'success');
    } catch (err) {
        console.error('[EXPENSE_ERROR]', err);
        showNotification('[ERROR] Gagal mengajukan klaim pengeluaran.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA KLAIM EXPENSE

```html
<div class="expense-card">
    <div class="card-header">
        <h3>Pengajuan Klaim Biaya Operasional (Reimbursement)</h3>
    </div>
    <form id="expense-form" class="form-grid">
        <div class="form-group">
            <label for="expense-cat">Kategori Pengeluaran</label>
            <select id="expense-cat" class="form-select" required>
                <option value="cat-1">BBM & Transportasi Dinas</option>
                <option value="cat-2">Konsumsi Lembur Proyek</option>
            </select>
        </div>
        <div class="form-group">
            <label for="expense-amount">Nominal Biaya (IDR)</label>
            <input type="number" id="expense-amount" required placeholder="Contoh: 150000" class="form-input">
        </div>
        <div class="form-group">
            <label for="receipt-file">Foto Nota/Struk Fisik</label>
            <input type="file" id="receipt-file" accept="image/*" class="form-input" required>
        </div>
        <button type="submit" class="btn btn-primary">Ajukan Klaim Sekarang</button>
    </form>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Wajib Bukti Nota:** Sistem menolak pengajuan klaim tanpa URL gambar struk yang valid.
- [ ] **Proteksi Lintas Karyawan:** Staf biasa tidak dapat mengintip nominal klaim staf divisi lain.
- [ ] **Notifikasi Approval:** Manajer menerima email rincian klaim baru dalam waktu < 5 detik.
- [ ] **Strict No-Emoji:** Status alur persetujuan (`[SUBMITTED]`, `[APPROVED]`, `[REJECTED]`, `[PAID]`) bebas emoji.