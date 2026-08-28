# API CONTRACT & BACKEND SPECIFICATION (v1.0.0)

> **Ekosistem Web Portal Masjid Musafir Sophia Jatiwarna**  
> Standar Kontrak Endpoint Serverless (Vercel Node.js), Skema Request/Response, dan Isolasi Database Mutlak.

---

## 1. ISOLASI TARGET SUPABASE (HARD PROJECT BOUNDARY)

Seluruh endpoint API dan pemanggilan alat MCP di repositori ini terikat secara absolut pada konfigurasi Supabase berikut:

| Parameter | Nilai Resmi Produksi |
| :--- | :--- |
| **Supabase Project ID** | `fcwajbemkbhkogwtqcmx` |
| **Supabase Project URL** | `https://fcwajbemkbhkogwtqcmx.supabase.co` |
| **Active MCP Server** | `supabase-masjid-sophia` |
| **Restricted/Forbidden MCP** | `supabase-siabe` (`znqstcnlykgsfzfdiltm`) & Proyek Lainnya |

> **PERINGATAN OPERASIONAL:**  
> Dilarang keras mengarahkan permintaan API, migrasi SQL, atau pemanggilan MCP ke selain Project ID `fcwajbemkbhkogwtqcmx` saat bekerja di repositori ini.

---

## 2. FORMAT ENVELOPE STANDAR (STANDARD RESPONSE FORMAT)

Semua respons API mengadopsi struktur envelope JSON yang konsisten:

### Respons Sukses (HTTP 200 / 201)
```json
{
  "success": true,
  "message": "Deskripsi sukses yang jelas dan ramah pengguna",
  "data": { ... }
}
```

### Respons Gagal / Validasi (HTTP 400 / 405 / 500)
```json
{
  "success": false,
  "message": "Penjelasan penyebab kegagalan dan solusi bagi pengguna",
  "details": { ... }
}
```

---

## 3. KATALOG ENDPOINT SERVERLESS (/api/)

---

### Endpoint 1: Ingestion Donasi & Sedekah Makan

* **Path:** `/api/donasi`
* **Method:** `POST`
* **CORS:** `Access-Control-Allow-Origin: *`
* **Deskripsi:** Menerima input donasi publik (Sedekah Makan Dzuhur, Santri Tahfidz, Kas Umum) dan menyimpannya ke tabel `public.donations` dengan 3-digit kode unik verifikasi otomatis.

#### Request Headers:
```http
Content-Type: application/json
```

#### Request Payload:
```json
{
  "donor_name": "Ahmad Fauzi",
  "email": "ahmad@example.com",
  "phone_number": "+6281234567890",
  "program_category": "Makan Berjamaah Gratis",
  "amount": 50000,
  "payment_method": "QRIS",
  "prayer_notes": "Semoga berkah untuk para musafir",
  "is_incognito": false
}
```

#### Field Validation Rules:
* `amount`: Numeric, Wajib, min: `1000`.
* `phone_number`: String, Wajib (format WhatsApp).
* `is_incognito`: Boolean, Opsional (jika `true`, `donor_name` otomatis disamarkan menjadi `Hamba Allah`).

#### Response Success (HTTP 200):
```json
{
  "success": true,
  "message": "Donasi berhasil dicatat. Silakan selesaikan pembayaran.",
  "data": {
    "id": "uuid-v4",
    "donor_name": "Ahmad Fauzi",
    "amount": 50000,
    "unique_code": 345,
    "total_amount": 50345,
    "payment_status": "PENDING",
    "created_at": "2026-08-29T06:00:00.000Z"
  }
}
```

---

### Endpoint 2: Pusat Pengaduan & Aspirasi Jamaah

* **Path:** `/api/pengaduan`
* **Method:** `POST`
* **Deskripsi:** Menampung kotak saran, keluhan fasilitas, dan aspirasi musafir, menyimpannya ke `public.feedback_complaints`, serta meneruskan notifikasi instan ke email DKM via Resend.

#### Request Payload:
```json
{
  "sender_name": "Budi Santoso",
  "email": "budi@example.com",
  "phone_number": "+6281298765432",
  "category": "Fasilitas & Kebersihan",
  "subject": "Dispenser Air Minum Musafir",
  "message": "Mohon ditambahkan stok gelas kertas di area dispenser musafir samping aula."
}
```

#### Response Success (HTTP 200):
```json
{
  "success": true,
  "message": "Terima kasih, pesan/saran Anda telah berhasil dikirimkan ke Pengurus DKM."
}
```

---

### Endpoint 3: System Health & Storage Monitor

* **Path:** `/api/health`
* **Method:** `GET`
* **Deskripsi:** Memeriksa latensi PostgreSQL Supabase `fcwajbemkbhkogwtqcmx`, ketersediaan CDN ImageKit, dan status serverless Vercel.

#### Response Success (HTTP 200):
```json
{
  "timestamp": "2026-08-29T06:00:00.000Z",
  "overall_status": "HEALTHY",
  "environment": "production",
  "services": {
    "vercel_edge": { "status": "HEALTHY", "region": "sin1", "runtime": "Node.js Edge / Serverless" },
    "supabase_db": { "status": "HEALTHY", "project_ref": "fcwajbemkbhkogwtqcmx", "latency_ms": 12 },
    "imagekit_cdn": { "status": "HEALTHY", "storage_limit_gb": 20.0, "estimated_used_gb": 0.25 },
    "resend_email": { "status": "HEALTHY", "rate_limit": "100 emails/day (Free Tier)" }
  },
  "latency_total_ms": 15
}
```

---

### Endpoint 4: Pengiriman Kuitansi Donasi Instan

* **Path:** `/api/send-receipt`
* **Method:** `POST`
* **Deskripsi:** Menghasilkan kuitansi HTML bertema resmi Sophia Gold (`#C9A84C`) dan mengirimkannya ke email donatur via Resend API.

#### Request Payload:
```json
{
  "donation_id": "DSP-1787956910",
  "donor_name": "Ahmad Fauzi",
  "email": "ahmad@example.com",
  "program_category": "Makan Berjamaah Gratis",
  "amount": 50000,
  "total_amount": 50345,
  "payment_method": "QRIS",
  "date": "29 Agustus 2026"
}
```

#### Response Success (HTTP 200):
```json
{
  "success": true,
  "message": "Email kuitansi donasi berhasil dikirim.",
  "email_id": "resend_msg_id_12345"
}
```

---

### Endpoint 5: Multi-Cloud Free-Tier Usage Monitor

* **Path:** `/api/cloud-usage`
* **Method:** `GET`
* **Deskripsi:** Agregator pemantauan kapasitas 7 pilar gratis (Supabase, Vercel, ImageKit, Resend, GitHub, Cloudflare, Google Drive) untuk dashboard Super Admin.

#### Response Success (HTTP 200):
```json
{
  "timestamp": "2026-08-29T06:00:00.000Z",
  "success": true,
  "summary": {
    "monthly_bill_idr": 0,
    "status_text": "ALL SAFE (7/7)",
    "total_db_records": 467,
    "est_db_size_mb": 2.70,
    "registered_users": 11,
    "email_quota_monthly": 3000,
    "email_sender": "info@masjidsophiajatiwarna.com"
  },
  "pillars": {
    "supabase": { "status": "SAFE", "db_size_mb": 2.70, "db_size_limit_mb": 500 },
    "resend": { "status": "SAFE", "monthly_quota": 3000, "daily_limit": 100 },
    "vercel": { "status": "SAFE", "bandwidth_limit_gb": 100 },
    "imagekit": { "status": "SAFE", "storage_limit_gb": 20 },
    "github": { "status": "SAFE", "cicd_minutes_limit": 2000 },
    "cloudflare": { "status": "SAFE", "security_level": "Bot Fight Mode Active" },
    "gdrive": { "status": "SAFE", "storage_limit_gb": 15 }
  }
}
```
