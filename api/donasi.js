// ==============================================================================
// Vercel Serverless Function: /api/donasi
// Ingestion Donasi & Sedekah Makan - Masjid Musafir Sophia Jatiwarna
// ==============================================================================

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://fcwajbemkbhkogwtqcmx.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_ANON_KEY || '';

export default async function handler(req, res) {
    // CORS Headers
    res.setHeader('Access-Control-Allow-Credentials', true);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ success: false, message: 'Method Not Allowed' });
    }

    try {
        const { donor_name, email, phone_number, program_category, amount, payment_method, prayer_notes, is_incognito } = req.body;

        // Validasi Dasar
        if (!phone_number || !amount || Number(amount) <= 0) {
            return res.status(400).json({ success: false, message: 'Nominal donasi dan nomor WhatsApp wajib diisi.' });
        }

        const cleanAmount = Number(amount);
        const uniqueCode = Math.floor(Math.random() * 899) + 100; // 3-digit kode unik verifikasi
        const totalAmount = cleanAmount + uniqueCode;

        const payload = {
            donor_name: is_incognito ? 'Hamba Allah' : (donor_name || 'Hamba Allah'),
            email: email || null,
            phone_number: phone_number,
            program_category: program_category || 'Makan Berjamaah Gratis',
            amount: cleanAmount,
            unique_code: uniqueCode,
            total_amount: totalAmount,
            payment_method: payment_method || 'QRIS',
            payment_status: 'PENDING',
            prayer_notes: prayer_notes || null,
            is_incognito: !!is_incognito,
            created_at: new Date().toISOString()
        };

        // Insert to Supabase DB via REST API
        const sbResponse = await fetch(`${SUPABASE_URL}/rest/v1/donations`, {
            method: 'POST',
            headers: {
                'apikey': SUPABASE_KEY,
                'Authorization': `Bearer ${SUPABASE_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
            },
            body: JSON.stringify(payload)
        });

        if (!sbResponse.ok) {
            const errText = await sbResponse.text();
            console.error('Supabase Ingestion Error:', errText);
            return res.status(500).json({ success: false, message: 'Gagal mencatat donasi ke database.' });
        }

        const data = await sbResponse.json();
        const savedDonation = data[0] || payload;

        return res.status(200).json({
            success: true,
            message: 'Donasi berhasil dicatat. Silakan selesaikan pembayaran.',
            data: savedDonation
        });

    } catch (error) {
        console.error('API Error:', error);
        return res.status(500).json({ success: false, message: 'Terjadi kesalahan sistem serverless.' });
    }
}
