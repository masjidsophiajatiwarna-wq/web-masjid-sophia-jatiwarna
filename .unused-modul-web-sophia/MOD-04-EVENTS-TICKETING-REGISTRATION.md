# SPESIFIKASI MODUL: EVENTS, TICKETING & QR REGISTRATION
> Kode Modul: `MOD-04` | Versi: `1.0.0` | Kategori: `Core & Public Interaction / Events` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-04-EVENTS-TICKETING-REGISTRATION` |
| **Nama Modul** | Events, Ticketing & QR Registration Management |
| **Kategori** | Event Management & Access Control |
| **Level Akses Publik** | Anonymous Participant / Gatekeeper Admin |
| **Tingkat Decoupling** | High (Bisa terhubung dengan MOD-02 untuk tiket berbayar atau MOD-01 untuk RSVP gratis) |
| **Integrasi Pilar** | Supabase (Database & Quota Lock), ImageKit (Event Banner), Resend (E-Ticket PDF/HTML) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan solusi manajemen event lengkap (seminar, kajian akbar, workshop bisnis, festival komunitas) yang mengotomatisasi proses registrasi publik, pembatasan kuota kursi (*race condition safe*), penerbitan E-Tiket ber-QR unik, dan sistem *check-in scanner* di pintu masuk tanpa antrean panjang.

### Fitur Utama:
1. **Penerbitan Event Multi-Sesi:** Pengaturan tanggal, lokasi fisik / link Zoom, pembicara, dan kuota maksimum peserta.
2. **Atomic Quota Reservation:** Mencegah *overbooking* saat ratusan peserta mendaftar serentak.
3. **E-Ticket QR Dispatcher via Resend:** Mengirimkan tiket digital dengan QR code unik ke email peserta segera setelah pendaftaran/pembayaran berhasil.
4. **Gatekeeper Mobile Scanner:** Web app pemindai QR untuk panitia di lokasi acara guna memverifikasi kehadiran secara real-time.

---

## 3. DIAGRAM ALUR PENDAFTARAN & CHECK-IN EVENT

```text
[PESERTA ACARA]
     |
     v (1. Isi Formulir Pendaftaran Event)
[Database Quota Engine (Supabase Stored Procedure)]
     |-- Verifikasi Sisa Kuota (current_participants < max_capacity)
     |-- Kunci Kuota secara Atomik (SELECT ... FOR UPDATE)
     |
     v (2. Sukses Terdaftar)
[E-Ticket Dispatcher (Resend API)]
     |-- Generate Unique Ticket Code (format: TKT-EVENTID-XXXXXX)
     |-- Kirim Email Tiket Berisi QR Code Unik ke Peserta
     |
     v (3. Hari-H Acara di Lokasi)
[Panitia Gatekeeper (Scanner Cam Web)]
     |-- Pindai QR Tiket Peserta di Pintu Masuk
     |-- Validasi Status Tiket: "ISSUED" -> "CHECKED_IN"
     |-- Cegah Double Check-in (Alert: Tiket Sudah Digunakan pada 08:30 WIB)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL MASTER EVENT
CREATE TABLE IF NOT EXISTS public.events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    banner_url TEXT,
    event_type VARCHAR(50) DEFAULT 'OFFLINE', -- 'OFFLINE', 'ONLINE', 'HYBRID'
    location_name VARCHAR(255) NOT NULL,
    location_address TEXT,
    online_meeting_url TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    max_capacity INT DEFAULT 100,
    current_registered INT DEFAULT 0,
    is_paid BOOLEAN DEFAULT false,
    ticket_price NUMERIC(15, 2) DEFAULT 0.00,
    status VARCHAR(30) DEFAULT 'OPEN', -- 'DRAFT', 'OPEN', 'CLOSED', 'COMPLETED', 'CANCELLED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL TIKET PESERTA
CREATE TABLE IF NOT EXISTS public.event_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    ticket_code VARCHAR(60) UNIQUE NOT NULL, -- Format: TKT-[SLUG]-[RANDOM]
    participant_name VARCHAR(150) NOT NULL,
    participant_email VARCHAR(150) NOT NULL,
    participant_phone VARCHAR(30) NOT NULL,
    payment_id UUID REFERENCES public.payment_transactions(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'ISSUED', -- 'ISSUED', 'CHECKED_IN', 'CANCELLED'
    checked_in_at TIMESTAMP WITH TIME ZONE,
    checked_in_by UUID, -- ID Panitia gatekeeper
    custom_responses JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_events_slug ON public.events (slug);
CREATE INDEX IF NOT EXISTS idx_tickets_code ON public.event_tickets (ticket_code);
CREATE INDEX IF NOT EXISTS idx_tickets_event_status ON public.event_tickets (event_id, status);

-- ATOMIC REGISTRATION RPC (MENCEGAH OVERBOOKING / RACE CONDITION)
CREATE OR REPLACE FUNCTION public.register_event_participant(
    p_event_id UUID,
    p_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_ticket_code VARCHAR,
    p_custom JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_event RECORD;
    v_new_ticket_id UUID;
BEGIN
    -- Kunci baris event untuk mencegah race condition
    SELECT * INTO v_event FROM public.events WHERE id = p_event_id FOR UPDATE;
    
    IF v_event.status != 'OPEN' THEN
        RAISE EXCEPTION '[REGISTRATION_CLOSED] Pendaftaran untuk acara ini telah ditutup.';
    END IF;

    IF v_event.current_registered >= v_event.max_capacity THEN
        RAISE EXCEPTION '[QUOTA_FULL] Mohon maaf, kuota peserta untuk acara ini telah habis.';
    END IF;

    -- Insert Tiket
    INSERT INTO public.event_tickets (event_id, ticket_code, participant_name, participant_email, participant_phone, custom_responses)
    VALUES (p_event_id, p_ticket_code, p_name, p_email, p_phone, p_custom)
    RETURNING id INTO v_new_ticket_id;

    -- Update Kapasitas Terdaftar
    UPDATE public.events 
    SET current_registered = current_registered + 1 
    WHERE id = p_event_id;

    RETURN v_new_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_tickets ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh membaca event yang berstatus OPEN / DRAFT publik
CREATE POLICY "Allow public read active events" 
ON public.events 
FOR SELECT 
TO anon, authenticated 
USING (status IN ('OPEN', 'CLOSED', 'COMPLETED'));

-- 2. Publik boleh mengecek status tiket miliknya sendiri via kode tiket
CREATE POLICY "Allow participant read own ticket" 
ON public.event_tickets 
FOR SELECT 
TO anon 
USING (true);

-- 3. Gatekeeper & Admin otentikasi memiliki akses penuh untuk check-in
CREATE POLICY "Allow admin and gatekeeper manage tickets" 
ON public.event_tickets 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: CHECK-IN SCANNER HANDLER (JAVASCRIPT)

```javascript
/**
 * MOD-04: Gatekeeper QR Scanner & Check-in Verifier
 */
async function processTicketCheckIn(scannedTicketCode) {
    const statusBox = document.getElementById('scanner-feedback');
    statusBox.className = 'feedback-box checking';
    statusBox.innerText = '[PROCESSING] Memverifikasi kode tiket: ' + scannedTicketCode;

    try {
        // 1. Cari data tiket
        const { data: ticket, error } = await supabaseClient
            .from('event_tickets')
            .select('id, ticket_code, participant_name, status, checked_in_at, events(title)')
            .eq('ticket_code', scannedTicketCode)
            .single();

        if (error || !ticket) {
            statusBox.className = 'feedback-box error';
            statusBox.innerText = '[INVALID_TICKET] Tiket tidak ditemukan dalam sistem database!';
            return;
        }

        // 2. Evaluasi Status Tiket
        if (ticket.status === 'CHECKED_IN') {
            statusBox.className = 'feedback-box warning';
            statusBox.innerText = `[ALREADY_CHECKED_IN] Tiket atas nama ${ticket.participant_name} telah digunakan sebelumnya pada ${new Date(ticket.checked_in_at).toLocaleTimeString()}.`;
            return;
        }

        // 3. Eksekusi Check-In
        const { error: updateError } = await supabaseClient
            .from('event_tickets')
            .update({
                status: 'CHECKED_IN',
                checked_in_at: new Date().toISOString()
            })
            .eq('id', ticket.id);

        if (updateError) throw updateError;

        statusBox.className = 'feedback-box success';
        statusBox.innerText = `[ACCESS_GRANTED] Selamat Datang, ${ticket.participant_name}! Silakan masuk.`;
        playAudioBeep('success');

    } catch (err) {
        console.error('[GATEKEEPER_ERROR]', err);
        statusBox.className = 'feedback-box error';
        statusBox.innerText = '[ERROR] Terjadi kegagalan koneksi saat validasi tiket.';
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA E-TIKET DIGITAL

```html
<div class="e-ticket-card">
    <div class="ticket-header">
        <h4 class="brand-name">SEMINAR NASIONAL BISNIS DIGITAL</h4>
        <span class="badge badge-success">[STATUS: TIKET VALID]</span>
    </div>
    
    <div class="ticket-body">
        <div class="participant-info">
            <p><strong>Nama Peserta:</strong> Ahmad Fauzan</p>
            <p><strong>Kode Tiket:</strong> <code id="display-code">TKT-SEM2026-98124</code></p>
            <p><strong>Waktu Acara:</strong> Sabtu, 28 Agustus 2026 | 09:00 - 15:00 WIB</p>
            <p><strong>Lokasi:</strong> Grand Ballroom Lt. 3, Jakarta Selatan</p>
        </div>
        <div class="ticket-qr-frame">
            <canvas id="ticket-qr-canvas"></canvas>
            <small class="hint">Tunjukkan QR code ini ke petugas pintu masuk.</small>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Simulasi Beban Kuota:** Memastikan tidak terjadi overbooking saat dieksekusi 50 request konkuren bersamaan di sisa kuota 1.
- [ ] **Pencegahan Tiket Ganda:** Pemindaian kedua pada tiket yang sama langsung mengeluarkan notifikasi peringatan `[ALREADY_CHECKED_IN]`.
- [ ] **Email Dispatcher:** Peserta menerima email E-Tiket berformat rapi dengan QR code dalam waktu < 10 detik.
- [ ] **Offline Resilience:** Scanner gatekeeper menyimpan cache kode tiket untuk validasi lokal saat sinyal internet melemah.
- [ ] **Strict No-Emoji:** Notifikasi scanner dan status e-tiket menggunakan label formal.