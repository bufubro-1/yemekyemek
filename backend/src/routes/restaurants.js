const express = require('express');
const { z } = require('zod');
const { withTransaction } = require('../db');
const { serializeRestaurant } = require('../utils/serializers');

const userIdSchema = z.string().uuid();
const restaurantSchema = z.object({
  ownerUserId: z.string().uuid(),
  name: z.string().trim().min(1).max(120),
  description: z.string().max(5000).default(''),
  phone: z.string().trim().min(7).max(20),
  address: z.string().trim().min(1).max(500),
  menuCategories: z.array(z.string().trim().min(1).max(80)).max(100).default([]),
}).strict();
const menuSchema = z.union([
  z.array(z.string().trim().min(1).max(80)).max(100),
  z.object({ menuCategories: z.array(z.string().trim().min(1).max(80)).max(100) }),
]);

async function getRestaurant(pool, ownerId) {
  const result = await pool.query(
    `SELECT r.id, r.owner_id, r.name, r.description, r.phone, r.address,
            COALESCE(array_agg(mc.name ORDER BY mc.sort_order, mc.id)
              FILTER (WHERE mc.id IS NOT NULL), '{}') AS menu_categories
     FROM restaurants r
     LEFT JOIN menu_categories mc ON mc.restaurant_id = r.id
     WHERE r.owner_id = $1
     GROUP BY r.id`,
    [ownerId],
  );
  const row = result.rows[0];
  return row ? serializeRestaurant(row, row.menu_categories) : null;
}

async function replaceMenu(client, restaurantId, categories) {
  await client.query('DELETE FROM menu_categories WHERE restaurant_id = $1', [restaurantId]);
  for (const [index, name] of [...new Set(categories)].entries()) {
    await client.query(
      'INSERT INTO menu_categories (restaurant_id, name, sort_order) VALUES ($1, $2, $3)',
      [restaurantId, name, index],
    );
  }
}

function createRestaurantsRouter({ pool, authenticate, requireSelfOrAdmin }) {
  const router = express.Router();
  router.use(authenticate);

  router.get('/owner/:userId', async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const restaurant = await getRestaurant(pool, ownerId);
      if (!restaurant) return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
      return res.json(restaurant);
    } catch (error) {
      return next(error);
    }
  });

  router.put('/owner/:userId', requireSelfOrAdmin(), async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const input = restaurantSchema.parse(req.body);
      if (input.ownerUserId !== ownerId) {
        return res.status(400).json({ success: false, message: 'Sahip kullanıcı kimlikleri eşleşmiyor.' });
      }

      await withTransaction(pool, async (client) => {
        const owner = await client.query('SELECT role FROM users WHERE id = $1', [ownerId]);
        if (!owner.rows[0]) {
          const error = new Error('Kullanıcı bulunamadı.');
          error.status = 404;
          throw error;
        }
        if (!['restaurant_owner', 'admin'].includes(owner.rows[0].role)) {
          const error = new Error('Yalnızca restoran sahipleri restoran kaydedebilir.');
          error.status = 403;
          throw error;
        }
        const result = await client.query(
          `INSERT INTO restaurants (owner_id, name, description, phone, address)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (owner_id) DO UPDATE SET
             name = EXCLUDED.name,
             description = EXCLUDED.description,
             phone = EXCLUDED.phone,
             address = EXCLUDED.address
           RETURNING id`,
          [ownerId, input.name, input.description, input.phone, input.address],
        );
        await replaceMenu(client, result.rows[0].id, input.menuCategories);
      });
      return res.json(await getRestaurant(pool, ownerId));
    } catch (error) {
      return next(error);
    }
  });

  router.get('/owner/:userId/menu', async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const restaurant = await getRestaurant(pool, ownerId);
      if (!restaurant) return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
      return res.json(restaurant.menuCategories);
    } catch (error) {
      return next(error);
    }
  });

  router.put('/owner/:userId/menu', requireSelfOrAdmin(), async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const input = menuSchema.parse(req.body);
      const categories = Array.isArray(input) ? input : input.menuCategories;
      await withTransaction(pool, async (client) => {
        const result = await client.query('SELECT id FROM restaurants WHERE owner_id = $1', [ownerId]);
        if (!result.rows[0]) {
          const error = new Error('Restoran bulunamadı.');
          error.status = 404;
          throw error;
        }
        await replaceMenu(client, result.rows[0].id, categories);
      });
      return res.json(categories);
    } catch (error) {
      return next(error);
    }
  });

  return router;
}

module.exports = { createRestaurantsRouter, getRestaurant };
