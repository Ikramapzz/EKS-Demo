const request = require('supertest');
const app = require('./server');

describe('GET /', () => {
  it('responds with a welcome message', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message');
  });
});

describe('GET /health', () => {
  it('responds with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
