// ==============================================================================
// Vercel Serverless Function: /api/indexnow
// IndexNow Instant Search Engine Indexing (Bing, Yandex, IndexNow.org)
// Masjid Musafir Sophia Jatiwarna
// ==============================================================================

const INDEXNOW_KEY = '3c0606547e9f4e598bddd982c65cf8f0';
const DEFAULT_HOST = 'masjidsophia.com';
const KEY_LOCATION = `https://${DEFAULT_HOST}/${INDEXNOW_KEY}.txt`;

const DEFAULT_URLS = [
    `https://${DEFAULT_HOST}/`,
    `https://${DEFAULT_HOST}/galeri`,
    `https://${DEFAULT_HOST}/artikel`
];

export default async function handler(req, res) {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Credentials', true);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    try {
        let urlsToSubmit = DEFAULT_URLS;

        if (req.method === 'POST' && req.body) {
            let body = req.body;
            if (typeof body === 'string') {
                try {
                    body = JSON.parse(body);
                } catch (e) {
                    // Ignore parse error, use default
                }
            }
            if (Array.isArray(body.urls) && body.urls.length > 0) {
                urlsToSubmit = body.urls;
            } else if (typeof body.url === 'string' && body.url.trim().length > 0) {
                urlsToSubmit = [body.url.trim()];
            }
        }

        // Normalize URLs (pastikan format https://masjidsophia.com/...)
        urlsToSubmit = urlsToSubmit.map(u => {
            if (u.startsWith('/')) {
                return `https://${DEFAULT_HOST}${u}`;
            }
            return u;
        }).filter(u => u.startsWith(`https://${DEFAULT_HOST}`) || u.startsWith(`http://${DEFAULT_HOST}`));

        if (urlsToSubmit.length === 0) {
            urlsToSubmit = DEFAULT_URLS;
        }

        // Prepare payload according to official IndexNow specification
        const payload = {
            host: DEFAULT_HOST,
            key: INDEXNOW_KEY,
            keyLocation: KEY_LOCATION,
            urlList: urlsToSubmit
        };

        // Submit to official IndexNow aggregator endpoint
        const endpoints = [
            'https://api.indexnow.org/indexnow',
            'https://www.bing.com/indexnow'
        ];

        const results = await Promise.all(
            endpoints.map(async (endpoint) => {
                try {
                    const response = await fetch(endpoint, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=utf-8'
                        },
                        body: JSON.stringify(payload)
                    });

                    return {
                        endpoint,
                        status: response.status,
                        statusText: response.statusText,
                        success: response.status === 200 || response.status === 202
                    };
                } catch (err) {
                    return {
                        endpoint,
                        status: 500,
                        statusText: err.message,
                        success: false
                    };
                }
            })
        );

        const isSuccess = results.some(r => r.success);

        return res.status(isSuccess ? 200 : 502).json({
            success: isSuccess,
            message: isSuccess
                ? 'Permintaan pengindeksan instan IndexNow berhasil dikirim ke mesin pencari.'
                : 'Pengiriman IndexNow mengalami kendala. Periksa log detail.',
            key: INDEXNOW_KEY,
            keyLocation: KEY_LOCATION,
            submitted_urls: urlsToSubmit,
            results
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan internal server saat memproses IndexNow.',
            error: error.message
        });
    }
}
