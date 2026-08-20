# SPESIFIKASI MODUL: MEMBERSHIP TIER & LOYALTY POINTS ENGINE
> Kode Modul: `MOD-11` | Versi: `1.0.0` | Kategori: `Customer Experience & Retention (Odoo-Grade Suite)` | Dependensi: `Supabase, ImageKit`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-11-MEMBERSHIP-LOYALTY-POINTS` |
| **Nama Modul** | Membership Tier & Loyalty Points Engine |
| **Kategori** | Customer Retention & Loyalty Program |
| **Level Akses Publik** | Member Authenticated (`auth.uid()`) |
| **Tingkat Decoupling** | High (Menambah lapisan insentif pada MOD-06, MOD-08, MOD-02) |
| **Integrasi Pilar** | Supabase (Atomic Point Ledgers & Tier Calculation), ImageKit (Digital Member Card) |

---

## 2. TUJUAN BISNIS & USE CASE

Meningkatkan *Customer Lifetime Value (CLV)* dan tingkat retensi pelanggan melalui sistem poin berjenjang (*tiered loyalty points: Silver, Gold, Platinum*), penukaran poin (*point redemption*) untuk voucher belanja/diskon, dan kartu member digital dengan kode QR personal.

### Fitur Utama:
1. **Multi-Tier Hierarchy:** Pengelompokan tingkat keanggotaan berdasarkan total akumulasi belanja (misal: Silver > Gold > Platinum).
2. **Double-Entry Point Ledger:** Pencatatan kredit (+Poin) saat belanja dan debit (-Poin) saat penukaran voucher secara atomik.
3. **Katalog Reward & Penukaran Kupon:** Menukar poin dengan kode diskon otomatis untuk MOD-06.
4. **Digital Membership Card:** Tampilan kartu virtual dengan barcode/QR member untuk dipindai di kasir fisik.

---

## 3. DIAGRAM ALUR AKUMULASI & PENUKARAN POIN

```text
[TRANSAKSI PEMBELIAN SELESAI (MOD-06 / MOD-02)]
     |
     v (1. Pemicu: Status "PAID")
[Point Engine: log_loyalty_earning]
     |-- Hitung Poin: 1 Poin per Rp 10.000 Belanja
     |-- Tambah Saldo Poin ke public.loyalty_ledgers (+100 Poin)
     |-- Update Total Belanja Tahunan & Evaluasi Kenaikan Tier Member
     |
     v (2. Pelanggan Mengakses Portal Poin)
[Katalog Penukaran Hadiah (Redemption)]
     |-- Pelanggan memilih "Voucher Diskon Rp 50.000" (Harga: 500 Poin)
     |-- Cek Saldo Poin: Jika Cukup -> Potong Saldo (-500 Poin)
     |-- Generate Unique Coupon Code untuk Checkout
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL TIER LEVEL KEANGGOTAAN
CREATE TABLE IF NOT EXISTS public.membership_tiers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tier_name VARCHAR(50) UNIQUE NOT NULL, -- 'SILVER', 'GOLD', 'PLATINUM'
    min_spend_threshold NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    point_multiplier NUMERIC(3, 2) NOT NULL DEFAULT 1.00, -- Contoh: 1.5x poin untuk Gold
    perks_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL SALDO MEMBER (LINK PROFIL)
CREATE TABLE IF NOT EXISTS public.member_loyalty_cards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    member_card_number VARCHAR(60) UNIQUE NOT NULL, -- Format: MBR-YYYYMM-XXXX
    current_tier_id UUID REFERENCES public.membership_tiers(id),
    current_points_balance INT NOT NULL DEFAULT 0,
    lifetime_points_earned INT NOT NULL DEFAULT 0,
    total_lifetime_spend NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL BUKU BESAR POIN (IMMUTABLE POINT LEDGER)
CREATE TABLE IF NOT EXISTS public.loyalty_point_ledgers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    card_id UUID NOT NULL REFERENCES public.member_loyalty_cards(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL, -- 'EARNED', 'REDEEMED', 'EXPIRED', 'ADJUSTMENT'
    points INT NOT NULL, -- Positif jika earned, Negatif jika redeemed
    balance_after INT NOT NULL,
    reference_id VARCHAR(100), -- Order ID atau Reward ID
    description VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_loyalty_card_user ON public.member_loyalty_cards (user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_ledger_card ON public.loyalty_point_ledgers (card_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.membership_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_loyalty_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_point_ledgers ENABLE ROW LEVEL SECURITY;

-- 1. Semua pengguna boleh melihat informasi tier
CREATE POLICY "Allow public read tiers" 
ON public.membership_tiers 
FOR SELECT 
TO anon, authenticated 
USING (true);

-- 2. Member hanya bisa melihat saldo dan buku besar poin miliknya
CREATE POLICY "Member view own loyalty card" 
ON public.member_loyalty_cards 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Member view own point ledger" 
ON public.loyalty_point_ledgers 
FOR SELECT 
TO authenticated 
USING (
    card_id IN (SELECT id FROM public.member_loyalty_cards WHERE user_id = auth.uid())
);

-- 3. Admin memiliki akses penuh
CREATE POLICY "Admin manage loyalty" 
ON public.member_loyalty_cards 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: REDEEM REWARD HANDLER (JAVASCRIPT)

```javascript
/**
 * MOD-11: Point Redemption Handler
 */
async function redeemRewardVoucher(rewardId, pointsCost) {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
        showNotification('[WARNING] Harap masuk ke akun Anda terlebih dahulu.', 'warning');
        return;
    }

    try {
        const { data, error } = await supabaseClient
            .rpc('process_loyalty_redemption', {
                p_user_id: user.id,
                p_reward_id: rewardId,
                p_points_cost: pointsCost
            });

        if (error) throw error;

        showNotification(`[SUCCESS] Penukaran berhasil! Kode voucher Anda: ${data.coupon_code}`, 'success');
        refreshPointsDisplay();
    } catch (err) {
        console.error('[REDEMPTION_ERROR]', err);
        showNotification('[ERROR] Saldo poin tidak mencukupi untuk menukar hadiah ini.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA KARTU MEMBER DIGITAL

```html
<div class="digital-member-card platinum-tier">
    <div class="card-top">
        <span class="brand-logo-text">LOYALTY REWARDS</span>
        <span class="tier-pill">[PLATINUM MEMBER]</span>
    </div>
    <div class="card-middle">
        <div class="points-block">
            <span class="points-label">Total Saldo Poin:</span>
            <h2 class="points-value">1,450 PTS</h2>
        </div>
    </div>
    <div class="card-bottom">
        <div class="member-meta">
            <span class="member-name">Ahmad Fauzan</span>
            <code class="member-id">MBR-202608-8821</code>
        </div>
        <div class="card-barcode-frame">
            <canvas id="member-barcode-canvas"></canvas>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Integritas Saldo Poin:** Saldo poin tidak pernah bernilai minus berkat validasi constraint database.
- [ ] **Kalkulasi Akumulasi Multiplier:** Poin terkalkulasi tepat berdasarkan faktor pengali tier pengguna.
- [ ] **Audit Trail Riwayat:** Setiap penambahan dan pengurangan poin terekam permanen di `loyalty_point_ledgers`.
- [ ] **Strict No-Emoji:** Tampilan kartu member dan status tier bebas emoji.