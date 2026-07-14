const test = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../src/app');

const config = {
  JWT_SECRET: 'test-secret-that-is-at-least-thirty-two-characters',
  corsOrigins: [],
};
const pool = {
  query: async () => ({ rows: [{ '?column?': 1 }] }),
};

async function withServer(callback) {
  const server = createApp({ pool, config }).listen(0);
  try {
    const { port } = server.address();
    await callback(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('Flutter /api/v1 rotaları kimlik doğrulama uygular', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(
      `${baseUrl}/api/v1/users/00000000-0000-4000-8000-000000000000/profile`,
    );
    assert.equal(response.status, 401);
  });
});

test('Yönetim /v1 rotaları kimlik doğrulama uygular', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/v1/admin/tables`);
    assert.equal(response.status, 401);
  });
});
