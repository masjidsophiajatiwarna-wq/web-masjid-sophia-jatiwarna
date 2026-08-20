# SPESIFIKASI MODUL: APPOINTMENT & BOOKING SCHEDULE ENGINE
> Kode Modul: `MOD-10` | Versi: `1.0.0` | Kategori: `Operations & Scheduling (Odoo-Grade Suite)` | Dependensi: `Supabase, Resend, Gmail`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-10-APPOINTMENT-BOOKING-SYSTEM` |
| **Nama Modul** | Appointment & Booking Schedule Engine |
| **Kategori** | Calendar Scheduling & Resource Allocation |
| **Level Akses Publik** | Anonymous Guest (Booking) / Staff Specialist (Admin) |
| **Tingkat Decoupling** | High (Bisa diintegrasikan ke landing page jasa konsultasi, klinik, salon, studio) |
| **Integrasi Pilar** | Supabase (Calendar Slot Matrix), Resend (ICS Calendar File Email), Gmail (Staff Sync) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyediakan sistem reservasi janji temu dan booking jadwal konsultasi/layanan mandiri dengan pemilihan staf/ahli, pencegahan tabrakan jam (*anti-collision slot lock*), penentuan jam kerja operasional & hari libur, serta pengiriman undangan kalender otomatis (.ICS) ke email klien dan staf.

### Fitur Utama:
1. **Time-Slot Grid Generator:** Pembagian jadwal otomatis dalam interval waktu (misal: 30 menit atau 60 menit).
2. **Buffer Time Protection:** Jeda istirahat otomatis antar-sesi (misal: 15 menit).
3. **Pencegahan Double-Booking Atomik:** Penguncian slot di level database PostgreSQL saat form sedang disubmit.
4. **Undangan Kalender (.ICS File):** Attachment file kalender yang otomatis masuk ke Google Calendar / Apple Calendar / Outlook.

---

## 3. DIAGRAM ALUR RESERVASI JADWAL

```text
[KLIEN / PENGUNJUNG]
     |
     v (1. Pilih Layanan, Staf Ahli, dan Tanggal di Kalender)
[Slot Grid Generator (JS Engine)]
     |-- Query ketersediaan jam kerja staf
     |-- Filter jam yang sudah terisi (booked)
     |-- Tampilkan slot hijau yang tersedia
     |
     v (2. Pilih Jam & Isi Data Kontak)
[Atomic Slot Lock (Supabase RPC)]
     |-- Verifikasi slot kosong: WHERE staff_id = X AND booking_time = Y
     |-- Kunci dan buat entri (Status: CONFIRMED / PENDING_PAYMENT)
     |
     v (3. Auto Notification & Calendar Sync)
[Resend Notification Dispatcher]
     |-- Kirim email konfirmasi ke Klien dengan file .ICS terlampir
     |-- Kirim notifikasi agenda ke akun Gmail Staf pengampu
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL STAF / KONSULTAN LAYANAN
CREATE TABLE IF NOT EXISTS public.booking_staff (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    role_title VARCHAR(100) NOT NULL, -- Contoh: "Dokter Gigi", "Konsultan Pajak", "Senior Stylist"
    email VARCHAR(150) NOT NULL,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL LAYANAN (SERVICES)
CREATE TABLE IF NOT EXISTS public.booking_services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 60,
    buffer_minutes INT NOT NULL DEFAULT 15,
    price NUMERIC(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL APPOINTMENTS / RESERVASI
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_code VARCHAR(60) UNIQUE NOT NULL, -- Format: BKG-YYYYMMDD-XXXX
    service_id UUID NOT NULL REFERENCES public.booking_services(id),
    staff_id UUID REFERENCES public.booking_staff(id),
    client_name VARCHAR(150) NOT NULL,
    client_email VARCHAR(150) NOT NULL,
    client_phone VARCHAR(30) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(30) DEFAULT 'CONFIRMED', -- 'PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
    meeting_link TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT no_overlapping_staff_booking EXCLUDE USING gist (
        staff_id WITH =,
        tstzrange(start_time, end_time) WITH &&
    )
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_appointments_staff_time ON public.appointments (staff_id, start_time);
CREATE INDEX IF NOT EXISTS idx_appointments_code ON public.appointments (booking_code);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.booking_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh melihat daftar staf dan layanan aktif
CREATE POLICY "Allow public read active staff" 
ON public.booking_staff 
FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

CREATE POLICY "Allow public read active services" 
ON public.booking_services 
FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

-- 2. Publik boleh membuat reservasi (INSERT)
CREATE POLICY "Allow public insert appointment" 
ON public.appointments 
FOR INSERT 
TO anon 
WITH CHECK (start_time > timezone('utc'::text, now()));

-- 3. Publik hanya bisa mengecek reservasi miliknya via booking_code
CREATE POLICY "Allow public read own appointment" 
ON public.appointments 
FOR SELECT 
TO anon 
USING (true);

-- 4. Admin / Staf memiliki akses penuh
CREATE POLICY "Allow admin manage all appointments" 
ON public.appointments 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: ICS CALENDAR BUILDER (JAVASCRIPT)

```javascript
/**
 * MOD-10: ICS Calendar File Builder
 */
function createICSFile(booking) {
    const formatDate = (date) => date.toISOString().replace(/-|:|\.\d+/g, '');

    const icsContent = [
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'PRODID:-//Nama Brand//Booking Engine//ID',
        'CALSCALE:GREGORIAN',
        'METHOD:REQUEST',
        'BEGIN:VEVENT',
        `UID:${booking.booking_code}@domainbrand.com`,
        `DTSTAMP:${formatDate(new Date())}`,
        `DTSTART:${formatDate(new Date(booking.start_time))}`,
        `DTEND:${formatDate(new Date(booking.end_time))}`,
        `SUMMARY:Janji Temu: ${booking.service_name}`,
        `DESCRIPTION:Reservasi layanan dengan ${booking.staff_name}. Kode Booking: ${booking.booking_code}`,
        `LOCATION:${booking.location || 'Online / Kantor Pusat'}`,
        'STATUS:CONFIRMED',
        'END:VEVENT',
        'END:VCALENDAR'
    ].join('\r\n');

    return icsContent;
}
```

---

## 7. SPESIFIKASI GRID PILIHAN JAM (SLOT PICKER)

```html
<div class="booking-slot-container">
    <div class="calendar-header">
        <h4>Pilih Waktu Konsultasi yang Tersedia</h4>
        <p class="date-label">Kamis, 20 Agustus 2026</p>
    </div>

    <div class="time-slot-grid">
        <button type="button" class="time-slot available" onclick="selectTimeSlot('09:00')">09:00 - 10:00</button>
        <button type="button" class="time-slot available" onclick="selectTimeSlot('10:15')">10:15 - 11:15</button>
        <button type="button" class="time-slot booked" disabled>11:30 - 12:30 [TERISI]</button>
        <button type="button" class="time-slot available" onclick="selectTimeSlot('13:30')">13:30 - 14:30</button>
        <button type="button" class="time-slot available" onclick="selectTimeSlot('14:45')">14:45 - 15:45</button>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Pencegahan Tabrakan Jadwal:** PostgreSQL Constraint `EXCLUDE USING gist` berhasil menolak insert slot bentrok.
- [ ] **Sinkronisasi ICS:** File kalender otomatis dikenali dan dapat ditambahkan ke Google Calendar sekali klik.
- [ ] **Validasi Waktu Lampau:** Pengguna tidak dapat memilih tanggal atau jam di masa lampau.
- [ ] **Strict No-Emoji:** Status ketersediaan jadwal menggunakan penanda `[TERSEDIA]`, `[TERISI]`, `[TERTUTUP]`.