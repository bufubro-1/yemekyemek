const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const { withTransaction } = require('../db');
const { serializeUser } = require('../utils/serializers');

const credentialsSchema = z.object({
  email: z.string().email().transform((value) => value.toLowerCase()),
  password: z.string().min(8).max(128),
});

const registerSchema = credentialsSchema.extend({
  nickname: z.string().trim().min(3).max(32).regex(/^[\p{L}\p{N}_.-]+$/u),
  username: z.string().trim().min(1).max(64),
  role: z.enum(['user', 'restaurant_owner', 'restaurantOwner']).default('user'),
});

function createAuthRouter({ pool, jwtSecret, authenticate }) {
  const router = express.Router();
  const signToken = (user) => jwt.sign(
    { sub: user.id, role: user.role, email: user.email },
    jwtSecret,
    { expiresIn: '7d' },
  );

  router.post('/register', async (req, res, next) => {
    try {
      const input = registerSchema.parse(req.body);
      const passwordHash = await bcrypt.hash(input.password, 12);
      const user = await withTransaction(pool, async (client) => {
        const result = await client.query(
          `INSERT INTO users (nickname, username, email, password_hash, role)
           VALUES ($1, $2, $3, $4, $5)
           RETURNING id, nickname, username, email, role, created_at`,
          [
            input.nickname,
            input.username,
            input.email,
            passwordHash,
            input.role === 'user' ? 'user' : 'restaurant_owner',
          ],
        );
        await client.query('INSERT INTO profiles (user_id) VALUES ($1)', [result.rows[0].id]);
        return result.rows[0];
      });

      res.status(201).json({ success: true, token: signToken(user), user: serializeUser(user) });
    } catch (error) {
      next(error);
    }
  });

  router.post('/login', async (req, res, next) => {
    try {
      const input = credentialsSchema.parse(req.body);
      const result = await pool.query(
        `SELECT id, nickname, username, email, password_hash, role, created_at
         FROM users WHERE lower(email) = $1`,
        [input.email],
      );
      const user = result.rows[0];
      if (!user || !(await bcrypt.compare(input.password, user.password_hash))) {
        return res.status(401).json({ success: false, message: 'E-posta veya parola hatalı.' });
      }
      return res.json({ success: true, token: signToken(user), user: serializeUser(user) });
    } catch (error) {
      return next(error);
    }
  });

  router.get('/verify-token', authenticate, async (req, res, next) => {
    try {
      const result = await pool.query(
        'SELECT id, nickname, username, email, role, created_at FROM users WHERE id = $1',
        [req.auth.sub],
      );
      if (!result.rows[0]) return res.status(401).json({ success: false, message: 'Kullanıcı bulunamadı.' });
      return res.json({ success: true, user: serializeUser(result.rows[0]) });
    } catch (error) {
      return next(error);
    }
  });

  router.post('/refresh-token', authenticate, (req, res) => {
    const user = { id: req.auth.sub, role: req.auth.role, email: req.auth.email };
    res.json({ success: true, token: signToken(user) });
  });

  router.post('/logout', authenticate, (req, res) => {
    res.status(204).end();
  });

  return router;
}

module.exports = { createAuthRouter };
