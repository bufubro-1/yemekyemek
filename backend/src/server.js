require('dotenv').config();
const { loadConfig } = require('./config');
const { createPool } = require('./db');
const { createApp } = require('./app');
const { seedAdmin } = require('./services/seedAdmin');

async function start() {
  const config = loadConfig();
  const pool = createPool(config);
  await pool.query('SELECT 1');
  const seedResult = await seedAdmin(pool, config);
  if (seedResult.seeded) console.info(`Yönetici hesabı hazır: ${seedResult.email}`);

  const server = createApp({ pool, config }).listen(config.PORT, () => {
    console.info(`YemekYemek API ${config.PORT} portunda çalışıyor.`);
  });

  const shutdown = () => {
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

start().catch((error) => {
  console.error('API başlatılamadı:', error);
  process.exit(1);
});
