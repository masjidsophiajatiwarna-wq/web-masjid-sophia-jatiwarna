# SPESIFIKASI MODUL: POS RESTAURANT, TABLE MANAGEMENT & KITCHEN DISPLAY (KDS)
> Kode Modul: `MOD-21` | Versi: `1.0.0` | Kategori: `Sales & POS Suite (F&B / REC-04)` | Dependensi: `Supabase Realtime, MOD-20`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-21-POS-RESTAURANT-KITCHEN` |
| **Nama Modul** | POS Restaurant, Floor/Table Management & Kitchen Display System (KDS) |
| **Kategori** | Food & Beverage (F&B) Operations |
| **Level Akses Publik** | Waiter / Cashier / Kitchen Chef (`authenticated`) |
| **Tingkat Decoupling** | High (Ekstensi khusus F&B di atas MOD-20 dan MOD-02) |
| **Integrasi Pilar** | Supabase (PostgreSQL Realtime Subscriptions untuk Kitchen Display) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola operasional restoran, kafe, dan kedai secara terpadu melalui denah tata letak meja makan (*Floor/Table Layout*), pemesanan langsung dari meja oleh pelayan (*Waiter Tablet Ordering*), pengiriman pesanan instan ke layar koki di dapur (*Kitchen Display System - KDS Realtime*), pemisahan tagihan (*Split Bill*), dan penggabungan meja.

### Fitur Utama:
1. **Visual Floor & Table Map:** Denah meja interaktif dengan indikator warna status (`KOSONG`, `TERISI`, `TAGIHAN_DICETAK`).
2. **Real-time Kitchen Display System (KDS):** Layar dapur yang berbunyi dan memperbarui antrean masak otomatis tanpa kertas tiket.
3. **Menu Modifiers & Notes:** Catatan khusus memasak (misal: "Pedas Sedang, Tanpa Bawang, Es Sedikit").
4. **Split Bill & Merge Table:** Fitur fleksibel untuk membagi tagihan per orang atau menggabungkan grup meja.

---

## 3. DIAGRAM ALUR PESANAN RESTORAN & KDS REALTIME

```text
[PELAYAN / WAITER TABLET]
     |
     v (1. Pilih Meja: Meja #05 -> Input Pesanan Makanan & Minuman)
[Supabase: public.restaurant_orders & public.kitchen_tickets]
     |-- Status Meja diubah: "OCCUPIED"
     |
     v (2. Broadcast Realtime via Supabase WebSocket)
[LAYAR DAPUR / KDS (kitchen-display.html)]
     |-- Muncul Tiket Pesanan Baru: Meja #05 (Bunyi Notifikasi Beep)
     |-- Koki menekan tombol "MULAI MASAK" -> Status: "COOKING"
     |-- Koki menekan tombol "SIAP SAJI"   -> Status: "READY_TO_SERVE"
     |
     v (3. Pelanggan Membayar di Kasir)
[Kasir POS (MOD-20 / MOD-02)]
     |-- Cetak Bill / Split Bill -> Bayar Tunai / QRIS
     |-- Status Meja kembali: "AVAILABLE"
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL DENAH MEJA RESTORAN (RESTAURANT TABLES)
CREATE TABLE IF NOT EXISTS public.restaurant_tables (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    table_number VARCHAR(20) UNIQUE NOT NULL, -- Contoh: 'T-01', 'VIP-02'
    floor_zone VARCHAR(50) DEFAULT 'INDOOR', -- 'INDOOR', 'OUTDOOR', 'VIP', 'ROOFTOP'
    capacity INT DEFAULT 4,
    status VARCHAR(30) DEFAULT 'AVAILABLE', -- 'AVAILABLE', 'OCCUPIED', 'RESERVED', 'BILL_PRINTED'
    current_order_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL TIKET MASAK DAPUR (KITCHEN TICKETS)
CREATE TABLE IF NOT EXISTS public.kitchen_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_number VARCHAR(60) UNIQUE NOT NULL, -- Format: KDN-YYYYMMDD-XXXX
    table_id UUID NOT NULL REFERENCES public.restaurant_tables(id),
    order_id UUID NOT NULL REFERENCES public.pos_orders(id) ON DELETE CASCADE,
    item_name VARCHAR(200) NOT NULL,
    quantity INT NOT NULL,
    cooking_notes TEXT, -- 'Pedas level 3, kuah dipisah'
    status VARCHAR(30) DEFAULT 'QUEUED', -- 'QUEUED', 'COOKING', 'READY', 'SERVED'
    started_cooking_at TIMESTAMP WITH TIME ZONE,
    ready_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_kds_status ON public.kitchen_tickets (status);
CREATE INDEX IF NOT EXISTS idx_tables_zone ON public.restaurant_tables (floor_zone, status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.restaurant_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kitchen_tickets ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public resto access" ON public.restaurant_tables FOR ALL TO anon USING (false);

-- 2. Staf Resto & Dapur memiliki izin kelola
CREATE POLICY "Allow resto staff manage tables" 
ON public.restaurant_tables 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);

CREATE POLICY "Allow kitchen staff manage tickets" 
ON public.kitchen_tickets 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: KDS REALTIME SUBSCRIPTION (JAVASCRIPT)

```javascript
/**
 * MOD-21: Realtime Kitchen Display System Listener
 */
function initKitchenRealtimeFeed() {
    supabaseClient
        .channel('kitchen_orders_feed')
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'kitchen_tickets'
        }, (payload) => {
            console.log('[KDS_NEW_ORDER]', payload.new);
            appendKitchenTicketCard(payload.new);
            playAudioBeep('kitchen-bell');
        })
        .subscribe();
}

async function markItemReady(ticketId) {
    const { error } = await supabaseClient
        .from('kitchen_tickets')
        .update({
            status: 'READY',
            ready_at: new Date().toISOString()
        })
        .eq('id', ticketId);

    if (error) {
        showNotification('[ERROR] Gagal mengupdate status masakan.', 'error');
    } else {
        removeCardFromKDS(ticketId);
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA KITCHEN DISPLAY (KDS)

```html
<div class="kds-screen">
    <div class="kds-header">
        <h3>Layar Antrean Pesanan Dapur (KDS)</h3>
        <span class="badge badge-success">[STATUS: REALTIME AKTIF]</span>
    </div>

    <div class="kds-ticket-grid" id="kds-grid">
        <!-- Card Tiket Dapur -->
        <div class="kds-ticket-card" id="ticket-uuid-1">
            <div class="ticket-top">
                <span class="table-badge">MEJA #05</span>
                <span class="timer-badge">04:12 Min</span>
            </div>
            <div class="ticket-items">
                <p><strong>2x</strong> Nasi Goreng Spesial</p>
                <small class="notes">Catatan: Pedas sedang, tanpa acar</small>
                <p><strong>1x</strong> Ayam Bakar Madu</p>
            </div>
            <button type="button" class="btn btn-success btn-block" onclick="markItemReady('uuid-1')">Pesanan Siap Saji</button>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Sinkronisasi Realtime:** Pesanan dari tablet pelayan muncul di layar dapur dalam waktu < 1 detik.
- [ ] **Indikator Meja:** Meja otomatis berganti warna status saat ada transaksi aktif dan kembali hijau setelah dibayar.
- [ ] **Split Bill Accuracy:** Pembagian pembayaran terpisah menghasilkan total yang tepat sama dengan nilai pesanan induk.
- [ ] **Strict No-Emoji:** Status tiket dapur dan antarmuka denah meja bebas emoji.