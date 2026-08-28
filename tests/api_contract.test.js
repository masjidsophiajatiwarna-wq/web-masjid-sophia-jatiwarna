import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

describe('API Contract & Specification Verification', () => {

    test('1. Berkas API_CONTRACT.md tersedia di root direktori', () => {
        const contractPath = resolve(process.cwd(), 'API_CONTRACT.md');
        assert.ok(existsSync(contractPath), 'Berkas API_CONTRACT.md wajib tersedia');
    });

    test('2. API_CONTRACT.md secara eksplisit mengunci Supabase Project ID fcwajbemkbhkogwtqcmx', () => {
        const contractContent = readFileSync(resolve(process.cwd(), 'API_CONTRACT.md'), 'utf-8');
        assert.match(contractContent, /fcwajbemkbhkogwtqcmx/, 'Project ID fcwajbemkbhkogwtqcmx harus terkunci di kontrak');
        assert.match(contractContent, /https:\/\/fcwajbemkbhkogwtqcmx\.supabase\.co/, 'Project URL harus terkunci di kontrak');
        assert.match(contractContent, /supabase-masjid-sophia/, 'MCP Server aktif harus supabase-masjid-sophia');
    });

    test('3. Seluruh 5 endpoint serverless terdokumentasi di API_CONTRACT.md', () => {
        const contractContent = readFileSync(resolve(process.cwd(), 'API_CONTRACT.md'), 'utf-8');
        const requiredEndpoints = ['/api/donasi', '/api/pengaduan', '/api/health', '/api/send-receipt', '/api/cloud-usage'];
        
        requiredEndpoints.forEach(ep => {
            assert.ok(contractContent.includes(ep), `Endpoint ${ep} wajib tercantum di API_CONTRACT.md`);
        });
    });

});
