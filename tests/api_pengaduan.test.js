import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import pengaduanHandler from '../api/pengaduan.js';
import { createMockReqRes } from './test_helpers.js';

describe('Serverless API: /api/pengaduan (Pusat Pengaduan & Aspirasi)', () => {

    test('1. Menolak request selain POST (Method Not Allowed 405)', async () => {
        const { req, res } = createMockReqRes({ method: 'GET' });
        await pengaduanHandler(req, res);

        assert.equal(res.statusCode, 405);
        assert.equal(res.body.success, false);
    });

    test('2. Menolak pengaduan tanpa subjek atau isi pesan (HTTP 400)', async () => {
        const { req, res } = createMockReqRes({
            method: 'POST',
            body: {
                sender_name: 'Budi',
                subject: '',
                message: ''
            }
        });
        await pengaduanHandler(req, res);

        assert.equal(res.statusCode, 400);
        assert.equal(res.body.success, false);
        assert.match(res.body.message, /wajib diisi/i);
    });

    test('3. Memproses pengaduan valid dan mengembalikan status sukses (HTTP 200)', async () => {
        process.env.SUPABASE_ANON_KEY = 'mock_anon_key_for_test';
        const originalFetch = global.fetch;
        let dbPayload = null;

        global.fetch = async (url, options) => {
            if (url.includes('/rest/v1/feedback_complaints')) {
                dbPayload = JSON.parse(options.body);
            }
            return {
                ok: true,
                status: 200,
                json: async () => ({ id: 'mock-id' })
            };
        };

        try {
            const { req, res } = createMockReqRes({
                method: 'POST',
                body: {
                    sender_name: 'Budi Santoso',
                    email: 'budi@example.com',
                    phone_number: '+6281298765432',
                    category: 'Fasilitas & Kebersihan',
                    subject: 'Dispenser Air Musafir',
                    message: 'Mohon dicek stok gelas di dispenser air minum musafir.'
                }
            });

            await pengaduanHandler(req, res);

            assert.equal(res.statusCode, 200);
            assert.equal(res.body.success, true);
            assert.match(res.body.message, /berhasil dikirimkan/i);
            assert.equal(dbPayload.sender_name, 'Budi Santoso');
            assert.equal(dbPayload.status, 'BARU');
            assert.equal(dbPayload.category, 'Fasilitas & Kebersihan');
        } finally {
            global.fetch = originalFetch;
        }
    });

});
