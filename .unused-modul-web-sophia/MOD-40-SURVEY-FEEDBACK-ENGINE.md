# SPESIFIKASI MODUL: SURVEY, NPS & CUSTOMER FEEDBACK ENGINE
> Kode Modul: `MOD-40` | Versi: `1.0.0` | Kategori: `Produktivitas & Dokumen (REC-23)` | Dependensi: `Supabase, Resend`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-40-SURVEY-FEEDBACK-ENGINE` |
| **Nama Modul** | Survey, NPS & Customer Feedback Engine |
| **Kategori** | Feedback Collection, Market Research & CSAT/NPS Analytics |
| **Level Akses Publik** | Anonymous / Authenticated Respondent (Isi Survei) |
| **Tingkat Decoupling** | High (Menangkap kepuasan setelah transaksi MOD-02/MOD-06 atau penutupan tiket MOD-16) |
| **Integrasi Pilar** | Supabase (Dynamic JSONB Survey Schema & Aggregation Engine) |

---

## 2. TUJUAN BISNIS & USE CASE

Mengukur indeks kepuasan pelanggan (*Customer Satisfaction - CSAT*), loyalitas merek (*Net Promoter Score - NPS: Skala 0 s.d 10*), dan umpan balik pasar melalui pembuat kuesioner dinamis (*Dynamic Form Builder: Rating Bintang, Pilihan Ganda, Skala Likert, Teks Terbuka*), serta analitik ringkasan visual untuk tim riset & pemasaran.

### Fitur Utama:
1. **Dynamic Question Schema (JSONB):** Pembuatan pertanyaan kuesioner beragam tipe tanpa mengubah struktur tabel database.
2. **Kalkulasi Net Promoter Score (NPS):** Kategorisasi otomatis responden (*Promoters: 9-10, Passives: 7-8, Detractors: 0-6*).
3. **Trigger Otomatis Pasca-Transaksi:** Pengiriman link survei singkat 1 menit via email Resend setelah order sampai.
4. **Agregasi Grafik Respon:** Visualisasi distribusi persentase jawaban responden secara real-time.

---

## 3. DIAGRAM ALUR SURVEI & ANALITIK KEPUASAN

```text
[EVENT: PESANAN SELESAI / TIKET RESOLVED]
     |
     v (1. Kirim Undangan Kuesioner via Resend Email)
[Responden Membuka Link Survei (survey-form.html)]
     |-- Menjawab Pertanyaan: NPS Rating 9/10 + Feedback Teks
     |
     v (2. Simpan Respon ke Supabase)
[Supabase: public.survey_responses]
     |-- Simpan Payload Jawaban JSONB
     |
     v (3. Agregasi Skor NPS & CSAT Real-Time)
[Dashboard Analitik Kepuasan]
     |-- Hitung NPS: % Promoters - % Detractors
     |-- Skor NPS: +65 (Sangat Bagus)
```

---

## 4. SKEMA DATABASE SQL LENGKAP (POSTGRESQL)

```sql
-- TABEL KAMPANYE SURVEI (SURVEY CAMPAIGNS)
CREATE TABLE IF NOT EXISTS public.survey_campaigns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    survey_type VARCHAR(50) DEFAULT 'NPS', -- 'NPS', 'CSAT', 'MARKET_RESEARCH', 'EVENT_FEEDBACK'
    questions_schema JSONB NOT NULL, -- Array konfigurasi pertanyaan
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TABEL HASIL RESPON SURVEI (SURVEY RESPONSES)
CREATE TABLE IF NOT EXISTS public.survey_responses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id UUID NOT NULL REFERENCES public.survey_campaigns(id) ON DELETE CASCADE,
    respondent_email VARCHAR(150),
    nps_score INT, -- Nilai 0 s.d 10
    answers_data JSONB NOT NULL, -- Format: {"q1": "Sangat Puas", "q2": "Pengiriman cepat"}
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEXING
CREATE INDEX IF NOT EXISTS idx_survey_slug ON public.survey_campaigns (slug);
CREATE INDEX IF NOT EXISTS idx_survey_resp ON public.survey_responses (survey_id, nps_score);
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
ALTER TABLE public.survey_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_responses ENABLE ROW LEVEL SECURITY;

-- 1. Publik boleh membaca survei aktif dan mengirim respon
CREATE POLICY "Allow public read active surveys" ON public.survey_campaigns FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "Allow public submit survey response" ON public.survey_responses FOR INSERT TO anon, authenticated WITH CHECK (true);

-- 2. Staff Admin memiliki kontrol penuh melihat hasil
CREATE POLICY "Allow admin manage surveys" 
ON public.survey_campaigns 
FOR ALL 
TO authenticated 
USING (
    auth.jwt() ->> 'role' = 'service_role' OR 
    (SELECT is_active FROM public.admin_users WHERE email = auth.jwt() ->> 'email') = true
);
```

---

## 6. LOGIKA KLIEN: SUBMIT SURVEY RESPONSE (JAVASCRIPT)

```javascript
/**
 * MOD-40: Submit Survey Answers & Calculate NPS
 */
async function submitSurveyAnswers(surveyId, npsScore, answersObject) {
    try {
        const { error } = await supabaseClient
            .from('survey_responses')
            .insert([{
                survey_id: surveyId,
                nps_score: npsScore,
                answers_data: answersObject
            }]);

        if (error) throw error;
        showNotification('[SUCCESS] Terima kasih atas masukan berharga yang Anda berikan.', 'success');
        showThankYouView();
    } catch (err) {
        console.error('[SURVEY_ERROR]', err);
        showNotification('[ERROR] Gagal mengirim respon survei.', 'error');
    }
}
```

---

## 7. SPESIFIKASI ANTARMUKA KUESIONER NPS

```html
<div class="survey-box">
    <h3>Seberapa besar kemungkinan Anda merekomendasikan layanan kami ke rekan Anda?</h3>
    <div class="nps-rating-scale">
        <button type="button" class="nps-btn" onclick="selectNPS(0)">0</button>
        <button type="button" class="nps-btn" onclick="selectNPS(5)">5</button>
        <button type="button" class="nps-btn active" onclick="selectNPS(9)">9</button>
        <button type="button" class="nps-btn" onclick="selectNPS(10)">10</button>
    </div>
    <div class="scale-labels">
        <span>Sangat Tidak Mungkin</span>
        <span>Sangat Mungkin</span>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Kalkulasi NPS Standar:** Rumus % Promoters (9-10) dikurangi % Detractors (0-6) terhitung akurat.
- [ ] **Pencegahan Spam Respon:** Pembatasan 1 kali submit per alamat IP / Token sesi dalam periode 24 jam.
- [ ] **Strict No-Emoji:** Form kuesioner dan label kepuasan bebas emoji.