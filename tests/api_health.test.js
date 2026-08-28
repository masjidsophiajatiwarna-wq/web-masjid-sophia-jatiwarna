import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import healthHandler from '../api/health.js';
import { createMockReqRes } from './test_helpers.js';

describe('Serverless API: /api/health (System Health & Project Isolation)', () => {

    test('1. Merespons OPTIONS Preflight dengan status 200', async () => {
        const { req, res } = createMockReqRes({ method: 'OPTIONS' });
        await healthHandler(req, res);

        assert.equal(res.statusCode, 200);
    });

    test('2. Mengembalikan struktur kesehatan 4 pilar dan isolasi Project ID fcwajbemkbhkogwtqcmx', async () => {
        const originalFetch = global.fetch;
        global.fetch = async (url) => {
            return {
                ok: true,
                status: 200,
                json: async () => [{ id: 'mock-checklist-1' }]
            };
        };

        try {
            const { req, res } = createMockReqRes({ method: 'GET' });
            await healthHandler(req, res);

            assert.equal(res.statusCode, 200);
            assert.ok(res.body.timestamp);
            assert.equal(res.body.overall_status, 'HEALTHY');
            
            // Verifikasi Isolasi Supabase Project ID
            assert.equal(
                res.body.services.supabase_db.project_ref, 
                'fcwajbemkbhkogwtqcmx', 
                'Target database harus strictly terarah ke project ID Masjid Sophia fcwajbemkbhkogwtqcmx'
            );

            assert.equal(res.body.services.vercel_edge.status, 'HEALTHY');
            assert.equal(res.body.services.imagekit_cdn.status, 'HEALTHY');
            assert.equal(res.body.services.resend_email.status, 'HEALTHY');
        } finally {
            global.fetch = originalFetch;
        }
    });

});
