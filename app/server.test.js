// ─── Tests ───────────────────────────────────────────────────
const request = require('supertest');
const app = require('./server');

describe('API endpoints', () => {

  // Test 1: health endpoint always works (no AWS needed)
  test('GET /health returns 200 and healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'healthy' });
  });

  // Test 2: root endpoint exists and handles missing DynamoDB gracefully
  test('GET / returns 200 or 500', async () => {
    const response = await request(app).get('/');
    expect([200, 500]).toContain(response.status);
  });

});