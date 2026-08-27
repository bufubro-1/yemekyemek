const express = require('express');
const { z } = require('zod');
const { withTransaction } = require('../db');
const { serializeRestaurant } = require('../utils/serializers');

const userIdSchema = z.string().uuid();
const categoryIdSchema = z.string().uuid();
const menuItemIdSchema = z.string().uuid();
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

const categoryCreateSchema = z.object({
  name: z.string().trim().min(1).max(80),
  sortOrder: z.number().int().min(0).optional(),
}).strict();

const categoryUpdateSchema = categoryCreateSchema
  .partial()
  .refine((input) => Object.keys(input).length > 0, {
    message: 'En az bir kategori alanı gönderilmelidir.',
  });

const menuItemCreateSchema = z.object({
  name: z.string().trim().min(1).max(120),
  description: z.string().trim().max(5000).default(''),
  price: z.number().finite().min(0).max(99999999.99),
  isAvailable: z.boolean().default(true),
  sortOrder: z.number().int().min(0).optional(),
}).strict();

const menuItemUpdateSchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  description: z.string().trim().max(5000).optional(),
  price: z.number().finite().min(0).max(99999999.99).optional(),
  isAvailable: z.boolean().optional(),
  sortOrder: z.number().int().min(0).optional(),
}).strict().refine(
  (input) => Object.keys(input).length > 0,
  {
    message: 'En az bir ürün alanı gönderilmelidir.',
  },
);

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

function normalizeCategoryNames(categories) {
  const uniqueCategories = new Map();

  for (const category of categories) {
    const name = category.trim();
    const normalizedName = name.toLowerCase();

    if (!uniqueCategories.has(normalizedName)) {
      uniqueCategories.set(normalizedName, name);
    }
  }

  return [...uniqueCategories.values()];
}

function createHttpError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

function serializeMenuCategory(row) {
  return {
    id: row.id,
    name: row.name,
    sortOrder: Number(row.sort_order),
    itemCount: Number(row.item_count ?? 0),
  };
}

function serializeMenuItem(row) {
  return {
    id: row.id,
    categoryId: row.category_id,
    name: row.name,
    description: row.description,
    price: Number(row.price),
    isAvailable: row.is_available,
    sortOrder: Number(row.sort_order),
    createdAt: new Date(row.created_at).toISOString(),
  };
}

async function getRestaurantId(queryable, ownerId) {
  const result = await queryable.query(
    'SELECT id FROM restaurants WHERE owner_id = $1',
    [ownerId],
  );

  if (!result.rows[0]) {
    throw createHttpError(404, 'Restoran bulunamadı.');
  }

  return result.rows[0].id;
}

async function getOwnedCategoryId(
  queryable,
  ownerId,
  categoryId,
) {
  const result = await queryable.query(
    `SELECT mc.id
     FROM menu_categories mc
     JOIN restaurants r ON r.id = mc.restaurant_id
     WHERE mc.id = $1
       AND r.owner_id = $2`,
    [categoryId, ownerId],
  );

  if (!result.rows[0]) {
    throw createHttpError(
      404,
      'Menü kategorisi bulunamadı.',
    );
  }

  return result.rows[0].id;
}

async function syncMenuCategories(client, restaurantId, categories) {
  const categoryNames = normalizeCategoryNames(categories);
  const retainedIds = [];

  for (const [index, name] of categoryNames.entries()) {
    const existing = await client.query(
      `SELECT id
       FROM menu_categories
       WHERE restaurant_id = $1
         AND lower(name) = lower($2)`,
      [restaurantId, name],
    );

    if (existing.rows[0]) {
      await client.query(
        `UPDATE menu_categories
         SET name = $2,
             sort_order = $3
         WHERE id = $1`,
        [existing.rows[0].id, name, index],
      );

      retainedIds.push(existing.rows[0].id);
      continue;
    }

    const inserted = await client.query(
      `INSERT INTO menu_categories (
         restaurant_id,
         name,
         sort_order
       )
       VALUES ($1, $2, $3)
       RETURNING id`,
      [restaurantId, name, index],
    );

    retainedIds.push(inserted.rows[0].id);
  }

  if (retainedIds.length === 0) {
    await client.query(
      'DELETE FROM menu_categories WHERE restaurant_id = $1',
      [restaurantId],
    );
    return;
  }

  await client.query(
    `DELETE FROM menu_categories
     WHERE restaurant_id = $1
       AND NOT (id = ANY($2::uuid[]))`,
    [restaurantId, retainedIds],
  );
}

function createRestaurantsRouter({ pool, authenticate, requireSelfOrAdmin }) {
  const router = express.Router();
  router.use(authenticate);

  router.get(
  '/owner/:userId/menu/categories',
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const restaurantId = await getRestaurantId(pool, ownerId);

      const result = await pool.query(
        `SELECT
           mc.id,
           mc.name,
           mc.sort_order,
           COUNT(mi.id)::integer AS item_count
         FROM menu_categories mc
         LEFT JOIN menu_items mi ON mi.category_id = mc.id
         WHERE mc.restaurant_id = $1
         GROUP BY mc.id
         ORDER BY mc.sort_order, mc.id`,
        [restaurantId],
      );

      return res.json({
        success: true,
        categories: result.rows.map(serializeMenuCategory),
      });
    } catch (error) {
      return next(error);
    }
  },
);

router.post(
  '/owner/:userId/menu/categories',
  requireSelfOrAdmin(),
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const input = categoryCreateSchema.parse(req.body);

      const category = await withTransaction(
        pool,
        async (client) => {
          const restaurantId = await getRestaurantId(
            client,
            ownerId,
          );

          let sortOrder = input.sortOrder;

          if (sortOrder === undefined) {
            const orderResult = await client.query(
              `SELECT
                 COALESCE(MAX(sort_order) + 1, 0) AS next_order
               FROM menu_categories
               WHERE restaurant_id = $1`,
              [restaurantId],
            );

            sortOrder = Number(
              orderResult.rows[0].next_order,
            );
          }

          const result = await client.query(
            `INSERT INTO menu_categories (
               restaurant_id,
               name,
               sort_order
             )
             VALUES ($1, $2, $3)
             RETURNING id, name, sort_order`,
            [restaurantId, input.name, sortOrder],
          );

          return serializeMenuCategory(result.rows[0]);
        },
      );

      return res.status(201).json({
        success: true,
        category,
      });
    } catch (error) {
      return next(error);
    }
  },
);

router.patch(
  '/owner/:userId/menu/categories/:categoryId',
  requireSelfOrAdmin(),
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const categoryId = categoryIdSchema.parse(
        req.params.categoryId,
      );
      const input = categoryUpdateSchema.parse(req.body);

      const result = await pool.query(
        `UPDATE menu_categories mc
         SET
           name = COALESCE($3, mc.name),
           sort_order = COALESCE($4, mc.sort_order)
         FROM restaurants r
         WHERE mc.id = $1
           AND mc.restaurant_id = r.id
           AND r.owner_id = $2
         RETURNING mc.id, mc.name, mc.sort_order`,
        [
          categoryId,
          ownerId,
          input.name ?? null,
          input.sortOrder ?? null,
        ],
      );

      if (!result.rows[0]) {
        throw createHttpError(
          404,
          'Menü kategorisi bulunamadı.',
        );
      }

      return res.json({
        success: true,
        category: serializeMenuCategory(result.rows[0]),
      });
    } catch (error) {
      return next(error);
    }
  },
);

router.delete(
  '/owner/:userId/menu/categories/:categoryId',
  requireSelfOrAdmin(),
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const categoryId = categoryIdSchema.parse(
        req.params.categoryId,
      );

      const result = await pool.query(
        `DELETE FROM menu_categories mc
         USING restaurants r
         WHERE mc.id = $1
           AND mc.restaurant_id = r.id
           AND r.owner_id = $2
         RETURNING mc.id`,
        [categoryId, ownerId],
      );

      if (!result.rows[0]) {
        throw createHttpError(
          404,
          'Menü kategorisi bulunamadı.',
        );
      }

      return res.json({
        success: true,
      });
    } catch (error) {
      return next(error);
    }
  },
);

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
        await syncMenuCategories(client, result.rows[0].id, input.menuCategories);
      });
      return res.json(await getRestaurant(pool, ownerId));
    } catch (error) {
      return next(error);
    }
  });

router.get(
  '/owner/:userId/menu/categories/:categoryId/items',
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const categoryId = categoryIdSchema.parse(
        req.params.categoryId,
      );

      await getOwnedCategoryId(
        pool,
        ownerId,
        categoryId,
      );

      const result = await pool.query(
        `SELECT
           id,
           category_id,
           name,
           description,
           price,
           is_available,
           sort_order,
           created_at
         FROM menu_items
         WHERE category_id = $1
         ORDER BY sort_order, id`,
        [categoryId],
      );

      return res.json({
        success: true,
        items: result.rows.map(serializeMenuItem),
      });
    } catch (error) {
      return next(error);
    }
  },
);

router.post(
  '/owner/:userId/menu/categories/:categoryId/items',
  requireSelfOrAdmin(),
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const categoryId = categoryIdSchema.parse(
        req.params.categoryId,
      );
      const input = menuItemCreateSchema.parse(req.body);

      const item = await withTransaction(
        pool,
        async (client) => {
          await getOwnedCategoryId(
            client,
            ownerId,
            categoryId,
          );

          let sortOrder = input.sortOrder;

          if (sortOrder === undefined) {
            const orderResult = await client.query(
              `SELECT
                 COALESCE(MAX(sort_order) + 1, 0) AS next_order
               FROM menu_items
               WHERE category_id = $1`,
              [categoryId],
            );

            sortOrder = Number(
              orderResult.rows[0].next_order,
            );
          }

          const result = await client.query(
            `INSERT INTO menu_items (
               category_id,
               name,
               description,
               price,
               is_available,
               sort_order
             )
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING
               id,
               category_id,
               name,
               description,
               price,
               is_available,
               sort_order,
               created_at`,
            [
              categoryId,
              input.name,
              input.description,
              input.price,
              input.isAvailable,
              sortOrder,
            ],
          );

          return serializeMenuItem(result.rows[0]);
        },
      );

      return res.status(201).json({
        success: true,
        item,
      });
    } catch (error) {
      return next(error);
    }
  },
);

router.patch(
  '/owner/:userId/menu/items/:itemId',
  requireSelfOrAdmin(),
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const itemId = menuItemIdSchema.parse(
        req.params.itemId,
      );
      const input = menuItemUpdateSchema.parse(req.body);

      const result = await pool.query(
        `UPDATE menu_items mi
         SET
           name = COALESCE($3, mi.name),
           description = COALESCE($4, mi.description),
           price = COALESCE($5, mi.price),
           is_available = COALESCE(
             $6,
             mi.is_available
           ),
           sort_order = COALESCE(
             $7,
             mi.sort_order
           )
         FROM menu_categories mc, restaurants r
         WHERE mi.id = $1
           AND mi.category_id = mc.id
           AND mc.restaurant_id = r.id
           AND r.owner_id = $2
         RETURNING
           mi.id,
           mi.category_id,
           mi.name,
           mi.description,
           mi.price,
           mi.is_available,
           mi.sort_order,
           mi.created_at`,
        [
          itemId,
          ownerId,
          input.name ?? null,
          input.description ?? null,
          input.price ?? null,
          input.isAvailable ?? null,
          input.sortOrder ?? null,
        ],
      );

      if (!result.rows[0]) {
        throw createHttpError(
          404,
          'Menü ürünü bulunamadı.',
        );
      }

      return res.json({
        success: true,
        item: serializeMenuItem(result.rows[0]),
      });
    } catch (error) {
      return next(error);
    }
  },
);

router.delete(
  '/owner/:userId/menu/items/:itemId',
  requireSelfOrAdmin(),
  async (req, res, next) => {
    try {
      const ownerId = userIdSchema.parse(req.params.userId);
      const itemId = menuItemIdSchema.parse(
        req.params.itemId,
      );

      const result = await pool.query(
        `DELETE FROM menu_items mi
         USING menu_categories mc, restaurants r
         WHERE mi.id = $1
           AND mi.category_id = mc.id
           AND mc.restaurant_id = r.id
           AND r.owner_id = $2
         RETURNING mi.id`,
        [itemId, ownerId],
      );

      if (!result.rows[0]) {
        throw createHttpError(
          404,
          'Menü ürünü bulunamadı.',
        );
      }

      return res.json({
        success: true,
      });
    } catch (error) {
      return next(error);
    }
  },
);

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
        await syncMenuCategories(client, result.rows[0].id, categories);
      });
      return res.json(normalizeCategoryNames(categories));
    } catch (error) {
      return next(error);
    }
  });

  return router;
}

module.exports = {
  createRestaurantsRouter,
  getRestaurant,
  normalizeCategoryNames,
  serializeMenuCategory,
  serializeMenuItem,
  getRestaurantId,
  getOwnedCategoryId,
  syncMenuCategories,
};