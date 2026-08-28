import { test, describe, mock } from 'node:test';
import assert from 'node:assert/strict';
import donasiHandler from '../api/donasi.js';
import { createMockReqRes } from './test_helpers.js';

describe('Serverless API: /api/donasi (Ingestion Donasi)', () => {

    test('1. Menolak request selain POST (Method Not Allowed 405)', async () => {
        const { req, res } = createMockReqRes({ method: 'GET' });
        await donasiHandler(req, res);

        assert.equal(res.statusCode, 405);
        assert.equal(res.body.success, false);
        assert.equal(res.body.message, 'Method Not Allowed');
    });

    test('2. Merespons OPTIONS Preflight dengan status 200 dan CORS headers', async () => {
        const { req, res } = createMockReqRes({ method: 'OPTIONS' });
        await donasiHandler(req, res);

        assert.equal(res.statusCode, 200);
        assert.equal(res.headers['access-control-allow-origin'], '*');
    });

    test('3. Menolak input tanpa nomor WhatsApp atau nominal donasi <= 0 (HTTP 400)', async () => {
        const { req, res } = createMockReqRes({
            method: 'POST',
            body: {
                donor_name: 'Ahmad',
                amount: 0,
                phone_number: ''
            }
        });
        await donasiHandler(req, res);

        assert.equal(res.statusCode, 400);
        assert.equal(res.body.success, false);
        assert.match(res.body.message, /wajib diisi/i);
    });

    test('4. Menolak nominal donasi negatif (HTTP 400)', async () => {
        const { req, res } = createMockReqRes({
            method: 'POST',
            body: {
                donor_name: 'Ahmad',
                amount: -50000,
                phone_number: '+6281234567890'
            }
        });
        await donasiHandler(req, res);

        assert.equal(res.statusCode, 400);
        assert.equal(res.body.success, false);
    });

    test('5. Memproses donasi valid, menghasilkan kode unik 3 digit, dan menyamarkan nama jika incognito', async () => {
        // Mock global fetch untuk simulasi Supabase response
        const originalFetch = global.fetch;
        global.fetch = async (url, options) => {
            const parsedBody = JSON.parse(options.body);
            return {
                ok: true,
                status: 201,
                json: async () => [{
                    id: 'd9b3e1a0-1234-4567-8901-abcdef123456',
                    ...parsedBody
                }]
            };
        };

        try {
            const { req, res } = createMockReqRes({
                method: 'POST',
                body: {
                    donor_name: 'Ahmad Fauzi',
                    email: 'ahmad@example.com',
                    phone_number: '+6281234567890',
                    program_category: 'Makan Berjamaah Gratis',
                    amount: 50000,
                    payment_method: 'QRIS',
                    prayer_notes: 'Semoga berkah untuk musafir',
                    is_incognito: true
                }
            });

            await donasiHandler(req, res);

            assert.equal(res.statusCode, 200);
            assert.equal(res.body.success, true);
            assert.equal(res.body.data.donor_name, 'Hamba Allah', 'Nama wajib disamarkan jika is_incognito = true');
            assert.equal(res.body.data.amount, 50000);
            assert.ok(res.body.data.unique_code >= 100 && res.body.data.unique_code <= 999, 'Kode unik harus 3 digit');
            assert.equal(res.body.data.total_amount, 50000 + res.body.data.unique_code);
            assert.equal(res.body.data.payment_status, 'PENDING');
        } finally {
            global.fetch = originalFetch;
        }
    });

});
