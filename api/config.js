// ==============================================================================
// Vercel Serverless Function: /api/config.js
// Safe Public Runtime Configuration Provider - Masjid Musafir Sophia Jatiwarna
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
    // CORS Headers
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Cache-Control', 'public, max-age=60, s-maxage=300, stale-while-revalidate=600');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'GET') {
        return res.status(405).json({ success: false, message: 'Method Not Allowed' });
    }

    const localEnv = (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) ? getLocalEnvFallback() : {};

    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || localEnv.SUPABASE_URL || '';
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || localEnv.SUPABASE_ANON_KEY || '';

    return res.status(200).json({
        success: true,
        supabaseUrl,
        supabaseAnonKey
    });
}
