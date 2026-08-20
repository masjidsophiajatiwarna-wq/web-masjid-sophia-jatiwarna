# SPESIFIKASI MODUL: DOCUMENT MANAGEMENT & LEGAL E-SIGNATURE
> Kode Modul: `MOD-37` | Versi: `1.0.0` | Kategori: `Produktivitas & Dokumen (REC-20)` | Dependensi: `Supabase, ImageKit, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-37-DOCUMENT-ESIGNATURE-LEGAL` |
| **Nama Modul** | Document Repository & Legal Digital E-Signature Engine |
| **Kategori** | Document Management & Digital Contract Signing |
| **Level Akses Publik** | Signee Client (Tanda Tangan via Token URL) / Legal Officer (Admin) |
| **Tingkat Decoupling** | High (Menangani pengesahan kontrak NDA, SPK proyek, perjanjian vendor) |
| **Integrasi Pilar** | Supabase (Document Audit Hash & Signing Order), Resend (Sign Request Email) |

---

## 2. TUJUAN BISNIS & USE CASE

Menghilangkan kebutuhan tanda tangan basah di atas kertas melalui sistem manajemen dokumen terpusat berizin, alur penandatanganan dokumen legal digital multi-pihak (*Multi-Party E-Signature Workflow: Pihak Pertama -> Pihak Kedua -> Saksi*), verifikasi integritas file berbasis SHA-256 Hash, dan penerbitan sertifikat audit tanda tangan (*Signature Audit Certificate*).

### Fitur Utama:
1. **Multi-Signer Workflow:** Penentuan urutan penandatangan (Pihak 1 dulu, kemudian Pihak 2).
2. **Secure One-Time Signing Link:** Tautan aman yang dikirim ke email penandatangan via Resend.
3. **Canvas Signature & Font Preset:** Pilihan tanda tangan gambar goresan tangan atau tipografi formal.
4. **SHA-256 Tamper-Proof Audit:** Setiap dokumen yang telah ditandatangani dikunci dengan cryptographic hash.

---

## 3. DIAGRAM ALUR PENANDATANGANAN DOKUMEN DIGITAL

```text
[LEGAL OFFICER (doc-composer.html)]
     |
     v (1. Upload PDF Kontrak & Tentukan Posisi TTD Pihak 1 & 2)
[Supabase: public.legal_documents & public.document_signers]
     |-- Hitung SHA-256 Hash Asli Dokumen
     |-- Kirim Email Link Tanda Tangan ke Pihak 1 (Resend API)
     |
     v (2. Pihak 1 Membuka Link & Menandatangani)
[Pihak 1 TTD di Layar]
     |-- Rekam IP Address, Timestamp, dan Gambar TTD
     |-- Status Pihak 1: "SIGNED"
     |-- Trigger Otomatis: Kirim Email Link Tanda Tangan ke Pihak 2
     |
     v (3. Pihak 2 Menandatangani)
[Semua Pihak Telah TTD -> Status Dokumen: "COMPLETED"]
     |-- Gabungkan TTD ke PDF Final & Terbitkan Sertifikat Audit
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL MASTER DOKUMEN LEGAL
CREATE TABLE IF NOT EXISTS public.legal_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_number VARCHAR(60) UNIQUE NOT NULL, -- Format: DOC-YYYYMMDD-XXXX
    title VARCHAR(200) NOT NULL,
    original_file_url TEXT NOT NULL,
    signed_final_file_url TEXT,
    sha256_checksum VARCHAR(64) NOT NULL,
    status VARCHAR(30) DEFAULT 'PENDING', -- 'PENDING', 'PARTIAL_SIGNED', 'COMPLETED', 'DECLINED', 'EXPIRED'
    created_by UUID REFERENCES public.admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL PARA PIHAK PENANDATANGAN (DOCUMENT SIGNERS)
CREATE TABLE IF NOT EXISTS public.document_signers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_id UUID NOT NULL REFERENCES public.legal_documents(id) ON DELETE CASCADE,
    signer_name VARCHAR(150) NOT NULL,
    signer_email VARCHAR(150) NOT NULL,
    signing_order INT NOT NULL DEFAULT 1, -- Urutan 1, 2, 3
    secure_token VARCHAR(100) UNIQUE NOT NULL DEFAULT md5(random()::text || clock_timestamp()::text),
    status VARCHAR(30) DEFAULT 'WAITING', -- 'WAITING', 'INVITED', 'SIGNED', 'DECLINED'
    signature_image_url TEXT,
    ip_address VARCHAR(45),
    signed_at TIMESTAMP WITH TIME ZONE
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_legal_doc_status ON public.legal_documents (status);
CREATE INDEX IF NOT EXISTS idx_signers_token ON public.document_signers (secure_token);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_signers ENABLE ROW LEVEL SECURITY;

-- 1. Penandatangan boleh melihat dan menandatangani dokumen via secure_token
CREATE POLICY "Signers view own document via token" ON public.legal_documents FOR SELECT TO anon USING (true);
CREATE POLICY "Signers update signature via token" ON public.document_signers FOR UPDATE TO anon USING (status = 'INVITED');

-- 2. Legal Staff memiliki kontrol penuh
CREATE POLICY "Allow legal staff manage documents" 
ON public.legal_documents 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: EXECUTE E-SIGN (JAVASCRIPT)

```javascript
/**
 * MOD-37: Sign Document and Advance Workflow
 */
async function executeSignDocument(signerToken, signatureBase64) {
    try {
        const { data, error } = await supabaseClient
            .from('document_signers')
            .update({
                status: 'SIGNED',
                signature_image_url: signatureBase64,
                signed_at: new Date().toISOString()
            })
            .eq('secure_token', signerToken)
            .select()
            .single();

        if (error) throw error;
        showNotification('[SUCCESS] Dokumen berhasil ditandatangani secara sah.', 'success');
    } catch (err) {
        console.error('[SIGN_ERROR]', err);
        showNotification('[ERROR] Gagal memproses tanda tangan digital.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA RUANG TANDA TANGAN

```html
<div class="signing-room-card">
    <div class="doc-header">
        <h3>Perjanjian Kerjasama Layanan (SPK #2026/08/04)</h3>
        <span class="badge badge-info">[STATUS: MENUNGGU TANDA TANGAN ANDA]</span>
    </div>
    <div class="pdf-preview-box">
        <iframe src="https://ik.imagekit.io/brand/kontrak-spk.pdf" width="100%" height="400"></iframe>
    </div>
    <div class="sig-pad-box">
        <label>Bubuhkan Tanda Tangan Anda di Bawah:</label>
        <canvas id="sig-pad" width="400" height="150" class="canvas-border"></canvas>
        <button type="button" class="btn btn-success" onclick="confirmSignature()">Sahkan & Tandatangani</button>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Integritas Alur Berjenjang:** Pihak kedua tidak dapat menandatangani sebelum pihak pertama selesai.
- [ ] **Validasi Hash Dokumen:** Dokumen final yang diunduh memiliki bukti sertifikat hash SHA-256 asli.
- [ ] **Strict No-Emoji:** Status dokumen dan sertifikat legalitas bebas emoji.