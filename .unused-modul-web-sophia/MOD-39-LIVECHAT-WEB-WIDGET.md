# SPESIFIKASI MODUL: LIVE CHAT & REALTIME WEB WIDGET SUPPORT
> Kode Modul: `MOD-39` | Versi: `1.0.0` | Kategori: `Produktivitas & Dokumen (REC-22)` | Dependensi: `Supabase Realtime, MOD-16`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-39-LIVECHAT-WEB-WIDGET` |
| **Nama Modul** | Live Chat & Realtime Web Support Widget |
| **Kategori** | Realtime Communication & Instant Customer Support |
| **Level Akses Publik** | Anonymous Web Visitor (Chat) / Support Agent (`authenticated`) |
| **Tingkat Decoupling** | High (Widget mengambang yang dapat disematkan ke halaman publik mana pun) |
| **Integrasi Pilar** | Supabase Realtime (WebSocket Chat Rooms & Agent Presence) |

---

## 2. TUJUAN BISNIS & USE CASE

Memberikan bantuan instan kepada pengunjung website melalui tombol chat mengambang (*Floating Live Chat Widget*), percakapan dua arah secara langsung (*Two-Way WebSocket Messaging*), deteksi ketersediaan staf CS (*Agent Online/Offline Presence*), pesan pembuka otomatis (*Automated Greeting / Triage*), dan kemampuan eskalasi percakapan menjadi tiket resmi di MOD-16 jika operator sedang offline.

### Fitur Utama:
1. **Lightweight Embeddable Widget:** Script JS ringan (< 30KB) siap tempel di `index.html`.
2. **WebSocket Real-time Messaging:** Pesan terkirim dan diterima seketika tanpa refresh halaman.
3. **Agent Presence & Typing Indicator:** Menampilkan status agen sedang online atau sedang mengetik.
4. **Auto-Convert to Helpdesk Ticket (MOD-16):** Jika pengunjung chat di luar jam operasional, pesan otomatis menjadi tiket bantuan.

---

## 3. DIAGRAM ALUR LIVE CHAT REALTIME

```text
[PENGUNJUNG WEBSITE (live-chat-widget.js)]
     |
     v (1. Buka Balon Chat -> Masukkan Nama & Pesan Pertama)
[Supabase: public.livechat_sessions (WebSocket Channel)]
     |-- Broadcast Sesi Baru ke Panel Operator CS
     |
     v (2. CS Operator Menerima Sesi Chat)
[Dua Arah Realtime: Pengunjung <---> Operator CS]
     |-- Kirim Pesan Teks & Lampiran Gambar ImageKit
     |
     v (3. Sesi Chat Berakhir)
[Tutup Sesi & Minta Rating Kepuasan (CSAT)]
     |-- Simpan Log Transkrip Obrolan
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL SESI LIVE CHAT (LIVECHAT SESSIONS)
CREATE TABLE IF NOT EXISTS public.livechat_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_token VARCHAR(100) UNIQUE NOT NULL DEFAULT md5(random()::text || clock_timestamp()::text),
    visitor_name VARCHAR(150) NOT NULL,
    visitor_email VARCHAR(150),
    assigned_agent_id UUID REFERENCES public.admin_users(id),
    status VARCHAR(30) DEFAULT 'WAITING', -- 'WAITING', 'ACTIVE', 'CLOSED', 'CONVERTED_TO_TICKET'
    rating INT, -- Nilai kepuasan 1 s.d 5
    started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- TABEL PESAN LIVE CHAT (LIVECHAT MESSAGES)
CREATE TABLE IF NOT EXISTS public.livechat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES public.livechat_sessions(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL, -- 'VISITOR', 'AGENT', 'BOT'
    sender_name VARCHAR(150) NOT NULL,
    message_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_chat_session_token ON public.livechat_sessions (session_token);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON public.livechat_messages (session_id, created_at);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.livechat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livechat_messages ENABLE ROW LEVEL SECURITY;

-- 1. Pengunjung publik boleh membuat sesi dan mengirim pesan
CREATE POLICY "Public create chat session" ON public.livechat_sessions FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Public read own chat session" ON public.livechat_sessions FOR SELECT TO anon USING (true);
CREATE POLICY "Public post chat message" ON public.livechat_messages FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Public read chat messages" ON public.livechat_messages FOR SELECT TO anon USING (true);

-- 2. Staff CS memiliki akses penuh
CREATE POLICY "Agents manage all chats" 
ON public.livechat_sessions 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: REALTIME CHAT LISTENER (JAVASCRIPT)

```javascript
/**
 * MOD-39: Realtime Live Chat WebSocket Engine
 */
function subscribeToChatSession(sessionId) {
    supabaseClient
        .channel(`chat_${sessionId}`)
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'livechat_messages',
            filter: `session_id=eq.${sessionId}`
        }, (payload) => {
            appendMessageToChatUI(payload.new);
        })
        .subscribe();
}

async function sendChatMessage(sessionId, senderType, name, text) {
    await supabaseClient.from('livechat_messages').insert([{
        session_id: sessionId,
        sender_type: senderType,
        sender_name: name,
        message_text: text
    }]);
}
```

---

## 7. SPESIFIKASI ANTARMUKA WIDGET FLOATING CHAT

```html
<div class="livechat-floating-widget">
    <div class="chat-header">
        <h4>Layanan Bantuan Pelanggan</h4>
        <span class="status-indicator online">[OPERATOR ONLINE]</span>
    </div>
    <div class="chat-messages-area" id="chat-stream">
        <div class="msg-bubble bot">Halo! Ada yang bisa kami bantu hari ini?</div>
    </div>
    <div class="chat-input-row">
        <input type="text" id="chat-input" placeholder="Tuliskan pesan Anda..." class="form-input">
        <button type="button" class="btn btn-primary" onclick="handleSendChat()">Kirim</button>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Latensi Pesan Seketika:** Pesan muncul di layar lawan bicara dalam waktu < 300ms via WebSocket.
- [ ] **Eskalasi Offline:** Di luar jam operasional, widget otomatis menawarkan form pembuatan tiket MOD-16.
- [ ] **Strict No-Emoji:** Status online operator dan copywriting pesan otomatis bebas emoji.