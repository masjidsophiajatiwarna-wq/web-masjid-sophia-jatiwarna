// ==============================================================================
// Vercel Serverless Function: /api/send-receipt
// Pengiriman Kuitansi Donasi Instan via Resend.com Email API
// ==============================================================================

const RESEND_API_KEY = process.env.RESEND_API_KEY;

export default async function handler(req, res) {
    // CORS Headers
    res.setHeader('Access-Control-Allow-Credentials', true);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ success: false, message: 'Method Not Allowed' });
    }

    try {
        const { donation_id, donor_name, email, program_category, amount, total_amount, payment_method, date } = req.body;

        if (!email) {
            return res.status(400).json({ success: false, message: 'Email donatur tidak tersedia.' });
        }

        const formattedAmount = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(total_amount || amount);

        const emailHtml = `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: 'Plus Jakarta Sans', Arial, sans-serif; background-color: #F8F6F0; color: #1D1D1B; margin: 0; padding: 20px; }
                    .receipt-card { max-width: 580px; margin: 0 auto; background: #FFFFFF; border-radius: 12px; border-top: 6px solid #C9A84C; padding: 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
                    .header { text-align: center; border-bottom: 1px solid #E5E7EB; padding-bottom: 20px; margin-bottom: 20px; }
                    .header h2 { margin: 0 0 5px 0; color: #1D1D1B; font-size: 20px; }
                    .header p { margin: 0; color: #4B5563; font-size: 13px; }
                    .receipt-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 14px; }
                    .receipt-table td { padding: 10px 0; border-bottom: 1px solid #F3F4F6; }
                    .receipt-table td.label { color: #4B5563; width: 40%; }
                    .receipt-table td.val { font-weight: bold; text-align: right; color: #1D1D1B; }
                    .total-box { background: #FAF6E8; border: 1px solid #E8D8A0; padding: 15px; border-radius: 8px; text-align: center; margin-bottom: 20px; }
                    .total-box .amount { font-size: 24px; font-weight: 800; color: #785800; }
                    .footer { text-align: center; font-size: 12px; color: #9CA3AF; margin-top: 25px; line-height: 1.5; }
                </style>
            </head>
            <body>
                <div class="receipt-card">
                    <div class="header">
                        <h2>Kuitansi Tanda Terima Donasi</h2>
                        <p>Masjid Musafir Sophia Jatiwarna (DKM Sophia)</p>
                    </div>
                    <p style="font-size: 14px; color: #4B5563;">Jazakumullahu Khairan Katsiran, berikut adalah rincian tanda terima donasi Anda:</p>
                    <table class="receipt-table">
                        <tr>
                            <td class="label">ID Transaksi:</td>
                            <td class="val">${donation_id || 'DSP-' + Date.now()}</td>
                        </tr>
                        <tr>
                            <td class="label">Nama Donatur:</td>
                            <td class="val">${donor_name || 'Hamba Allah'}</td>
                        </tr>
                        <tr>
                            <td class="label">Program:</td>
                            <td class="val">${program_category || 'Makan Berjamaah Gratis'}</td>
                        </tr>
                        <tr>
                            <td class="label">Metode Pembayaran:</td>
                            <td class="val">${payment_method || 'QRIS'}</td>
                        </tr>
                        <tr>
                            <td class="label">Waktu Transaksi:</td>
                            <td class="val">${date || new Date().toLocaleDateString('id-ID')}</td>
                        </tr>
                    </table>
                    <div class="total-box">
                        <div style="font-size: 12px; color: #785800; font-weight: 600; text-transform: uppercase;">Total Donasi Diterima</div>
                        <div class="amount">${formattedAmount}</div>
                    </div>
                    <p style="font-size: 13px; color: #4B5563; text-align: center; font-style: italic;">
                        "Semoga Allah SWT membalas kebaikan Bapak/Ibu dengan keberkahan yang berlipat ganda dan menjadi amal jariyah yang terus mengalir."
                    </p>
                    <div class="footer">
                        Masjid Sophia Jatiwarna • Jl. Raya Hankam, Jatiwarna, Bekasi<br>
                        Hotline DKM 24 Jam: 0851-8835-2432 • masjidsophiajatiwarna@gmail.com
                    </div>
                </div>
            </body>
            </html>
        `;

        const resendRes = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${RESEND_API_KEY}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                from: 'Masjid Sophia Jatiwarna <dkm@masjidsophiajatiwarna.com>',
                to: [email],
                subject: `Kuitansi Tanda Terima Donasi - Masjid Sophia [${program_category || 'Sedekah'}]`,
                html: emailHtml
            })
        });

        const resendData = await resendRes.json();

        if (!resendRes.ok) {
            console.error('Resend Error:', resendData);
            return res.status(500).json({ success: false, message: 'Gagal mengirim email tanda terima via Resend.', details: resendData });
        }

        return res.status(200).json({
            success: true,
            message: 'Email kuitansi donasi berhasil dikirim.',
            email_id: resendData.id
        });

    } catch (error) {
        console.error('Send Receipt Error:', error);
        return res.status(500).json({ success: false, message: 'Terjadi kesalahan sistem saat mengirim kuitansi.' });
    }
}
