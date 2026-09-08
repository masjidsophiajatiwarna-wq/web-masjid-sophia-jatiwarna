// ==============================================================================
// VERCEL SERVERLESS FUNCTION: ImageKit.io Upload Relay & Bridge
// Proyek: Web Portal Masjid Musafir Sophia Jatiwarna
// ==============================================================================

export default async function handler(req, res) {
    // CORS Configuration
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method Not Allowed' });
    }

    try {
        const { file, fileName, folder } = req.body || {};

        if (!file || !fileName) {
            return res.status(400).json({ success: false, error: 'Parameter file dan fileName wajib disertakan.' });
        }

        const privateKey = process.env.IMAGEKIT_PRIVATE_KEY;
        if (!privateKey) {
            return res.status(500).json({
                success: false,
                error: 'Konfigurasi IMAGEKIT_PRIVATE_KEY belum disetel pada server environment variable.'
            });
        }
        const authHeader = 'Basic ' + Buffer.from(privateKey + ':').toString('base64');

        const formData = new FormData();
        formData.append('file', file);
        formData.append('fileName', fileName);
        formData.append('folder', folder || '/masjid-sophia');
        formData.append('useUniqueFileName', 'true');

        const ikRes = await fetch('https://upload.imagekit.io/api/v1/files/upload', {
            method: 'POST',
            headers: {
                'Authorization': authHeader
            },
            body: formData
        });

        const ikData = await ikRes.json();

        if (ikRes.ok && ikData.fileId) {
            return res.status(200).json({
                success: true,
                fileId: ikData.fileId,
                name: ikData.name,
                url: ikData.url,
                filePath: ikData.filePath,
                size: ikData.size,
                fileType: ikData.fileType || 'image',
                thumbnailUrl: ikData.thumbnailUrl || ikData.url
            });
        } else {
            console.error('ImageKit Upload Failed:', ikData);
            return res.status(ikRes.status || 500).json({
                success: false,
                error: ikData.message || 'Gagal mengunggah berkas ke ImageKit.'
            });
        }
    } catch (err) {
        console.error('ImageKit Relay Error:', err);
        return res.status(500).json({
            success: false,
            error: 'Terjadi kesalahan server saat mengunggah berkas: ' + err.message
        });
    }
}
