const express = require('express');
const { z } = require('zod');
const { withTransaction } = require('../db');
const { serializeUser } = require('../utils/serializers');

const userIdSchema = z.string().uuid();
const profileSchema = z.object({
  userId: z.string().uuid().optional(),
  username: z.string().trim().min(1).max(64).optional(),
  avatarLocalPath: z.string().max(2048).nullable().optional(),
  bio: z.string().max(150).optional(),
  followersCount: z.number().int().min(0).optional(),
  followingCount: z.number().int().min(0).optional(),
  ratingBadge: z.string().trim().min(1).max(32).optional(),
  dietPreferences: z.array(z.string().trim().min(1).max(64)).max(100).optional(),
  allergies: z.array(z.string().trim().min(1).max(64)).max(100).optional(),
  pastOrders: z.array(z.string().trim().min(1).max(255)).max(500).optional(),
  favoriteRestaurants: z.array(z.string().trim().min(1).max(120)).max(500).optional(),
  eatListRestaurants: z.array(z.string().trim().min(1).max(120)).max(500).optional(),
  comments: z.array(z.string().trim().min(1).max(500)).max(500).optional(),
}).strict();

async function loadProfile(pool, userId) {
  const [profile, diet, allergies, orders, favorites, eatList, comments] = await Promise.all([
    pool.query(
      `SELECT p.user_id, p.avatar_path, p.bio, p.followers_count, p.following_count,
              p.rating_badge, u.username
       FROM profiles p JOIN users u ON u.id = p.user_id WHERE p.user_id = $1`,
      [userId],
    ),
    pool.query('SELECT label FROM diet_preferences WHERE user_id = $1 ORDER BY id', [userId]),
    pool.query('SELECT label FROM allergies WHERE user_id = $1 ORDER BY id', [userId]),
    pool.query('SELECT description FROM past_orders WHERE user_id = $1 ORDER BY ordered_at DESC', [userId]),
    pool.query(
      `SELECT r.name FROM favorite_restaurants f
       JOIN restaurants r ON r.id = f.restaurant_id WHERE f.user_id = $1 ORDER BY f.added_at DESC`,
      [userId],
    ),
    pool.query(
      `SELECT r.name FROM eat_list_restaurants e
       JOIN restaurants r ON r.id = e.restaurant_id WHERE e.user_id = $1 ORDER BY e.added_at DESC`,
      [userId],
    ),
    pool.query('SELECT body FROM comments WHERE user_id = $1 ORDER BY created_at DESC', [userId]),
  ]);

  const row = profile.rows[0];
  if (!row) return null;
  return {
    userId: row.user_id,
    avatarLocalPath: row.avatar_path,
    bio: row.bio,
    followersCount: row.followers_count,
    followingCount: row.following_count,
    ratingBadge: row.rating_badge,
    dietPreferences: diet.rows.map((item) => item.label),
    allergies: allergies.rows.map((item) => item.label),
    pastOrders: orders.rows.map((item) => item.description),
    favoriteRestaurants: favorites.rows.map((item) => item.name),
    eatListRestaurants: eatList.rows.map((item) => item.name),
    comments: comments.rows.map((item) => item.body),
  };
}

async function replaceLabels(client, table, userId, values) {
  await client.query(`DELETE FROM ${table} WHERE user_id = $1`, [userId]);
  for (const value of [...new Set(values)]) {
    await client.query(`INSERT INTO ${table} (user_id, label) VALUES ($1, $2)`, [userId, value]);
  }
}

async function replaceDescriptions(client, table, column, userId, values) {
  await client.query(`DELETE FROM ${table} WHERE user_id = $1`, [userId]);
  for (const value of values) {
    await client.query(
      `INSERT INTO ${table} (user_id, ${column}) VALUES ($1, $2)`,
      [userId, value],
    );
  }
}

async function replaceRestaurantList(client, table, userId, names) {
  await client.query(`DELETE FROM ${table} WHERE user_id = $1`, [userId]);
  for (const name of [...new Set(names)]) {
    const restaurant = await client.query(
      'SELECT id FROM restaurants WHERE name = $1 ORDER BY created_at, id LIMIT 1',
      [name],
    );
    if (!restaurant.rows[0]) {
      const error = new Error(`Restoran bulunamadı: ${name}`);
      error.status = 400;
      throw error;
    }
    await client.query(
      `INSERT INTO ${table} (user_id, restaurant_id) VALUES ($1, $2)`,
      [userId, restaurant.rows[0].id],
    );
  }
}

function createProfilesRouter({ pool, authenticate, requireSelfOrAdmin }) {
  const router = express.Router();
  router.use(authenticate);

  router.get('/:userId/profile', async (req, res, next) => {
    try {
      const userId = userIdSchema.parse(req.params.userId);
      const profile = await loadProfile(pool, userId);
      if (!profile) return res.status(404).json({ success: false, message: 'Profil bulunamadı.' });
      return res.json(profile);
    } catch (error) {
      return next(error);
    }
  });

  router.post('/:userId/profile', requireSelfOrAdmin(), async (req, res, next) => {
    try {
      const userId = userIdSchema.parse(req.params.userId);
      await pool.query(
        'INSERT INTO profiles (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING',
        [userId],
      );
      return res.status(201).json(await loadProfile(pool, userId));
    } catch (error) {
      return next(error);
    }
  });

  router.put('/:userId/profile', requireSelfOrAdmin(), async (req, res, next) => {
    try {
      const userId = userIdSchema.parse(req.params.userId);
      const input = profileSchema.parse(req.body);
      if (input.userId && input.userId !== userId) {
        return res.status(400).json({ success: false, message: 'Profil kullanıcı kimlikleri eşleşmiyor.' });
      }
      await withTransaction(pool, async (client) => {
        if (input.username !== undefined) {
          await client.query('UPDATE users SET username = $1 WHERE id = $2', [input.username, userId]);
        }
        await client.query(
          `UPDATE profiles SET
             avatar_path = COALESCE($1, avatar_path),
             bio = COALESCE($2, bio),
             rating_badge = COALESCE($3, rating_badge)
           WHERE user_id = $4`,
          [
            input.avatarLocalPath === null ? null : input.avatarLocalPath,
            input.bio,
            input.ratingBadge,
            userId,
          ],
        );
        if (input.avatarLocalPath === null) {
          await client.query('UPDATE profiles SET avatar_path = NULL WHERE user_id = $1', [userId]);
        }
        if (input.dietPreferences) await replaceLabels(client, 'diet_preferences', userId, input.dietPreferences);
        if (input.allergies) await replaceLabels(client, 'allergies', userId, input.allergies);
        if (input.pastOrders) {
          await replaceDescriptions(client, 'past_orders', 'description', userId, input.pastOrders);
        }
        if (input.comments) await replaceDescriptions(client, 'comments', 'body', userId, input.comments);
        if (input.favoriteRestaurants) {
          await replaceRestaurantList(client, 'favorite_restaurants', userId, input.favoriteRestaurants);
        }
        if (input.eatListRestaurants) {
          await replaceRestaurantList(client, 'eat_list_restaurants', userId, input.eatListRestaurants);
        }
      });
      const [profile, userResult] = await Promise.all([
        loadProfile(pool, userId),
        pool.query(
          'SELECT id, nickname, username, email, role, created_at FROM users WHERE id = $1',
          [userId],
        ),
      ]);
      if (!profile) return res.status(404).json({ success: false, message: 'Profil bulunamadı.' });
      return res.json({ profile, user: serializeUser(userResult.rows[0]) });
    } catch (error) {
      return next(error);
    }
  });

  const listEndpoints = {
    'diet-preferences': ['diet_preferences', 'label'],
    allergies: ['allergies', 'label'],
    orders: ['past_orders', 'description'],
    comments: ['comments', 'body'],
  };
  router.get('/:userId/:collection', async (req, res, next) => {
    try {
      const userId = userIdSchema.parse(req.params.userId);
      const definition = listEndpoints[req.params.collection];
      if (!definition) return next();
      const result = await pool.query(
        `SELECT ${definition[1]} AS value FROM ${definition[0]} WHERE user_id = $1 ORDER BY id`,
        [userId],
      );
      return res.json(result.rows.map((row) => row.value));
    } catch (error) {
      return next(error);
    }
  });

  router.get('/:userId/lists', async (req, res, next) => {
    try {
      const userId = userIdSchema.parse(req.params.userId);
      const profile = await loadProfile(pool, userId);
      if (!profile) return res.status(404).json({ success: false, message: 'Profil bulunamadı.' });
      return res.json({
        favoriteRestaurants: profile.favoriteRestaurants,
        eatListRestaurants: profile.eatListRestaurants,
      });
    } catch (error) {
      return next(error);
    }
  });

  router.get(['/:userId/followers', '/:userId/following'], async (req, res, next) => {
    try {
      const userId = userIdSchema.parse(req.params.userId);
      const followers = req.path.endsWith('/followers');
      const result = await pool.query(
        `SELECT u.id, u.nickname, u.username
         FROM follows f JOIN users u ON u.id = ${followers ? 'f.follower_id' : 'f.followed_id'}
         WHERE ${followers ? 'f.followed_id' : 'f.follower_id'} = $1
         ORDER BY f.created_at DESC`,
        [userId],
      );
      return res.json(result.rows);
    } catch (error) {
      return next(error);
    }
  });

  return router;
}

module.exports = { createProfilesRouter, loadProfile };
