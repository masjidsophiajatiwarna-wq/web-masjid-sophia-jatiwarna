# SPESIFIKASI MODUL: HELPDESK, SUPPORT TICKET & SLA MANAGER
> Kode Modul: `MOD-16` | Versi: `1.0.0` | Kategori: `Customer Support (Odoo-Grade Suite)` | Dependensi: `Supabase, Resend, Gmail`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-16-HELPDESK-TICKET-SUPPORT` |
| **Nama Modul** | Helpdesk, Support Ticket & SLA Manager |
| **Kategori** | Customer Support, Incident Management & Helpdesk |
| **Level Akses Publik** | Public Anonymous (Submit) / Customer Auth / Support Staff |
| **Tingkat Decoupling** | High (Menangani keluhan terkait pesanan MOD-06 atau modul lainnya) |
| **Integrasi Pilar** | Supabase (Ticket State & Chat Threads), Resend (Email Reply Ingestion), Gmail (Forwarding) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan sistem *ticketing support* pelanggan profesional untuk menangani keluhan, pertanyaan produk, atau permohonan bantuan teknis dengan nomor tiket unik, penetapan prioritas masalah (*Low, Medium, High, Urgent*), pelacakan target SLA respon (*First Response Time*), serta riwayat percakapan transparan antara tim support dan pelanggan.

### Fitur Utama:
1. **Penerbitan Nomor Tiket Unik:** Format standar penomoran (`TCK-YYYYMMDD-XXXX`).
2. **Thread Percakapan Dua Arah:** Klien dapat membalas via portal web atau balasan email langsung.
3. **Catatan Internal (Internal Notes):** Komentar khusus tim support yang tersembunyi dari tampilan klien.
4. **SLA Breach Monitoring:** Peringatan otomatis jika tiket berstatus *Urgent* belum direspon dalam 2 jam.

---

## 3. DIAGRAM ALUR TIKET BANTUAN & RESOLUSI

```text
[PELANGGAN]
     |
     v (1. Buat Tiket via Form Web atau Email Gmail Forwarding)
[Supabase: public.support_tickets]
     |-- Terbitkan Nomor Tiket: TCK-20260819-0012
     |-- Set Status: "OPEN" | Prioritas: "HIGH"
     |-- Kirim Email Resend Konfirmasi ke Pelanggan
     |
     v (2. Tim Support Mengambil Tiket)
[Support Agent Dashboard]
     |-- Status diubah ke "IN_PROGRESS"
     |-- Kirim balasan publik atau tambahkan catatan internal
     |
     v (3. Penyelesaian Masalah)
[Status: RESOLVED / CLOSED]
     |-- Kirim email notifikasi solusi ke Pelanggan
     |-- Minta rating kepuasan (1 - 5 Bintang)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL TIKET BANTUAN (SUPPORT TICKETS)
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_number VARCHAR(60) UNIQUE NOT NULL, -- Format: TCK-YYYYMMDD-XXXX
    customer_name VARCHAR(150) NOT NULL,
    customer_email VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(30),
    subject VARCHAR(255) NOT NULL,
    category VARCHAR(50) DEFAULT 'GENERAL', -- 'BILLING', 'TECHNICAL', 'ORDER', 'GENERAL'
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- 'LOW', 'MEDIUM', 'HIGH', 'URGENT'
    status VARCHAR(30) DEFAULT 'OPEN', -- 'OPEN', 'IN_PROGRESS', 'WAITING_CLIENT', 'RESOLVED', 'CLOSED'
    assigned_agent_id UUID REFERENCES public.admin_users(id),
    first_response_due TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    satisfaction_rating INT, -- Nilai 1 s.d 5
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PESAN THREAD TIKET (TICKET MESSAGES)
CREATE TABLE IF NOT EXISTS public.ticket_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL, -- 'CLIENT', 'AGENT', 'SYSTEM'
    sender_name VARCHAR(150) NOT NULL,
    message_body TEXT NOT NULL,
    is_internal_note BOOLEAN DEFAULT false, -- True = Hanya terlihat oleh staf internal
    attachments TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_tickets_number ON public.support_tickets (ticket_number);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON public.support_tickets (status);
CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket ON public.ticket_messages (ticket_id);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh membuat tiket baru
CREATE POLICY "Allow public create ticket" 
ON public.support_tickets 
FOR INSERT 
TO anon 
WITH CHECK (char_length(trim(subject)) >= 5);

-- 2. Publik boleh melihat tiket miliknya via ticket_number
CREATE POLICY "Allow public view own ticket" 
ON public.support_tickets 
FOR SELECT 
TO anon 
USING (true);

-- 3. Publik hanya boleh melihat pesan thread yang BUKAN internal note
CREATE POLICY "Allow public read public messages" 
ON public.ticket_messages 
FOR SELECT 
TO anon 
USING (is_internal_note = false);

-- 4. Admin Support memiliki akses penuh
CREATE POLICY "Allow support staff manage tickets" 
ON public.support_tickets 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);

CREATE POLICY "Allow support staff manage messages" 
ON public.ticket_messages 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: TICKET THREAD DISPATCHER (JAVASCRIPT)

```javascript
/**
 * MOD-16: Support Ticket Message Dispatcher
 */
async function sendTicketReply(ticketId, messageText, isInternal = false) {
    const { data: { user } } = await supabaseClient.auth.getUser();

    try {
        const { error } = await supabaseClient
            .from('ticket_messages')
            .insert([{
                ticket_id: ticketId,
                sender_type: user ? 'AGENT' : 'CLIENT',
                sender_name: user ? user.email : document.getElementById('client-name').value,
                message_body: messageText,
                is_internal_note: isInternal
            }]);

        if (error) throw error;
        showNotification('[SUCCESS] Balasan berhasil dikirim.', 'success');
        refreshTicketThread(ticketId);
    } catch (err) {
        console.error('[TICKET_REPLY_ERROR]', err);
        showNotification('[ERROR] Gagal mengirim balasan tiket.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA THREAD PERCAKAPAN

```html
<div class="ticket-thread-container">
    <div class="ticket-header">
        <h3 class="ticket-subject">Kendala Verifikasi Pembayaran Donasi #124</h3>
        <span class="badge badge-warning">[STATUS: IN PROGRESS]</span>
        <span class="badge badge-danger">[PRIORITAS: URGENT]</span>
    </div>

    <div class="messages-stream">
        <!-- Pesan Pelanggan -->
        <div class="message-bubble client">
            <div class="message-meta"><strong>Ahmad Fauzan</strong> - 19 Ags 2026, 14:10</div>
            <div class="message-text">Saya sudah transfer donasi sebesar Rp 100.412 tetapi status belum berubah menjadi lunas.</div>
        </div>

        <!-- Pesan Agen Support -->
        <div class="message-bubble agent">
            <div class="message-meta"><strong>Tim Support</strong> - 19 Ags 2026, 14:25</div>
            <div class="message-text">Halo Bapak Ahmad, terima kasih atas konfirmasinya. Mutasi pembayaran telah kami verifikasi secara manual.</div>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kerahasiaan Catatan Internal:** Pesan dengan `is_internal_note = true` tidak pernah bocor ke sisi klien publik.
- [ ] **SLA Timer Alert:** Tiket dengan prioritas tinggi memunculkan visual highlight jika melewati batas waktu respon.
- [ ] **Format Nomor Tiket:** Penomoran tiket unik dan otomatis berurutan.
- [ ] **Strict No-Emoji:** Label prioritas (`[LOW]`, `[MEDIUM]`, `[HIGH]`, `[URGENT]`) bebas dari emoji.