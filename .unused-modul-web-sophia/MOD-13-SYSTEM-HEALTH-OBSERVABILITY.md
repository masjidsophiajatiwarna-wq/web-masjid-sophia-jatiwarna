# SPESIFIKASI MODUL: SYSTEM HEALTH, OBSERVABILITY & UPTIME PROBES
> Kode Modul: `MOD-13` | Versi: `1.0.0` | Kategori: `Observability & DevOps (Benchmark Modul E)` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-13-SYSTEM-HEALTH-OBSERVABILITY` |
| **Nama Modul** | System Health, Observability & Uptime Probes Engine |
| **Kategori** | System Monitoring, Diagnostic & SLA Tracking |
| **Level Akses Publik** | Restricted (Admin Sistem / DevOps `authenticated`) |
| **Tingkat Decoupling** | High (Memantau kesehatan infrastruktur 7 pilar secara independen) |
| **Integrasi Pilar** | Supabase (DB Latency Probe), ImageKit (CDN Ping), Resend (API Connection Check) |

---

## 2. TUJUAN BISNIS & USE CASE

Menjamin keandalan (*high availability*) dan kesiapan operasional seluruh layanan eksternal yang menopang web app secara terpusat, mendeteksi gangguan (*downtime / latency spike*) lebih awal sebelum dikeluhkan oleh pengguna, serta menyediakan dashboard status visual.

### Fitur Utama:
1. **Multi-Service Latency Probes:** Pengecekan waktu respon berkala (Database PostgreSQL, CDN ImageKit, Gateway Resend Email).
2. **Badge Status Visual Standar:** Klasifikasi formal `[HEALTHY / OPERATIONAL]`, `[DEGRADED]`, `[DOWN]`.
3. **Database Capacity & Quota Gauge:** Pemantauan persentase penggunaan kuota basis data dan jumlah baris tabel.
4. **Log Riwayat Insiden:** Pencatatan waktu mulai gangguan (*incident start*) hingga pemulihan (*recovery time*).

---

## 3. DIAGRAM ALUR PROBE OBSERVABILITY

```text
[ADMIN MONITOR / CRON WORKER]
     |
     +---> [Probe 1: Supabase DB Ping] ----> Query SELECT 1 -> Catat Latensi (ms)
     |
     +---> [Probe 2: ImageKit CDN Ping] ---> Fetch 1px Test Asset -> Status HTTP 200/404
     |
     +---> [Probe 3: Resend API Ping] -----> Check API Key Auth Endpoint
     |
     v
[Pencatatan Hasil Probe ke public.system_health_logs]
     |-- Evaluasi Ambang Batas:
     |   - Latensi < 250ms  -> [HEALTHY]
     |   - Latensi 250-1000ms -> [DEGRADED]
     |   - Timeout / Error   -> [DOWN]
     |
     v
[Tampilan Admin Panel (system-health.html)]
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL LOG PEMERIKSAAN KESEHATAN SISTEM
CREATE TABLE IF NOT EXISTS public.system_health_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL, -- 'SUPABASE_DB', 'IMAGEKIT_CDN', 'RESEND_EMAIL', 'VERCEL_EDGE'
    status VARCHAR(30) NOT NULL, -- 'HEALTHY', 'DEGRADED', 'DOWN'
    latency_ms INT NOT NULL,
    http_status_code INT,
    error_message TEXT,
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_health_service_time ON public.system_health_logs (service_name, checked_at DESC);

-- STORED PROCEDURE PING DATABASE CEPAT
CREATE OR REPLACE FUNCTION public.check_database_latency()
RETURNS INT AS $$
DECLARE
    t_start TIMESTAMP;
    t_end TIMESTAMP;
BEGIN
    t_start := clock_timestamp();
    PERFORM 1;
    t_end := clock_timestamp();
    RETURN (EXTRACT(MILLISECONDS FROM (t_end - t_start)))::INT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.system_health_logs ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public health access" 
ON public.system_health_logs 
FOR ALL 
TO anon 
USING (false);

-- 2. Khusus Admin Sistem yang berhak membaca dan menulis log
CREATE POLICY "Allow admin manage health logs" 
ON public.system_health_logs 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE is_active = true)
);
```

---

## 6. LOGIKA KLIEN: MULTI-PROBE DISPATCHER (JAVASCRIPT)

```javascript
/**
 * MOD-13: System Observability Prober
 */
async function runSystemDiagnostic() {
    const results = [];

    // 1. Probe Database Supabase
    const dbStart = performance.now();
    try {
        const { data, error } = await supabaseClient.from('admin_users').select('count', { count: 'exact', head: true });
        const dbLatency = Math.round(performance.now() - dbStart);
        results.push({
            service: 'Supabase PostgreSQL',
            status: dbLatency > 800 ? 'DEGRADED' : 'HEALTHY',
            latency: `${dbLatency} ms`
        });
    } catch (err) {
        results.push({ service: 'Supabase PostgreSQL', status: 'DOWN', latency: 'N/A' });
    }

    // 2. Probe CDN ImageKit
    const cdnStart = performance.now();
    try {
        const res = await fetch('https://ik.imagekit.io/[BRAND]/assets/favicon/favicon-16x16.png', { method: 'HEAD' });
        const cdnLatency = Math.round(performance.now() - cdnStart);
        results.push({
            service: 'ImageKit CDN',
            status: res.ok ? 'HEALTHY' : 'DEGRADED',
            latency: `${cdnLatency} ms`
        });
    } catch (err) {
        results.push({ service: 'ImageKit CDN', status: 'DOWN', latency: 'N/A' });
    }

    renderHealthDashboard(results);
}
```

---

## 7. SPESIFIKASI ANTARMUKA STATUS DASHBOARD

```html
<div class="system-health-card">
    <div class="health-header">
        <h3>Status Infrastruktur & Layanan Eksternal</h3>
        <button type="button" class="btn btn-sm" onclick="runSystemDiagnostic()">Jalankan Diagnostik</button>
    </div>

    <div class="service-status-grid">
        <div class="service-row">
            <span class="service-name">Database PostgreSQL (Supabase)</span>
            <span class="latency-val">42 ms</span>
            <span class="badge badge-success">[HEALTHY / OPERATIONAL]</span>
        </div>
        <div class="service-row">
            <span class="service-name">CDN Media & Assets (ImageKit)</span>
            <span class="latency-val">110 ms</span>
            <span class="badge badge-success">[HEALTHY / OPERATIONAL]</span>
        </div>
        <div class="service-row">
            <span class="service-name">Gateway Email Transaksional (Resend)</span>
            <span class="latency-val">185 ms</span>
            <span class="badge badge-success">[HEALTHY / OPERATIONAL]</span>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Timeout Handling:** Layanan yang tidak merespon dalam 3 detik ditandai `[DOWN]` tanpa membekukan halaman dashboard.
- [ ] **Akurasi Pengukuran Latensi:** Waktu respon latensi diukur menggunakan API `performance.now()`.
- [ ] **Pemberitahuan Formal:** Label badge status seragam menggunakan format `[HEALTHY]`, `[DEGRADED]`, `[DOWN]`.
- [ ] **Strict No-Emoji:** Panel observabilitas bebas emoji.