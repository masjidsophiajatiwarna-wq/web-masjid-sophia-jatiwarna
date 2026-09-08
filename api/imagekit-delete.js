// ==============================================================================
// VERCEL SERVERLESS FUNCTION: ImageKit.io Delete Relay & Bridge
// Proyek: Web Portal Masjid Musafir Sophia Jatiwarna
// ==============================================================================

import fs from 'fs';
import path from 'path';

function getLocalEnvFallback() {
    try {
        const envPath = path.resolve(process.cwd(), '.env');
        if (fs.existsSync(envPath)) {
            const content = fs.readFileSync(envPath, 'utf8');
            const lines = content.split('\n');
            const envMap = {};
            for (const line of lines) {
                const trimmed = line.trim();
                if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
                    const idx = trimmed.indexOf('=');
                    const key = trimmed.substring(0, idx).trim();
                    const val = trimmed.substring(idx + 1).trim();
                    envMap[key] = val;
                }
            }
            return envMap;
        }
    } catch (e) {}
    return {};
}

export default async function handler(req, res) {
    // CORS Configuration
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'POST' && req.method !== 'DELETE') {
        return res.status(405).json({ success: false, error: 'Method Not Allowed' });
    }

    try {
        const { fileId } = req.body || {};

        if (!fileId) {
            return res.status(400).json({ success: false, error: 'Parameter fileId wajib disertakan.' });
        }

        const localEnv = !process.env.IMAGEKIT_PRIVATE_KEY ? getLocalEnvFallback() : {};
        const privateKey = process.env.IMAGEKIT_PRIVATE_KEY || localEnv.IMAGEKIT_PRIVATE_KEY;

        if (!privateKey) {
            return res.status(500).json({
                success: false,
                error: 'Konfigurasi IMAGEKIT_PRIVATE_KEY belum disetel pada environment variable.'
            });
        }

        const authHeader = 'Basic ' + Buffer.from(privateKey + ':').toString('base64');

        const ikRes = await fetch(`https://api.imagekit.io/v1/files/${encodeURIComponent(fileId)}`, {
            method: 'DELETE',
            headers: {
                'Authorization': authHeader
            }
        });

        if (ikRes.ok || ikRes.status === 204 || ikRes.status === 404) {
            // 404 dianggap sukses karena berkas memang sudah tidak ada di ImageKit
            return res.status(200).json({
                success: true,
                message: 'Berkas berhasil dihapus dari media library ImageKit.io CDN.',
                fileId
            });
        }

        const errorText = await ikRes.text();
        return res.status(ikRes.status).json({
            success: false,
            error: 'Gagal menghapus berkas dari ImageKit: ' + errorText
        });

    } catch (err) {
        return res.status(500).json({
            success: false,
            error: 'Terjadi kesalahan server internal: ' + (err.message || String(err))
        });
    }
}
