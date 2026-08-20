# SPESIFIKASI MODUL: PRODUCT LIFECYCLE MANAGEMENT (PLM & ECO)
> Kode Modul: `MOD-25` | Versi: `1.0.0` | Kategori: `Supply Chain & Manufaktur (REC-08)` | Dependensi: `Supabase, MOD-24`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-25-PLM-ENGINEERING-CHANGE` |
| **Nama Modul** | Product Lifecycle Management (PLM) & Engineering Change Orders (ECO) |
| **Kategori** | Engineering Design, Version Control & Product Lifecycle |
| **Level Akses Publik** | R&D Engineer & Product Owner (`authenticated`) |
| **Tingkat Decoupling** | High (Mengatur versi formula BOM pada MOD-24) |
| **Integrasi Pilar** | Supabase (Product Version Matrix & Engineering Workflow) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengelola siklus hidup rancangan produk (*Product Lifecycle*), revisi formula/desain teknis, alur persetujuan perubahan spesifikasi rekayasa (*Engineering Change Orders - ECO*), dan perbandingan versi (*BOM Diff / Revision Tracking*) guna mencegah kesalahan produksi saat formula material diperbarui.

### Fitur Utama:
1. **Version Control Formula Produk:** Riwayat versi formula (v1.0, v1.1, v2.0) yang terarsip secara historis.
2. **Engineering Change Orders (ECO):** Formulir usulan perubahan material/desain lengkap dengan analisis dampak biaya (*cost impact analysis*).
3. **BOM Version Comparison (Diff Viewer):** Menyorot komponen yang ditambah, dihapus, atau diubah kuantitasnya.
4. **Alur Approval Berjenjang R&D:** Persetujuan Lead Engineer -> Plant Manager sebelum formula baru aktif.

---

## 3. DIAGRAM ALUR ENGINEERING CHANGE ORDER (ECO)

```text
[ENGINEER R&D / PRODUCT DESIGNER]
     |
     v (1. Ajukan Usulan Perubahan: ECO-2026-003)
[Supabase: public.plm_eco_orders]
     |-- Ganti Bahan Komponen A (Rp 50.000) dengan Komponen B Lebih Kuat (Rp 60.000)
     |-- Analisis Dampak HPP: Kenaikan +Rp 10.000 / Unit
     |
     v (2. Review & Pengujian Sampel)
[Persetujuan Tim R&D & Manajemen Pabrik]
     |-- Disetujui -> Status: "APPLIED"
     |
     v (3. Otomasi Update Formula di MOD-24)
[Arsipkan BOM Lama (v1.0 -> ARCHIVED)]
     |-- Aktifkan BOM Baru (v2.0 -> ACTIVE)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL ENGINEERING CHANGE ORDERS (ECO)
CREATE TABLE IF NOT EXISTS public.plm_eco_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    eco_number VARCHAR(60) UNIQUE NOT NULL, -- Format: ECO-YYYYMMDD-XXXX
    product_id UUID NOT NULL REFERENCES public.products(id),
    base_bom_id UUID NOT NULL REFERENCES public.mrp_bom_headers(id),
    new_version VARCHAR(20) NOT NULL, -- Contoh: 'v2.0'
    change_title VARCHAR(200) NOT NULL,
    change_reason TEXT NOT NULL,
    cost_impact_per_unit NUMERIC(15, 2) DEFAULT 0.00,
    status VARCHAR(30) DEFAULT 'DRAFT', -- 'DRAFT', 'UNDER_REVIEW', 'APPROVED', 'APPLIED', 'REJECTED'
    proposed_by UUID REFERENCES public.admin_users(id),
    approved_by UUID REFERENCES public.admin_users(id),
    applied_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_eco_product ON public.plm_eco_orders (product_id);
CREATE INDEX IF NOT EXISTS idx_eco_status ON public.plm_eco_orders (status);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.plm_eco_orders ENABLE ROW LEVEL SECURITY;

-- 1. Blokir akses publik
CREATE POLICY "Deny public PLM access" ON public.plm_eco_orders FOR ALL TO anon USING (false);

-- 2. Engineer & Manager memiliki akses kelola
CREATE POLICY "Allow R&D staff manage ECOs" 
ON public.plm_eco_orders 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: ECO APPLY DISPATCHER (JAVASCRIPT)

```javascript
/**
 * MOD-25: Apply Approved ECO to Active BOM
 */
async function applyApprovedECO(ecoId) {
    try {
        const { data, error } = await supabaseClient
            .rpc('apply_engineering_change_order', { p_eco_id: ecoId });

        if (error) throw error;
        showNotification('[SUCCESS] Perubahan formula BOM baru berhasil diaktifkan.', 'success');
        refreshECODashboard();
    } catch (err) {
        console.error('[PLM_ERROR]', err);
        showNotification('[ERROR] Gagal menerapkan perubahan formula rekayasa.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA BOM DIFF VIEWER

```html
<div class="eco-card">
    <div class="card-header">
        <h3>Perbandingan Formula Desain (BOM Revision Diff)</h3>
        <span class="badge badge-warning">[ECO: USULAN REVISI V2.0]</span>
    </div>
    <div class="diff-container">
        <p class="diff-line deleted">- Komponen Lama: <code>RAW-WOD-01</code> Rangka Kayu Mahoni Standar (Rp 120.000)</p>
        <p class="diff-line added">+ Komponen Baru: <code>RAW-TEAK-02</code> Rangka Kayu Jati Perhutani (Rp 150.000)</p>
        <div class="impact-box">
            <strong>Dampak Biaya HPP:</strong> Kenaikan <strong>+Rp 30.000 / Unit</strong> (Kualitas Ketahanan +5 Tahun)
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Proteksi BOM Aktif:** Formula BOM tidak dapat diubah langsung di database tanpa melalui dokumen ECO resmi.
- [ ] **Histori Versi Lengkap:** Seluruh versi lama formula tetap dapat dibuka dan diaudit.
- [ ] **Strict No-Emoji:** Status dokumen ECO dan penanda diff formula bebas emoji.