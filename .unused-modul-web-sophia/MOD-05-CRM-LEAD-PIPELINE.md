# SPESIFIKASI MODUL: CRM LEAD PIPELINE & DEAL MANAGEMENT
> Kode Modul: `MOD-05` | Versi: `1.0.0` | Kategori: `Sales & CRM (Odoo-Grade Suite)` | Dependensi: `Supabase, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-05-CRM-LEAD-PIPELINE` |
| **Nama Modul** | CRM Lead Pipeline & Deal Management |
| **Kategori** | Customer Relationship Management & Sales Ops |
| **Level Akses Publik** | Restricted (Khusus Tim Sales / Admin `authenticated`) |
| **Tingkat Decoupling** | High (Menyerap data dari MOD-01 dan mengalirkan ke MOD-07) |
| **Integrasi Pilar** | Supabase (PostgreSQL Kanban State), Resend (Follow-up Automation) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengubah calon prospek (*leads*) dari formulir website, intake WhatsApp, dan referral menjadi penjualan tertutup (*closed-won deals*) melalui papan Kanban visual yang interaktif, pencatatan histori aktivitas penjualan, dan pelacakan estimasi omzet.

### Fitur Utama:
1. **Papan Kanban Interaktif:** Pemindahan stage lead via drag-and-drop (`NEW`, `QUALIFIED`, `PROPOSAL_SENT`, `NEGOTIATION`, `WON`, `LOST`).
2. **Koneksi Cepat WhatsApp (Click-to-Chat):** Generator link WhatsApp instan lengkap dengan template pesan follow-up dinamis.
3. **Pencatatan Riwayat Aktivitas:** Log panggilan telepon, catatan meeting, dan pengingat tanggal follow-up.
4. **Kalkulasi Probabilitas Omzet:** Menghitung total pipeline value dan weighted expected revenue secara real-time.

---

## 3. DIAGRAM ALUR PIPELINE PENJUALAN (SALES LIFECYCLE)

```text
[INTAKE LEAD (MOD-01 / Manual Entry)]
     |
     v (Status: NEW LEAD)
[Tahap 1: Kualifikasi Kebutuhan (QUALIFIED)]
     |-- Sales mengecek profil anggaran dan urgensi kebutuhan
     |
     v (Tahap 2: Pengiriman Penawaran (PROPOSAL_SENT))
[Kirim Proposal / Invoice Proforma via MOD-07]
     |-- Log tanggal proposal terkirim
     |
     v (Tahap 3: Negosiasi Harga / Kontrak (NEGOTIATION))
[Follow-up via WhatsApp API & Email Resend]
     |
     +---> [WON] (Deal Disetujui -> Terbitkan Tagihan Resmi di MOD-07)
     |
     +---> [LOST] (Batal / Alasan Kalah: Harga, Kompetitor, Anggaran Batal)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL PIPELINE DEALS / LEADS
CREATE TABLE IF NOT EXISTS public.crm_deals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL, -- Contoh: "Pengadaan Website Custom - PT ABC"
    contact_name VARCHAR(150) NOT NULL,
    company_name VARCHAR(150),
    email VARCHAR(150),
    phone_number VARCHAR(30) NOT NULL,
    estimated_value NUMERIC(15, 2) DEFAULT 0.00,
    stage VARCHAR(50) DEFAULT 'NEW', -- 'NEW', 'QUALIFIED', 'PROPOSAL_SENT', 'NEGOTIATION', 'WON', 'LOST'
    probability_percentage INT DEFAULT 20,
    expected_closing_date DATE,
    lead_source VARCHAR(50) DEFAULT 'WEBSITE', -- 'WEBSITE', 'WHATSAPP', 'REFERRAL', 'EXHIBITION'
    assigned_to UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    lost_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL LOG AKTIVITAS SALES (CALLS, MEETINGS, NOTES)
CREATE TABLE IF NOT EXISTS public.crm_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    deal_id UUID NOT NULL REFERENCES public.crm_deals(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- 'CALL', 'WHATSAPP', 'MEETING', 'EMAIL', 'NOTE'
    summary VARCHAR(255) NOT NULL,
    details TEXT,
    performed_by UUID REFERENCES public.admin_users(id),
    follow_up_due TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_crm_deals_stage ON public.crm_deals (stage);
CREATE INDEX IF NOT EXISTS idx_crm_deals_assigned ON public.crm_deals (assigned_to);
CREATE INDEX IF NOT EXISTS idx_crm_activities_deal ON public.crm_activities (deal_id);

-- TRIGGER UPDATE TIMESTAMP
DROP TRIGGER IF EXISTS trg_crm_deals_updated_at ON public.crm_deals;
CREATE TRIGGER trg_crm_deals_updated_at
BEFORE UPDATE ON public.crm_deals
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.crm_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_activities ENABLE ROW LEVEL SECURITY;

-- 1. Blokir semua akses publik (Anon)
CREATE POLICY "Deny public access to CRM deals" 
ON public.crm_deals 
FOR ALL 
TO anon 
USING (false);

-- 2. Tim sales / admin otentikasi dapat membaca dan mengelola data
CREATE POLICY "Allow authenticated staff manage deals" 
ON public.crm_deals 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);

CREATE POLICY "Allow authenticated staff manage activities" 
ON public.crm_activities 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: KANBAN STAGE UPDATER & WHATSAPP GENERATOR

```javascript
/**
 * MOD-05: CRM Actions & WhatsApp Link Generator
 */

// Memindahkan Stage Lead di Database
async function updateDealStage(dealId, newStage) {
    const probabilityMap = {
        'NEW': 10,
        'QUALIFIED': 30,
        'PROPOSAL_SENT': 60,
        'NEGOTIATION': 80,
        'WON': 100,
        'LOST': 0
    };

    try {
        const { error } = await supabaseClient
            .from('crm_deals')
            .update({
                stage: newStage,
                probability_percentage: probabilityMap[newStage] || 20
            })
            .eq('id', dealId);

        if (error) throw error;
        showNotification(`[SUCCESS] Status deal berhasil diperbarui ke: ${newStage}`, 'success');
        refreshKanbanBoard();
    } catch (err) {
        console.error('[CRM_STAGE_ERROR]', err);
        showNotification('[ERROR] Gagal memindahkan stage deal.', 'error');
    }
}

// Menghasilkan Link WhatsApp Follow-Up Otomatis
function openWhatsAppFollowUp(phone, contactName, dealTitle) {
    let cleanPhone = phone.replace(/\D/g, '');
    if (cleanPhone.startsWith('0')) cleanPhone = '62' + cleanPhone.substring(1);
    if (cleanPhone.startsWith('+62')) cleanPhone = cleanPhone.substring(1);

    const message = encodeURIComponent(
        `Halo Bapak/Ibu ${contactName},\n\nTerima kasih telah menghubungi kami terkait *${dealTitle}*.\nApakah ada hal yang dapat kami bantu diskusikan lebih lanjut hari ini?\n\nSalam hormat,\nTim Layanan`
    );

    window.open(`https://wa.me/${cleanPhone}?text=${message}`, '_blank');
}
```

---

## 7. SPESIFIKASI ANTARMUKA KANBAN BOARD

```html
<div class="kanban-wrapper">
    <div class="kanban-column" data-stage="NEW">
        <div class="column-header">
            <h4>PROSPEK BARU (NEW)</h4>
            <span class="count-badge" id="count-new">3</span>
        </div>
        <div class="card-list" id="list-new">
            <!-- Card Item -->
            <div class="deal-card" draggable="true" data-deal-id="uuid-1">
                <div class="deal-title">Pengadaan Cloud Server</div>
                <div class="deal-contact">Budi Santoso - PT Global Tech</div>
                <div class="deal-value">Rp 25.000.000</div>
                <div class="deal-actions">
                    <button type="button" class="btn btn-sm" onclick="openWhatsAppFollowUp('08123456789', 'Budi Santoso', 'Pengadaan Cloud Server')">Chat WA</button>
                </div>
            </div>
        </div>
    </div>
    
    <div class="kanban-column" data-stage="QUALIFIED">
        <div class="column-header"><h4>TERKUALIFIKASI (QUALIFIED)</h4></div>
        <div class="card-list" id="list-qualified"></div>
    </div>
    
    <div class="kanban-column" data-stage="PROPOSAL_SENT">
        <div class="column-header"><h4>PROPOSAL DIKIRIM</h4></div>
        <div class="card-list" id="list-proposal"></div>
    </div>

    <div class="kanban-column" data-stage="WON">
        <div class="column-header"><h4>DEAL WON (SUKSES)</h4></div>
        <div class="card-list" id="list-won"></div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kerahasiaan Data Prospek:** Publik tidak dapat melihat atau menebak data prospek pelanggan lain.
- [ ] **Sinkronisasi Stage:** Perubahan drag-and-drop langsung tersimpan di Supabase secara atomik.
- [ ] **Kalkulasi Omzet:** Total pipeline dan win-rate diperbarui instan tanpa reload halaman.
- [ ] **Format Nomor WhatsApp:** Sistem membersihkan karakter spasi atau tanda minus pada nomor telepon pelanggan.
- [ ] **Strict No-Emoji:** Penamaan kolom kanban dan catatan aktivitas bebas emoji.