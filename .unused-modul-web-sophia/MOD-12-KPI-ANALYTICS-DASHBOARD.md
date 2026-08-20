# SPESIFIKASI MODUL: KPI ANALYTICS & EXECUTIVE REPORTING DASHBOARD
> Kode Modul: `MOD-12` | Versi: `1.0.0` | Kategori: `Analytics & BI (Benchmark Modul D)` | Dependensi: `Supabase`

---

## 1. HEADER METADATA & RUANG LINGKUP

| Properti | Nilai |
| :--- | :--- |
| **Kode Modul** | `MOD-12-KPI-ANALYTICS-DASHBOARD` |
| **Nama Modul** | KPI Analytics & Executive Reporting Engine |
| **Kategori** | Business Intelligence & Data Visualization |
| **Level Akses Publik** | Restricted (Eksekutif & Admin `authenticated`) |
| **Tingkat Decoupling** | High (Membaca data teragregasi dari seluruh modul transaksional) |
| **Integrasi Pilar** | Supabase (PostgreSQL Materialized Views & Aggregate Functions) |

---

## 2. TUJUAN BISNIS & USE CASE

Menyajikan metrik performa utama (KPI), tren pendapatan/donasi, performa artikel terpopuler, tingkat konversi formulir, dan ringkasan eksekutif bisnis secara visual, interaktif, dan dapat diekspor ke format CSV / PDF untuk keperluan rapat pengambil keputusan.

### Fitur Utama:
1. **Executive Summary Cards:** Total Revenue, Total Submissions, Average Order Value (AOV), Lead Conversion Rate.
2. **Interactive Chart Engine (Chart.js):** Grafik tren pendapatan harian/bulanan, distribusi kategori produk/donasi.
3. **Date Range Filter Multi-Preset:** Hari ini, 7 Hari Terakhir, 30 Hari Terakhir, Bulan Ini, Custom Range.
4. **Data Exporter Engine:** Ekspor tabel data terfilter ke format spreadsheet CSV dan cetak ringkasan eksekutif.

---

## 3. DIAGRAM ARSITEKTUR ANALITIK & AGREGASI DATA

```text
[SUMBER DATA TRANSAKSIONAL]
   |-- public.form_submissions (MOD-01)
   |-- public.payment_transactions (MOD-02)
   |-- public.articles (MOD-03)
   |-- public.ecommerce_orders (MOD-06)
   |
   v
[PostgreSQL Database Aggregation Layer]
   |-- View: public.view_daily_revenue_kpi
   |-- RPC: public.get_dashboard_summary_metrics(start_date, end_date)
   |
   v
[Admin Dashboard Client (dashboard-kpi.html)]
   |-- Visualisasi Metric Cards
   |-- Render Chart.js (Line Chart, Bar Chart, Doughnut)
   |-- CSV Exporter Generator
```

---

## 4. SKEMA VIEW & STORED PROCEDURE SQL (POSTGRESQL)

```sql
-- VIEW AGREGASI PENDAPATAN HARIAN
CREATE OR REPLACE VIEW public.view_daily_revenue_kpi AS
SELECT 
    date_trunc('day', created_at)::date AS transaction_date,
    COUNT(id) AS total_transactions,
    SUM(CASE WHEN status IN ('PAID', 'VERIFIED') THEN total_amount ELSE 0 END) AS verified_revenue,
    COUNT(CASE WHEN status IN ('PAID', 'VERIFIED') THEN 1 END) AS successful_orders
FROM public.payment_transactions
GROUP BY date_trunc('day', created_at)
ORDER BY transaction_date DESC;

-- STORED PROCEDURE METRIK UTAMA DASHBOARD
CREATE OR REPLACE FUNCTION public.get_kpi_metrics(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    total_revenue NUMERIC,
    total_submissions BIGINT,
    total_orders BIGINT,
    total_article_views BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COALESCE(SUM(total_amount), 0.00) FROM public.payment_transactions WHERE status IN ('PAID', 'VERIFIED') AND created_at BETWEEN p_start_date AND p_end_date) AS total_revenue,
        (SELECT COUNT(id) FROM public.form_submissions WHERE created_at BETWEEN p_start_date AND p_end_date) AS total_submissions,
        (SELECT COUNT(id) FROM public.ecommerce_orders WHERE created_at BETWEEN p_start_date AND p_end_date) AS total_orders,
        (SELECT COALESCE(SUM(view_count), 0) FROM public.articles) AS total_article_views;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. KEBIJAKAN KEAMANAN ROW LEVEL SECURITY (RLS HARDENING)

```sql
-- 1. Blokir akses publik ke view dan fungsi analitik
REVOKE EXECUTE ON FUNCTION public.get_kpi_metrics FROM anon;

-- 2. Berikan izin eksekusi hanya kepada authenticated admin
GRANT EXECUTE ON FUNCTION public.get_kpi_metrics TO authenticated;
```

---

## 6. LOGIKA KLIEN: CHART.JS INITIALIZER & CSV EXPORTER

```javascript
/**
 * MOD-12: Chart.js Rendering & CSV Exporter
 */
let revenueChartInstance = null;

function renderRevenueChart(labels, dataValues) {
    const ctx = document.getElementById('revenue-chart-canvas').getContext('2d');
    if (revenueChartInstance) revenueChartInstance.destroy();

    revenueChartInstance = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Pendapatan Terverifikasi (IDR)',
                data: dataValues,
                borderColor: '#0284c7',
                backgroundColor: 'rgba(2, 132, 199, 0.1)',
                fill: true,
                tension: 0.3
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: { callback: (val) => 'Rp ' + val.toLocaleString('id-ID') }
                }
            }
        }
    });
}

function exportTableToCSV(tableId, filename = 'laporan-kpi.csv') {
    const table = document.getElementById(tableId);
    let csv = [];
    for (let row of table.rows) {
        let cols = Array.from(row.cells).map(cell => `"${cell.innerText.replace(/"/g, '""')}"`);
        csv.push(cols.join(','));
    }
    const blob = new Blob([csv.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
}
```

---

## 7. SPESIFIKASI ANTARMUKA EXECUTIVE DASHBOARD

```html
<div class="dashboard-container">
    <!-- Filter Date Range -->
    <div class="filter-bar">
        <select id="preset-date-filter" class="form-select">
            <option value="7d">7 Hari Terakhir</option>
            <option value="30d" selected>30 Hari Terakhir</option>
            <option value="this_month">Bulan Ini</option>
        </select>
        <button type="button" class="btn btn-secondary" onclick="exportTableToCSV('kpi-data-table')">Ekspor CSV</button>
    </div>

    <!-- Cards Grid -->
    <div class="metrics-grid">
        <div class="metric-card">
            <span class="metric-title">Total Pendapatan</span>
            <h3 class="metric-value" id="kpi-revenue">Rp 124.500.000</h3>
        </div>
        <div class="metric-card">
            <span class="metric-title">Total Formulir Masuk</span>
            <h3 class="metric-value" id="kpi-submissions">482 Data</h3>
        </div>
        <div class="metric-card">
            <span class="metric-title">Total Pesanan Sukses</span>
            <h3 class="metric-value" id="kpi-orders">189 Pesanan</h3>
        </div>
    </div>

    <!-- Chart Frame -->
    <div class="chart-card">
        <h4 class="chart-title">Tren Pendapatan & Pertumbuhan</h4>
        <div class="chart-wrapper">
            <canvas id="revenue-chart-canvas"></canvas>
        </div>
    </div>
</div>
```

---

## 8. CHECKLIST PENGUJIAN & ACCEPTANCE CRITERIA

- [ ] **Akurasi Perhitungan Agregasi:** Nilai total pada kartu metrik cocok 100% dengan total transaksi individual.
- [ ] **Kinerja Query Agregasi:** Eksekusi fungsi analitik berjalan < 500ms untuk rentang data 1 tahun.
- [ ] **Ekspor CSV Bersih:** Karakter pemisah koma dan kutip tertangani dengan rapi tanpa merusak format kolom.
- [ ] **Strict No-Emoji:** Label metrik, judul grafik, dan badge tren performa bebas dari karakter emoji.