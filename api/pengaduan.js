// ==============================================================================
// Vercel Serverless Function: /api/pengaduan
// Pusat Pengaduan & Kotak Saran Jamaah - Masjid Musafir Sophia Jatiwarna
// ==============================================================================

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://fcwajbemkbhkogwtqcmx.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_ANON_KEY || '';
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
        const { sender_name, email, phone_number, category, subject, message } = req.body;

        if (!subject || !message) {
            return res.status(400).json({ success: false, message: 'Subjek dan isi pesan pengaduan wajib diisi.' });
        }

        const payload = {
            sender_name: sender_name || 'Hamba Allah',
            email: email || null,
            phone_number: phone_number || null,
            category: category || 'Saran & Masukan',
            subject: subject,
            message: message,
            status: 'BARU',
            created_at: new Date().toISOString()
        };

        // 1. Simpan ke database Supabase
        const activeKey = process.env.SUPABASE_ANON_KEY || SUPABASE_KEY;
        if (activeKey) {
            await fetch(`${SUPABASE_URL}/rest/v1/feedback_complaints`, {
                method: 'POST',
                headers: {
                    'apikey': activeKey,
                    'Authorization': `Bearer ${activeKey}`,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=minimal'
                },
                body: JSON.stringify(payload)
            });
        }

        // 2. Teruskan notifikasi instan ke email resmi DKM via Resend
        if (RESEND_API_KEY) {
            try {
                await fetch('https://api.resend.com/emails', {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${RESEND_API_KEY}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        from: 'Pusat Pengaduan Sophia <info@masjidsophiajatiwarna.com>',
                        to: ['masjidsophiajatiwarna@gmail.com'],
                        subject: `[PENGADUAN JAMAAH - ${category || 'Saran'}] ${subject}`,
                        html: `
                            <div style="font-family: Arial, sans-serif; padding: 20px; background: #F8F6F0; color: #1D1D1B;">
                                <div style="max-width: 600px; margin: 0 auto; background: #FFFFFF; border-radius: 10px; border-left: 6px solid #C9A84C; padding: 25px;">
                                    <h3 style="margin-top: 0; color: #1D1D1B;">Pesan Baru dari Jamaah / Musafir</h3>
                                    <p><strong>Pengirim:</strong> ${sender_name || 'Hamba Allah'}</p>
                                    <p><strong>Kontak:</strong> ${phone_number || '-'} | ${email || '-'}</p>
                                    <p><strong>Kategori:</strong> ${category || 'Saran & Masukan'}</p>
                                    <p><strong>Subjek:</strong> ${subject}</p>
                                    <hr style="border: 0; border-top: 1px solid #E5E7EB; margin: 15px 0;">
                                    <p><strong>Isi Pesan:</strong></p>
                                    <div style="background: #FAFAFA; border: 1px solid #E5E7EB; border-radius: 6px; padding: 15px; line-height: 1.6;">
                                        ${message.replace(/\n/g, '<br>')}
                                    </div>
                                    <p style="font-size: 12px; color: #9CA3AF; margin-top: 20px;">
                                        Pesan ini otomatis tercatat di Database Supabase Masjid Sophia Jatiwarna.
                                    </p>
                                </div>
                            </div>
                        `
                    })
                });
            } catch (err) {
                console.warn('Resend alert forward error:', err);
            }
        }

        return res.status(200).json({
            success: true,
            message: 'Terima kasih, pesan/saran Anda telah berhasil dikirimkan ke Pengurus DKM.'
        });

    } catch (error) {
        console.error('Pengaduan Error:', error);
        return res.status(500).json({ success: false, message: 'Terjadi kesalahan sistem saat mengirim pengaduan.' });
    }
}
