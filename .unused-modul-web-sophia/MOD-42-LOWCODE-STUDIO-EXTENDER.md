# SPESIFIKASI MODUL: LOW-CODE STUDIO & DYNAMIC SCHEMA EXTENDER
> Kode Modul: `MOD-42` | Versi: `1.0.0` | Kategori: `Kustomisasi & Integrasi (REC-25)` | Dependensi: `Supabase, PostgreSQL JSONB`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-42-LOWCODE-STUDIO-EXTENDER` |
| **Nama Modul** | Low-Code Studio, Dynamic Schema Extender & Custom View Builder |
| **Kategori** | Developer Tools, Schema Extensibility & Low-Code Admin |
| **Level Akses Publik** | Restricted (Superadmin / System Architect `authenticated`) |
| **Tingkat Decoupling** | Core Extender (Menambah atribut dinamis pada modul MOD-01 s.d. MOD-41) |
| **Integrasi Pilar** | Supabase (PostgreSQL Dynamic JSONB & Schema Catalog) |

---

## 2. TUJUAN BISNIS & USE CASE

Mempercepat kustomisasi spesifik brand baru tanpa perlu mengubah kode sumber atau melakukan *deploy* ulang (*zero-code schema extension*), melalui antarmuka visual admin untuk menambahkan kolom kustom (*Custom Fields: Text, Number, Dropdown, Date, Toggle*), perancangan tata letak formulir (*Dynamic Form Layout Builder*), dan pembuatan aturan validasi data mandiri.

### Fitur Utama:
1. **Visual Custom Field Generator:** Tambah field tambahan (contoh: "Ukuran Sepatu", "Nomor Registrasi Organisasi") ke modul apa saja via kolom `metadata JSONB`.
2. **Dynamic UI Form Renderer:** Komponen Frontend yang otomatis merender elemen input berdasarkan konfigurasi skema JSONB.
3. **Validasi Aturan Kustom:** Penentuan kolom wajib diisi (*required*), panjang karakter, atau nilai regex tanpa mengubah backend.
4. **Ekspor-Impor Template Skema:** Kemampuan duplikasi skema modul antar-brand dalam format JSON.

---

## 3. DIAGRAM ALUR EXTENSI SKEMA LOW-CODE

```text
[SYSTEM ARCHITECT (admin-studio.html)]
     |
     v (1. Pilih Modul Target: MOD-01 Form Ingestion -> Tambah Field: "Ukuran Seragam")
[Supabase: public.studio_custom_fields]
     |-- Simpan Definisi Field: {name: "uniform_size", type: "SELECT", options: ["S","M","L","XL"]}
     |
     v (2. Klien Membuka Form di Browser (DynamicFormRenderer.js))
[Frontend Ingestion Engine]
     |-- Query Skema Dinamis untuk MOD-01
     |-- Render Otomatis Elemen Dropdown "Ukuran Seragam"
     |
     v (3. Submit Data)
[Simpan Nilai ke Kolom metadata JSONB di Tabel Asli]
     |-- form_submissions.metadata -> {"uniform_size": "L"}
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL DEFINISI CUSTOM FIELD (STUDIO CUSTOM FIELDS)
CREATE TABLE IF NOT EXISTS public.studio_custom_fields (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    target_module VARCHAR(50) NOT NULL, -- Contoh: 'MOD-01', 'MOD-06', 'MOD-28'
    field_key VARCHAR(60) NOT NULL, -- Contoh: 'uniform_size', 'branch_code'
    field_label VARCHAR(100) NOT NULL,
    field_type VARCHAR(30) NOT NULL, -- 'TEXT', 'NUMBER', 'SELECT', 'DATE', 'BOOLEAN', 'TEXTAREA'
    field_options JSONB DEFAULT '[]'::jsonb, -- Untuk pilihan dropdown: ["Option A", "Option B"]
    is_required BOOLEAN DEFAULT false,
    default_value TEXT,
    sort_order INT NOT NULL DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(target_module, field_key)
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_studio_module ON public.studio_custom_fields (target_module, is_active);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.studio_custom_fields ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh membaca konfigurasi field untuk merender formulir
CREATE POLICY "Allow public read active custom fields" 
ON public.studio_custom_fields 
FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

-- 2. Khusus Superadmin yang berhak menambah/mengedit konfigurasi field
CREATE POLICY "Superadmin manage studio fields" 
ON public.studio_custom_fields 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT role FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = 'SUPERADMIN'
);
```

---

## 6. LOGIKA KLIEN: DYNAMIC FORM RENDERER (JAVASCRIPT)

```javascript
/**
 * MOD-42: Dynamic Custom Fields Renderer
 */
async function renderDynamicFields(targetModule, containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const { data: fields, error } = await supabaseClient
        .from('studio_custom_fields')
        .select('*')
        .eq('target_module', targetModule)
        .eq('is_active', true)
        .order('sort_order');

    if (error || !fields) return;

    let html = '';
    fields.forEach(f => {
        html += `<div class="form-group custom-field">
            <label for="custom_${f.field_key}">${f.field_label} ${f.is_required ? '<span class="required">*</span>' : ''}</label>`;
        
        if (f.field_type === 'SELECT') {
            const options = Array.isArray(f.field_options) ? f.field_options : JSON.parse(f.field_options || '[]');
            html += `<select id="custom_${f.field_key}" name="${f.field_key}" class="form-select" ${f.is_required ? 'required' : ''}>
                <option value="">-- Pilih ${f.field_label} --</option>
                ${options.map(opt => `<option value="${opt}">${opt}</option>`).join('')}
            </select>`;
        } else if (f.field_type === 'TEXTAREA') {
            html += `<textarea id="custom_${f.field_key}" name="${f.field_key}" class="form-textarea" ${f.is_required ? 'required' : ''}></textarea>`;
        } else {
            html += `<input type="${f.field_type.toLowerCase()}" id="custom_${f.field_key}" name="${f.field_key}" class="form-input" ${f.is_required ? 'required' : ''}>`;
        }

        html += `</div>`;
    });

    container.innerHTML = html;
}
```

---

## 7. SPESIFIKASI ANTARMUKA LOW-CODE STUDIO

```html
<div class="studio-manager-card">
    <div class="header">
        <h3>Studio Generator: Kustomisasi Skema Modul</h3>
        <button type="button" class="btn btn-primary" onclick="openNewFieldModal()">+ Tambah Custom Field Baru</button>
    </div>
    <table class="data-table">
        <thead>
            <tr><th>Target Modul</th><th>Kunci Field (Key)</th><th>Label Tampilan</th><th>Tipe Input</th><th>Wajib Diisi</th></tr>
        </thead>
        <tbody>
            <tr>
                <td><code>MOD-01 (Form Ingestion)</code></td>
                <td><code>uniform_size</code></td>
                <td>Ukuran Seragam</td>
                <td><span class="badge badge-info">[SELECT / DROPDOWN]</span></td>
                <td>Ya</td>
            </tr>
        </tbody>
    </table>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Zero-Deploy Flexibility:** Penambahan field baru di admin studio langsung muncul di halaman web publik tanpa restart server.
- [ ] **Validasi Integritas JSONB:** Nilai input tersimpan secara rapi dalam struktur JSONB tanpa merusak kolom bawaan tabel.
- [ ] **Strict No-Emoji:** Panel Studio dan tipe input bebas emoji.