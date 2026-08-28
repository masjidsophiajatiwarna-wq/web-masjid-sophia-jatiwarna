# Supabase & PostgreSQL Operations Rules

> **Ekosistem Web Portal Masjid Musafir Sophia Jatiwarna**

## 1. Project Boundary & MCP Server Target

Setiap interaksi database, migrasi SQL, RPC, dan inspeksi skema di repositori ini WAJIB menggunakan target berikut:

- **Supabase Project ID:** `fcwajbemkbhkogwtqcmx`
- **Supabase Project URL:** `https://fcwajbemkbhkogwtqcmx.supabase.co`
- **Active MCP Server:** `supabase-masjid-sophia`

### Aturan Larangan (Strict Prohibitions)
1. **DILARANG KERAS** memanggil MCP server `supabase-siabe` (Project ID: `znqstcnlykgsfzfdiltm`) atau database eksternal lainnya saat bekerja di repositori ini.
2. Pengembang/AI tidak boleh mengasumsikan nama kolom; selalu lakukan verifikasi skema via `list_tables` atau berkas `database/schema.sql`.

## 2. Standar Penulisan SQL & Migrasi

1. **Row Level Security (RLS):** Semua tabel publik wajib mengaktifkan `ENABLE ROW LEVEL SECURITY`.
2. **Search Path:** Setiap fungsi `SECURITY DEFINER` wajib memiliki klausa `SET search_path = public` untuk mencegah eksploitasi search-path mutable.
3. **Pemberian Hak Eksekusi:** Fungsi sistem seperti trigger atau pembuatan akun DKM tidak boleh memiliki izin eksekusi dari role `anon`.
4. **Immutability & History:** Jangan menghapus berkas migrasi lama di folder `database/`; selalu buat berkas migrasi baru bertahap (`migration_*.sql`).
