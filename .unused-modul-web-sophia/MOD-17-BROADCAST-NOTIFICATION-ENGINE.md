# SPESIFIKASI MODUL: MULTI-CHANNEL BROADCAST & NOTIFICATION ENGINE
> Kode Modul: `MOD-17` | Versi: `1.0.0` | Kategori: `Marketing & Communications (Odoo-Grade Suite)` | Dependensi: `Supabase, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-17-BROADCAST-NOTIFICATION-ENGINE` |
| **Nama Modul** | Multi-Channel Broadcast & Notification Engine (Email & WhatsApp) |
| **Kategori** | Marketing Automation, Mass Communication & Alerts |
| **Level Akses Publik** | Restricted (Marketing Team & Admin `authenticated`) |
| **Tingkat Decoupling** | High (Menyerap kontak dari MOD-01, MOD-04, MOD-06, MOD-08) |
| **Integrasi Pilar** | Supabase (Broadcast Audience Segmentation), Resend (Mass Email API) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengirimkan siaran berita (*newsletter*), pengumuman kegiatan komunitas/masjid, penawaran promo kilat (*flash sale*), dan peringatan sistem secara massal ke ribuan kontak terdaftar melalui Email (Resend API) dan Webhook WhatsApp dengan segmentasi audiens yang presisi dan pelacakan status pengiriman (*delivery / open rate*).

### Fitur Utama:
1. **Segmentasi Audiens Dinamis:** Filter penerima berdasarkan kriteria (Semua Donatur, Pembeli Kategori Tertentu, Peserta Acara X, Status Member Platinum).
2. **Template Builder (HTML/Markdown):** Penyusunan template email yang rapi, responsif, dan bebas emoji.
3. **Queue & Batch Dispatcher:** Pengiriman bertahap (throttled) untuk menghindari penalti spam rate-limit.
4. **Unsubscribe Link Compliance:** Tautan berhenti berlangganan otomatis sesuai aturan hukum privasi data.

---

## 3. DIAGRAM ALUR SIARAN MASSAL (BROADCAST WORKFLOW)

```text
[MARKETING ADMIN (broadcast-composer.html)]
     |
     v (1. Tentukan Audiens & Susun Template Pesan)
[Supabase: public.broadcast_campaigns]
     |-- Segmentasi: SELECT email FROM public.form_submissions WHERE form_type = 'donasi'
     |-- Masukkan antrean ke public.broadcast_queue (Status: PENDING)
     |
     v (2. Queue Dispatcher Worker)
[Batch Processor (Rate Limit: 50 emails/detik)]
     |-- Ambil 50 entri PENDING
     |-- Kirim payload ke Resend Batch Email API
     |
     v (3. Feedback & Pelacakan Delivery)
[Resend Webhook Receiver (Supabase Edge Function)]
     |-- Update status: "DELIVERED", "OPENED", "BOUNCED", "COMPLAINED"
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL KAMPANYE SIARAN (BROADCAST CAMPAIGNS)
CREATE TABLE IF NOT EXISTS public.broadcast_campaigns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    channel VARCHAR(30) NOT NULL DEFAULT 'EMAIL', -- 'EMAIL', 'WHATSAPP'
    subject VARCHAR(255) NOT NULL,
    content_body TEXT NOT NULL,
    target_segment VARCHAR(100) NOT NULL DEFAULT 'ALL', -- 'ALL', 'DONORS', 'CUSTOMERS', 'MEMBERS'
    total_recipients INT DEFAULT 0,
    total_sent INT DEFAULT 0,
    total_delivered INT DEFAULT 0,
    total_opened INT DEFAULT 0,
    status VARCHAR(30) DEFAULT 'DRAFT', -- 'DRAFT', 'QUEUED', 'SENDING', 'COMPLETED', 'CANCELLED'
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL ANTREAN PENGIRIMAN (BROADCAST QUEUE)
CREATE TABLE IF NOT EXISTS public.broadcast_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    campaign_id UUID NOT NULL REFERENCES public.broadcast_campaigns(id) ON DELETE CASCADE,
    recipient_email VARCHAR(150),
    recipient_phone VARCHAR(30),
    recipient_name VARCHAR(150),
    status VARCHAR(30) DEFAULT 'PENDING', -- 'PENDING', 'SENT', 'DELIVERED', 'FAILED', 'BOUNCED'
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_broadcast_campaign_status ON public.broadcast_campaigns (status);
CREATE INDEX IF NOT EXISTS idx_broadcast_queue_status ON public.broadcast_queue (campaign_id, status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.broadcast_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast_queue ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public broadcast access" ON public.broadcast_campaigns FOR ALL TO anon USING (false);
CREATE POLICY "Deny public queue access" ON public.broadcast_queue FOR ALL TO anon USING (false);

-- 2. Admin Marketing memiliki akses penuh
CREATE POLICY "Allow marketing manage broadcasts" 
ON public.broadcast_campaigns 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);

CREATE POLICY "Allow marketing manage queue" 
ON public.broadcast_queue 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: RESEND BATCH DISPATCHER (JAVASCRIPT)

```javascript
/**
 * MOD-17: Broadcast Campaign Dispatcher
 */
async function launchBroadcastCampaign(campaignId) {
    const confirmSend = confirm('Apakah Anda yakin ingin memulai pengiriman siaran massal sekarang?');
    if (!confirmSend) return;

    try {
        const { error } = await supabaseClient
            .from('broadcast_campaigns')
            .update({
                status: 'QUEUED',
                sent_at: new Date().toISOString()
            })
            .eq('id', campaignId);

        if (error) throw error;
        showNotification('[SUCCESS] Kampanye berhasil dimasukkan ke dalam antrean pengiriman.', 'success');
        refreshCampaignList();
    } catch (err) {
        console.error('[BROADCAST_ERROR]', err);
        showNotification('[ERROR] Gagal memicu pengiriman siaran.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA PENGELOLA SIARAN

```html
<div class="broadcast-composer-card">
    <div class="composer-header">
        <h3>Susun Pesan Siaran Massal (Broadcast)</h3>
        <span class="badge badge-primary">[CHANNEL: EMAIL RESEND]</span>
    </div>

    <form id="broadcast-form" class="composer-form">
        <div class="form-group">
            <label for="campaign-title">Nama Kampanye (Internal)</label>
            <input type="text" id="campaign-title" required placeholder="Contoh: Laporan Bulanan Donasi Agustus 2026" class="form-input">
        </div>

        <div class="form-group">
            <label for="target-segment">Target Segmen Audiens</label>
            <select id="target-segment" class="form-select">
                <option value="ALL">Semua Kontak Terdaftar</option>
                <option value="DONORS">Seluruh Donatur Aktif</option>
                <option value="CUSTOMERS">Pelanggan Toko Online</option>
                <option value="MEMBERS">Anggota Member Komunitas</option>
            </select>
        </div>

        <div class="form-group">
            <label for="email-subject">Subjek Email</label>
            <input type="text" id="email-subject" required placeholder="Tuliskan judul subjek email yang menarik dan formal" class="form-input">
        </div>

        <div class="form-group">
            <label for="email-body">Isi Pesan (HTML / Plain Text)</label>
            <textarea id="email-body" rows="6" required placeholder="Tuliskan isi pengumuman atau newsletter Anda" class="form-textarea"></textarea>
        </div>

        <div class="form-actions">
            <button type="button" class="btn btn-secondary">Simpan Draf</button>
            <button type="submit" class="btn btn-primary">Kirim Siaran Sekarang</button>
        </div>
    </form>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kepatuhan Anti-Spam:** Pengiriman menyertakan header DKIM/SPF terverifikasi via Resend.
- [ ] **Throttling Queue:** Pengiriman batch tidak melampaui limit kuota API per detik.
- [ ] **Segmentasi Presisi:** Jumlah antrean sesuai dengan kriteria filter segmen yang dipilih.
- [ ] **Strict No-Emoji:** Teks subjek, isi email siaran, dan status kampanye bebas emoji.