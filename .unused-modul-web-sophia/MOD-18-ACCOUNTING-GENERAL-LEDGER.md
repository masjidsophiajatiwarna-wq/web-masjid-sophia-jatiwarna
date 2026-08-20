# SPESIFIKASI MODUL: DOUBLE-ENTRY ACCOUNTING & GENERAL LEDGER
> Kode Modul: `MOD-18` | Versi: `1.0.0` | Kategori: `Keuangan (Finance Core / REC-01)` | Dependensi: `Supabase`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-18-ACCOUNTING-GENERAL-LEDGER` |
| **Nama Modul** | Double-Entry Accounting & General Ledger Engine |
| **Kategori** | Core Financial Accounting & General Ledger |
| **Level Akses Publik** | Restricted (Finance Officer & Auditor `authenticated`) |
| **Tingkat Decoupling** | High (Menjadi muara jurnal otomatis dari MOD-02, MOD-06, MOD-07, MOD-19, MOD-20) |
| **Integrasi Pilar** | Supabase (PostgreSQL Double-Entry Balancing Ledger & Financial Statements) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan sistem pembukuan akuntansi berstandar PSAK / IFRS dengan prinsip pencatatan berpasangan (*double-entry balancing: Debit = Kredit*), Bagan Akun terstruktur (*Chart of Accounts - COA: Aset, Liabilitas, Ekuitas, Pendapatan, Beban*), buku besar (*General Ledger*), neraca saldo (*Trial Balance*), laporan laba rugi (*Profit & Loss*), dan rekonsiliasi mutasi bank.

### Fitur Utama:
1. **Chart of Accounts (COA) Standar:** Hierarki 5 digit kode akun (10000 Aset s.d. 50000 Beban).
2. **Atomic Journal Entry Validator:** Memastikan setiap transaksi jurnal memiliki total debit sama dengan total kredit sebelum disimpan.
3. **Laporan Keuangan Otomatis:** Neraca Keuangan (*Balance Sheet*) dan Laporan Laba Rugi periode dinamis.
4. **Jurnal Penutup Periode:** Kunci buku tahunan/bulanan untuk mencegah manipulasi data historis.

---

## 3. DIAGRAM ALUR JURNAL AKUNTANSI OTOMATIS

```text
[EVENT TRANSAKSI BISNIS]
   |-- Penjualan MOD-06 / MOD-20 (Debit: Kas/Bank, Kredit: Pendapatan)
   |-- Pembayaran Faktur MOD-07  (Debit: Kas/Bank, Kredit: Piutang Usaha)
   |-- Pembelian Stok MOD-23     (Debit: Persediaan, Kredit: Utang Usaha)
   |-- Beban Reimburse MOD-19    (Debit: Beban Ops, Kredit: Kas/Bank)
   |
   v
[PostgreSQL Journal Engine (Supabase RPC)]
   |-- Validasi: SUM(Debit) == SUM(Credit)
   |-- Simpan Header ke public.accounting_journals
   |-- Simpan Lines ke public.journal_entry_lines
   |
   v
[Agregasi Laporan Finansial Real-Time]
   |-- General Ledger per Akun
   |-- Neraca Saldo (Trial Balance)
   |-- Laporan Laba Rugi (P&L) & Neraca (Balance Sheet)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL BAGAN AKUN (CHART OF ACCOUNTS - COA)
CREATE TABLE IF NOT EXISTS public.chart_of_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    account_code VARCHAR(20) UNIQUE NOT NULL, -- Contoh: '11101' (Kas Utama), '41100' (Pendapatan Jasa)
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- 'ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE'
    normal_balance VARCHAR(10) NOT NULL DEFAULT 'DEBIT', -- 'DEBIT' atau 'CREDIT'
    parent_id UUID REFERENCES public.chart_of_accounts(id),
    is_reconcilable BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL INDUK JURNAL (JOURNAL HEADERS)
CREATE TABLE IF NOT EXISTS public.accounting_journals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    journal_number VARCHAR(60) UNIQUE NOT NULL, -- Format: JRN/YYYY/MM/XXXX
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reference_document VARCHAR(100), -- Contoh: 'INV/2026/08/0001'
    description TEXT NOT NULL,
    status VARCHAR(30) DEFAULT 'POSTED', -- 'DRAFT', 'POSTED', 'CANCELLED'
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL RINCIAN ENTRI JURNAL (JOURNAL ENTRY LINES)
CREATE TABLE IF NOT EXISTS public.journal_entry_lines (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    journal_id UUID NOT NULL REFERENCES public.accounting_journals(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES public.chart_of_accounts(id),
    debit_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    credit_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    memo VARCHAR(255),
    CONSTRAINT positive_debit_credit CHECK (debit_amount >= 0 AND credit_amount >= 0),
    CONSTRAINT not_both_zero CHECK (debit_amount > 0 OR credit_amount > 0)
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_coa_code ON public.chart_of_accounts (account_code);
CREATE INDEX IF NOT EXISTS idx_journals_date ON public.accounting_journals (entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_journal_lines_acc ON public.journal_entry_lines (account_id);

-- VALIDATOR ATOMIK DOUBLE-ENTRY BALANCING
CREATE OR REPLACE FUNCTION public.validate_journal_balance(p_journal_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_total_debit NUMERIC(15, 2);
    v_total_credit NUMERIC(15, 2);
BEGIN
    SELECT COALESCE(SUM(debit_amount), 0), COALESCE(SUM(credit_amount), 0)
    INTO v_total_debit, v_total_credit
    FROM public.journal_entry_lines
    WHERE journal_id = p_journal_id;

    IF v_total_debit != v_total_credit THEN
        RAISE EXCEPTION '[UNBALANCED_JOURNAL] Total Debit (Rp %) tidak seimbang dengan Total Kredit (Rp %).', v_total_debit, v_total_credit;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounting_journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entry_lines ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public accounting access" ON public.accounting_journals FOR ALL TO anon USING (false);

-- 2. Izin khusus untuk Finance / Superadmin
CREATE POLICY "Allow finance staff manage accounting" 
ON public.accounting_journals 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE role IN ('SUPERADMIN', 'FINANCE') AND is_active = true)
);

CREATE POLICY "Allow finance staff manage journal lines" 
ON public.journal_entry_lines 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE role IN ('SUPERADMIN', 'FINANCE') AND is_active = true)
);
```

---

## 6. LOGIKA KLIEN: POST JURNAL UMUM (JAVASCRIPT)

```javascript
/**
 * MOD-18: Journal Entry Poster
 */
async function postJournalEntry(entryHeader, entryLines) {
    const totalDebit = entryLines.reduce((acc, line) => acc + (parseFloat(line.debit) || 0), 0);
    const totalCredit = entryLines.reduce((acc, line) => acc + (parseFloat(line.credit) || 0), 0);

    if (Math.abs(totalDebit - totalCredit) > 0.01) {
        showNotification(`[ERROR] Jurnal tidak seimbang. Debit: ${totalDebit} != Kredit: ${totalCredit}`, 'error');
        return;
    }

    try {
        const { data: journal, error: jError } = await supabaseClient
            .from('accounting_journals')
            .insert([entryHeader])
            .select()
            .single();

        if (jError) throw jError;

        const linesPayload = entryLines.map(line => ({
            journal_id: journal.id,
            account_id: line.account_id,
            debit_amount: line.debit || 0,
            credit_amount: line.credit || 0,
            memo: line.memo || ''
        }));

        const { error: lError } = await supabaseClient
            .from('journal_entry_lines')
            .insert(linesPayload);

        if (lError) throw lError;

        showNotification(`[SUCCESS] Jurnal ${journal.journal_number} berhasil diposting.`, 'success');
    } catch (err) {
        console.error('[ACCOUNTING_ERROR]', err);
        showNotification('[ERROR] Gagal memposting entri akuntansi.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA LAPORAN LABA RUGI (P&L)

```html
<div class="financial-report-card">
    <div class="report-header">
        <h3>Laporan Laba Rugi (Profit & Loss Statement)</h3>
        <p class="period">Periode: 01 Januari 2026 - 31 Agustus 2026</p>
    </div>

    <table class="financial-table">
        <tbody>
            <tr class="header-row"><td colspan="2"><strong>PENDAPATAN USAHA</strong></td></tr>
            <tr><td>41100 - Pendapatan Penjualan Produk</td><td class="text-right">Rp 450.000.000</td></tr>
            <tr><td>41200 - Pendapatan Jasa Konsultasi</td><td class="text-right">Rp 120.000.000</td></tr>
            <tr class="subtotal-row"><td><strong>TOTAL PENDAPATAN</strong></td><td class="text-right"><strong>Rp 570.000.000</strong></td></tr>

            <tr class="header-row"><td colspan="2"><strong>BEBAN POKOK PENJUALAN (HPP)</strong></td></tr>
            <tr><td>51100 - Harga Pokok Penjualan Produk</td><td class="text-right">(Rp 210.000.000)</td></tr>
            <tr class="subtotal-row"><td><strong>LABA KOTOR (GROSS PROFIT)</strong></td><td class="text-right"><strong>Rp 360.000.000</strong></td></tr>

            <tr class="header-row"><td colspan="2"><strong>BEBAN OPERASIONAL</strong></td></tr>
            <tr><td>52100 - Beban Gaji & Honorarium</td><td class="text-right">(Rp 150.000.000)</td></tr>
            <tr><td>52200 - Beban Sewa & Utilitas</td><td class="text-right">(Rp 30.000.000)</td></tr>
            <tr class="highlight-row"><td><strong>LABA BERSIH OPERASIONAL (NET PROFIT)</strong></td><td class="text-right"><strong>Rp 180.000.000</strong></td></tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Keseimbangan Debit/Kredit Mutlak:** Sistem menolak penyimpanan entri yang tidak seimbang (*unbalanced*).
- [ ] **Integritas COA:** Akun induk tidak dapat dihapus jika masih memiliki sub-akun anak yang aktif.
- [ ] **Akurasi Neraca Keuangan:** Nilai Aset sama persis dengan Liabilitas + Ekuitas pada setiap tanggal cut-off.
- [ ] **Strict No-Emoji:** Format laporan keuangan, badge status jurnal, dan notifikasi bebas emoji.