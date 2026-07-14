const bcrypt = require('bcrypt');
const { withTransaction } = require('../db');

async function seedAdmin(pool, config) {
  if (!config.ADMIN_EMAIL) return { seeded: false };

  const email = config.ADMIN_EMAIL.toLowerCase();
  const existing = await pool.query(
    'SELECT password_hash FROM users WHERE email = $1',
    [email],
  );
  const passwordHash = existing.rows[0]
    && await bcrypt.compare(config.ADMIN_PASSWORD, existing.rows[0].password_hash)
    ? existing.rows[0].password_hash
    : await bcrypt.hash(config.ADMIN_PASSWORD, 12);
  const user = await withTransaction(pool, async (client) => {
    const result = await client.query(
      `INSERT INTO users (email, password_hash, nickname, username, role)
       VALUES ($1, $2, $3, $4, 'admin')
       ON CONFLICT (email) DO UPDATE SET
         password_hash = EXCLUDED.password_hash,
         nickname = EXCLUDED.nickname,
         username = EXCLUDED.username,
         role = 'admin'
       RETURNING id, email`,
      [
        email,
        passwordHash,
        config.ADMIN_NICKNAME,
        config.ADMIN_USERNAME,
      ],
    );
    await client.query(
      'INSERT INTO profiles (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING',
      [result.rows[0].id],
    );
    return result.rows[0];
  });

  return { seeded: true, email: user.email };
}

module.exports = { seedAdmin };
