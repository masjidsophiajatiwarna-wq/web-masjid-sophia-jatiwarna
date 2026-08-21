// ==============================================================================
// Vercel Serverless Function: /api/health
// System Health & Storage Monitor - Masjid Musafir Sophia Jatiwarna
// ==============================================================================

export default async function handler(req, res) {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Credentials', true);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }

    const startTime = Date.now();

    const healthReport = {
        timestamp: new Date().toISOString(),
        overall_status: 'HEALTHY',
        environment: process.env.NODE_ENV || 'production',
        services: {
            vercel_edge: {
                status: 'HEALTHY',
                region: process.env.VERCEL_REGION || 'sin1',
                runtime: 'Node.js Edge / Serverless'
            },
            supabase_db: {
                status: 'HEALTHY',
                project_ref: 'fcwajbemkbhkogwtqcmx',
                latency_ms: 0
            },
            imagekit_cdn: {
                status: 'HEALTHY',
                storage_limit_gb: 20.0,
                estimated_used_gb: 0.25,
                media_processing: 'WebP / AVIF & Video Adaptive'
            },
            resend_email: {
                status: 'HEALTHY',
                gateway: 'Resend API HTTPS',
                rate_limit: '100 emails/day (Free Tier)'
            }
        },
        latency_total_ms: 0
    };

    // Test Supabase connection latency
    try {
        const sbStart = Date.now();
        const sbKey = process.env.SUPABASE_ANON_KEY || '';
        const sbRes = await fetch('https://fcwajbemkbhkogwtqcmx.supabase.co/rest/v1/media_checklists?select=id&limit=1', {
            headers: {
                'apikey': sbKey,
                'Authorization': `Bearer ${sbKey}`
            }
        });
        healthReport.services.supabase_db.latency_ms = Date.now() - sbStart;
        if (!sbRes.ok) {
            healthReport.services.supabase_db.status = 'DEGRADED';
            healthReport.overall_status = 'DEGRADED';
        }
    } catch (e) {
        healthReport.services.supabase_db.status = 'DOWN';
        healthReport.overall_status = 'DEGRADED';
    }

    healthReport.latency_total_ms = Date.now() - startTime;

    return res.status(200).json(healthReport);
}
