// ==============================================================================
// Test Helper: Mock Request & Response untuk Vercel Serverless Functions
// ==============================================================================

export function createMockReqRes(options = {}) {
    const headers = options.headers || {};
    const body = options.body || {};
    const method = options.method || 'POST';

    const req = {
        method,
        headers,
        body,
        query: options.query || {}
    };

    const res = {
        statusCode: 200,
        headers: {},
        body: null,
        status(code) {
            this.statusCode = code;
            return this;
        },
        setHeader(key, val) {
            this.headers[key.toLowerCase()] = val;
            return this;
        },
        json(data) {
            this.body = data;
            return this;
        },
        end(data) {
            this.body = data || '';
            return this;
        }
    };

    return { req, res };
}
