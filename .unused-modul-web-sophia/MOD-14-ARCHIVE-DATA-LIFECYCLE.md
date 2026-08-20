# SPESIFIKASI MODUL: ARCHIVE PROJECT & COLD STORAGE LIFECYCLE
> Kode Modul: `MOD-14` | Versi: `1.0.0` | Kategori: `Data Lifecycle & Governance (Benchmark Modul F)` | Dependensi: `Supabase, Google Drive`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-14-ARCHIVE-DATA-LIFECYCLE` |
| **Nama Modul** | Archive Project & Cold Storage Lifecycle Manager |
| **Kategori** | Data Retention, Archival & Cold Storage |
| **Level Akses Publik** | Restricted (Super Admin & Automated Service Worker) |
| **Tingkat Decoupling** | High (Menangani siklus akhir data dari seluruh modul database) |
| **Integrasi Pilar** | Supabase (PostgreSQL Archival Flag), Google Drive (Cold Storage API) |

---

## 2. TUJUAN BISNIS & USE CASE

Menjaga performa kecepatan database produksi (*hot storage*) tetap optimal dan menghemat biaya kapasitas dengan cara memindahkan data transaksi lama (> 1 tahun) yang jarang diakses ke penyimpanan dingin (*cold storage*) di Google Drive dalam format NDJSON/CSV terkompresi, dengan opsi pemulihan (*restore*) jika dibutuhkan untuk audit hukum/pajak.

### Fitur Utama:
1. **Soft Delete & Archival Flag:** Menyembunyikan data kadaluarsa dari pencarian harian tanpa menghapus data secara permanen.
2. **Cold Storage Exporter (NDJSON/CSV):** Mengekspor batch ribuan baris data ke file terkompresi.
3. **Google Drive Integration (Service Account):** Upload otomatis ke folder arsip tahunan Google Drive (`/Arsip-Tahun-2025/`).
4. **Restore Endpoint:** Mengimpor kembali data arsip dingin ke database jika ada keperluan audit forensik.

---

## 3. DIAGRAM ALUR SIKLUS HIDUP DATA (DATA RETENTION)

```text
[DATA TRANSAKSI DALAM DATABASE]
     |
     v (Kriteria: created_at < NOW() - INTERVAL '1 year')
[Batch Worker / Scheduled Edge Function]
     |-- 1. Beri Flag: is_archived = true
     |-- 2. Dump data lama ke format NDJSON (Newline Delimited JSON)
     |
     v (Simpan ke Penyimpanan Dingin)
[Google Drive Service Account]
     |-- Upload file ke /Backup-Arsip/2025-Q4-archive.ndjson.gz
     |-- Catat ID File Google Drive ke tabel public.archival_logs
     |
     v (Opsional: Bersihkan Baris Database Hot Storage)
[Purge Database Hot Records]
     |-- DELETE FROM public.form_submissions WHERE is_archived = true AND archived_to_gdrive = true
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL LOG PENGARSIPAN
CREATE TABLE IF NOT EXISTS public.archival_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    source_table VARCHAR(100) NOT NULL, -- Contoh: 'form_submissions', 'payment_transactions'
    record_count INT NOT NULL,
    date_range_start TIMESTAMP WITH TIME ZONE NOT NULL,
    date_range_end TIMESTAMP WITH TIME ZONE NOT NULL,
    gdrive_file_id VARCHAR(150) NOT NULL,
    gdrive_file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    checksum_md5 VARCHAR(32) NOT NULL,
    executed_by UUID REFERENCES public.admin_users(id),
    status VARCHAR(30) DEFAULT 'COMPLETED', -- 'PROCESSING', 'COMPLETED', 'FAILED', 'RESTORED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- STORED PROCEDURE MARK DATA UNTUK DIARSIPKAN
CREATE OR REPLACE FUNCTION public.flag_records_for_archival(
    p_table_name VARCHAR,
    p_older_than INTERVAL
)
RETURNS INT AS $$
DECLARE
    v_affected INT;
BEGIN
    EXECUTE format(
        'UPDATE public.%I SET is_archived = true WHERE is_archived = false AND created_at < NOW() - $1',
        p_table_name
    ) USING p_older_than;
    GET DIAGNOSTICS v_affected = ROW_COUNT;
    RETURN v_affected;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.archival_logs ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik ke data log arsip
CREATE POLICY "Deny public archival access" 
ON public.archival_logs 
FOR ALL 
TO anon 
USING (false);

-- 2. Hanya Super Admin / Service Role yang diizinkan mengelola arsip
CREATE POLICY "Allow super admin manage archival" 
ON public.archival_logs 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    auth.jwt() ->> 'email' IN (SELECT email FROM public.admin_users WHERE role = 'SUPERADMIN' AND is_active = true)
);
```

---

## 6. LOGIKA KLIEN: EKSPOR ARSIP NDJSON (JAVASCRIPT)

```javascript
/**
 * MOD-14: NDJSON Cold Storage Serializer
 */
function serializeToNDJSON(recordsArray) {
    return recordsArray
        .map(record => JSON.stringify(record))
        .join('\n');
}

// Download file arsip NDJSON secara lokal atau kirim ke Google Drive API
function downloadArchiveFile(dataRows, tableName) {
    const ndjsonContent = serializeToNDJSON(dataRows);
    const blob = new Blob([ndjsonContent], { type: 'application/x-ndjson;charset=utf-8;' });
    const filename = `archive_${tableName}_${new Date().toISOString().slice(0,10)}.ndjson`;

    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
    showNotification(`[SUCCESS] Berkas arsip ${filename} berhasil diunduh.`, 'success');
}
```

---

## 7. SPESIFIKASI ANTARMUKA PANEL ARSIP DATA

```html
<div class="archive-manager-card">
    <div class="card-header">
        <h3>Pengelolaan Arsip & Retensi Data (Cold Storage)</h3>
        <span class="badge badge-info">[RETENSI AKTIF: > 365 HARI]</span>
    </div>

    <div class="archive-actions-grid">
        <div class="action-box">
            <h4>Arsipkan Data Formulir Lama</h4>
            <p>Pindahkan 1.240 data formulir tahun 2025 ke Google Drive.</p>
            <button type="button" class="btn btn-warning" onclick="triggerArchival('form_submissions')">Mulai Pengarsipan</button>
        </div>
        <div class="action-box">
            <h4>Arsipkan Riwayat Transaksi Lama</h4>
            <p>Pindahkan 850 transaksi lunas tahun 2025 ke Google Drive.</p>
            <button type="button" class="btn btn-warning" onclick="triggerArchival('payment_transactions')">Mulai Pengarsipan</button>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Validasi Integritas Checksum:** MD5 hash file arsip di Google Drive sama persis dengan data aslinya.
- [ ] **Data Retention Safety:** Data yang berumur < 1 tahun tidak dapat ditandai arsip secara tidak sengaja.
- [ ] **Simulasi Pemulihan (Restore):** File NDJSON hasil ekspor dapat di-parse dan dimasukkan kembali tanpa error format.
- [ ] **Strict No-Emoji:** Label status dan notifikasi pengarsipan menggunakan format baku.