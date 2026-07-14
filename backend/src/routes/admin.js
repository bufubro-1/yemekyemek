const express = require('express');
const bcrypt = require('bcrypt');
const { z } = require('zod');

const PROTECTED_COLUMNS = new Set(['password_hash']);
const paginationSchema = z.object({
  limit: z.coerce.number().int().min(1).max(200).optional(),
  offset: z.coerce.number().int().min(0).optional(),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(200).optional(),
});
const valuesSchema = z.record(z.string(), z.unknown());
const updateSchema = z.object({
  pk: valuesSchema,
  values: valuesSchema,
}).strict();
const deleteSchema = z.object({ pk: valuesSchema }).strict();
const userQuerySchema = paginationSchema.extend({
  search: z.string().trim().max(255).default(''),
});
const roleSchema = z.object({
  role: z.enum(['user', 'restaurant_owner', 'admin']),
}).strict();
const passwordSchema = z.object({
  password: z.string().min(8).max(128),
}).strict();

function quoteIdentifier(identifier) {
  return `"${identifier.replaceAll('"', '""')}"`;
}

async function discoverTables(pool) {
  const result = await pool.query(
    `SELECT t.table_name
     FROM information_schema.tables t
     WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
     ORDER BY t.table_name`,
  );
  return result.rows.map((row) => row.table_name);
}

async function getTableMetadata(pool, tableName) {
  const table = await pool.query(
    `SELECT EXISTS (
       SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name = $1
     ) AS exists`,
    [tableName],
  );
  if (!table.rows[0].exists) return null;

  const [columns, primaryKeys] = await Promise.all([
    pool.query(
      `SELECT column_name, data_type, udt_name, is_nullable, column_default,
              is_identity, is_generated
       FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = $1
       ORDER BY ordinal_position`,
      [tableName],
    ),
    pool.query(
      `SELECT kcu.column_name
       FROM information_schema.table_constraints tc
       JOIN information_schema.key_column_usage kcu
         ON kcu.constraint_name = tc.constraint_name
        AND kcu.constraint_schema = tc.constraint_schema
        AND kcu.table_name = tc.table_name
       WHERE tc.table_schema = 'public'
         AND tc.table_name = $1
         AND tc.constraint_type = 'PRIMARY KEY'
       ORDER BY kcu.ordinal_position`,
      [tableName],
    ),
  ]);

  return {
    name: tableName,
    columns: columns.rows.map((column) => ({
      ...column,
      protected: PROTECTED_COLUMNS.has(column.column_name),
    })),
    primaryKey: primaryKeys.rows.map((row) => row.column_name),
  };
}

function validateColumns(metadata, input, { allowPrimaryKey = true } = {}) {
  const columns = new Map(metadata.columns.map((column) => [column.column_name, column]));
  for (const name of Object.keys(input)) {
    const column = columns.get(name);
    if (!column) {
      const error = new Error(`Geçersiz sütun: ${name}`);
      error.status = 400;
      throw error;
    }
    if (column.protected) {
      const error = new Error(`${name} sütununa yönetici gezgini üzerinden erişilemez.`);
      error.status = 403;
      throw error;
    }
    if (!allowPrimaryKey && metadata.primaryKey.includes(name)) {
      const error = new Error('Birincil anahtar sütunları güncellenemez.');
      error.status = 400;
      throw error;
    }
  }
}

function buildPrimaryKeyWhere(metadata, pk, startIndex = 1) {
  if (metadata.primaryKey.length === 0) {
    const error = new Error('Tabloda birincil anahtar olmadığı için bu işlem desteklenmiyor.');
    error.status = 400;
    throw error;
  }
  const keys = Object.keys(pk);
  if (keys.length !== metadata.primaryKey.length || metadata.primaryKey.some((key) => !(key in pk))) {
    const error = new Error(`Birincil anahtar alanları gerekli: ${metadata.primaryKey.join(', ')}`);
    error.status = 400;
    throw error;
  }
  validateColumns(metadata, pk);
  return {
    sql: metadata.primaryKey
      .map((key, index) => `${quoteIdentifier(key)} = $${startIndex + index}`)
      .join(' AND '),
    values: metadata.primaryKey.map((key) => pk[key]),
  };
}

function safeColumns(metadata) {
  return metadata.columns.filter((column) => !column.protected).map((column) => column.column_name);
}

function paginationValues(query) {
  const parsed = paginationSchema.parse(query);
  const limit = parsed.pageSize || parsed.limit || 50;
  return {
    limit,
    offset: parsed.offset ?? (parsed.page - 1) * limit,
    page: parsed.offset === undefined ? parsed.page : Math.floor(parsed.offset / limit) + 1,
  };
}

function createAdminRouter({ pool, authenticate, requireAdmin }) {
  const router = express.Router();
  router.use(authenticate, requireAdmin);

  router.get('/overview', async (req, res, next) => {
    try {
      const tables = await discoverTables(pool);
      const overview = await Promise.all(tables.map(async (tableName) => {
        const metadata = await getTableMetadata(pool, tableName);
        const result = await pool.query(
          `SELECT count(*)::integer AS count FROM public.${quoteIdentifier(metadata.name)}`,
        );
        return { name: tableName, count: result.rows[0].count };
      }));
      return res.json({ data: overview });
    } catch (error) {
      return next(error);
    }
  });

  router.get('/users', async (req, res, next) => {
    try {
      const query = userQuerySchema.parse(req.query);
      const pagination = paginationValues(query);
      const search = `%${query.search}%`;
      const rowsWhere = query.search
        ? `WHERE email ILIKE $3 OR nickname ILIKE $3 OR username ILIKE $3`
        : '';
      const countWhere = query.search
        ? `WHERE email ILIKE $1 OR nickname ILIKE $1 OR username ILIKE $1`
        : '';
      const parameters = query.search
        ? [pagination.limit, pagination.offset, search]
        : [pagination.limit, pagination.offset];
      const [users, count] = await Promise.all([
        pool.query(
          `SELECT id, nickname, username AS name, email, role, created_at
           FROM users ${rowsWhere} ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
          parameters,
        ),
        pool.query(
          `SELECT count(*)::integer AS count FROM users ${countWhere}`,
          query.search ? [search] : [],
        ),
      ]);
      const total = count.rows[0].count;
      return res.json({
        users: users.rows,
        pagination: {
          total,
          page: pagination.page,
          pageSize: pagination.limit,
          totalPages: Math.max(1, Math.ceil(total / pagination.limit)),
        },
      });
    } catch (error) {
      return next(error);
    }
  });

  router.patch('/users/:id', async (req, res, next) => {
    try {
      const id = z.string().uuid().parse(req.params.id);
      const input = roleSchema.parse(req.body);
      if (id === req.auth.sub && input.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Kendi yönetici rolünüzü kaldıramazsınız.' });
      }
      const result = await pool.query(
        `UPDATE users SET role = $1 WHERE id = $2
         RETURNING id, nickname, username AS name, email, role, created_at`,
        [input.role, id],
      );
      if (!result.rows[0]) return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
      return res.json(result.rows[0]);
    } catch (error) {
      return next(error);
    }
  });

  router.patch('/users/:id/password', async (req, res, next) => {
    try {
      const id = z.string().uuid().parse(req.params.id);
      const input = passwordSchema.parse(req.body);
      const passwordHash = await bcrypt.hash(input.password, 12);
      const result = await pool.query(
        'UPDATE users SET password_hash = $1 WHERE id = $2',
        [passwordHash, id],
      );
      if (result.rowCount === 0) return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
      return res.status(204).end();
    } catch (error) {
      return next(error);
    }
  });

  router.delete('/users/:id', async (req, res, next) => {
    try {
      const id = z.string().uuid().parse(req.params.id);
      if (id === req.auth.sub) {
        return res.status(403).json({ success: false, message: 'Kendi yönetici hesabınızı silemezsiniz.' });
      }
      const result = await pool.query('DELETE FROM users WHERE id = $1', [id]);
      if (result.rowCount === 0) return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
      return res.status(204).end();
    } catch (error) {
      return next(error);
    }
  });

  router.get('/tables', async (req, res, next) => {
    try {
      const tables = await discoverTables(pool);
      const metadata = await Promise.all(tables.map(async (table) => {
        const [details, count] = await Promise.all([
          getTableMetadata(pool, table),
          pool.query(`SELECT count(*)::integer AS count FROM public.${quoteIdentifier(table)}`),
        ]);
        return { ...details, rowCount: count.rows[0].count };
      }));
      return res.json({ tables: metadata });
    } catch (error) {
      return next(error);
    }
  });

  router.get('/tables/:table', async (req, res, next) => {
    try {
      const pagination = paginationValues(req.query);
      const metadata = await getTableMetadata(pool, req.params.table);
      if (!metadata) return res.status(404).json({ success: false, message: 'Tablo bulunamadı.' });
      const selected = safeColumns(metadata);
      const orderBy = metadata.primaryKey.length
        ? ` ORDER BY ${metadata.primaryKey.map(quoteIdentifier).join(', ')}`
        : '';
      const table = quoteIdentifier(metadata.name);
      const [rows, count] = await Promise.all([
        pool.query(
          `SELECT ${selected.map(quoteIdentifier).join(', ')} FROM public.${table}${orderBy} LIMIT $1 OFFSET $2`,
          [pagination.limit, pagination.offset],
        ),
        pool.query(`SELECT count(*)::integer AS count FROM public.${table}`),
      ]);
      return res.json({
        rows: rows.rows,
        columns: metadata.columns.filter((column) => !column.protected),
        primaryKeys: metadata.primaryKey,
        total: count.rows[0].count,
        limit: pagination.limit,
        offset: pagination.offset,
        page: pagination.page,
        pageSize: pagination.limit,
        totalPages: Math.max(1, Math.ceil(count.rows[0].count / pagination.limit)),
      });
    } catch (error) {
      return next(error);
    }
  });

  router.post('/tables/:table', async (req, res, next) => {
    try {
      const values = valuesSchema.parse(req.body);
      const metadata = await getTableMetadata(pool, req.params.table);
      if (!metadata) return res.status(404).json({ success: false, message: 'Tablo bulunamadı.' });
      validateColumns(metadata, values);
      const entries = Object.entries(values);
      if (entries.length === 0) {
        return res.status(400).json({ success: false, message: 'En az bir alan gerekli.' });
      }
      const columns = entries.map(([name]) => quoteIdentifier(name));
      const parameters = entries.map((_, index) => `$${index + 1}`);
      const returning = safeColumns(metadata).map(quoteIdentifier).join(', ');
      const result = await pool.query(
        `INSERT INTO public.${quoteIdentifier(metadata.name)} (${columns.join(', ')})
         VALUES (${parameters.join(', ')}) RETURNING ${returning}`,
        entries.map(([, value]) => value),
      );
      return res.status(201).json(result.rows[0]);
    } catch (error) {
      return next(error);
    }
  });

  const updateTableRow = async (req, res, next) => {
    try {
      const input = updateSchema.parse(req.body.primaryKey
        ? { pk: req.body.primaryKey, values: req.body.changes }
        : req.body);
      const metadata = await getTableMetadata(pool, req.params.table);
      if (!metadata) return res.status(404).json({ success: false, message: 'Tablo bulunamadı.' });
      validateColumns(metadata, input.values, { allowPrimaryKey: false });
      if (
        metadata.name === 'users'
        && String(input.pk.id) === String(req.auth.sub)
        && input.values.role !== undefined
        && input.values.role !== 'admin'
      ) {
        return res.status(403).json({
          success: false,
          message: 'Kendi yönetici rolünüzü kaldıramazsınız.',
        });
      }
      const entries = Object.entries(input.values);
      if (entries.length === 0) {
        return res.status(400).json({ success: false, message: 'En az bir güncellenecek alan gerekli.' });
      }
      const where = buildPrimaryKeyWhere(metadata, input.pk, entries.length + 1);
      const assignments = entries.map(
        ([name], index) => `${quoteIdentifier(name)} = $${index + 1}`,
      );
      const returning = safeColumns(metadata).map(quoteIdentifier).join(', ');
      const result = await pool.query(
        `UPDATE public.${quoteIdentifier(metadata.name)} SET ${assignments.join(', ')}
         WHERE ${where.sql} RETURNING ${returning}`,
        [...entries.map(([, value]) => value), ...where.values],
      );
      if (!result.rows[0]) return res.status(404).json({ success: false, message: 'Kayıt bulunamadı.' });
      return res.json(result.rows[0]);
    } catch (error) {
      return next(error);
    }
  };
  router.put('/tables/:table', updateTableRow);
  router.patch('/tables/:table/rows', updateTableRow);

  const deleteTableRow = async (req, res, next) => {
    try {
      const input = deleteSchema.parse(req.body.primaryKey
        ? { pk: req.body.primaryKey }
        : req.body);
      const metadata = await getTableMetadata(pool, req.params.table);
      if (!metadata) return res.status(404).json({ success: false, message: 'Tablo bulunamadı.' });
      const where = buildPrimaryKeyWhere(metadata, input.pk);
      if (metadata.name === 'users' && String(input.pk.id) === String(req.auth.sub)) {
        return res.status(403).json({ success: false, message: 'Kendi yönetici hesabınızı silemezsiniz.' });
      }
      const result = await pool.query(
        `DELETE FROM public.${quoteIdentifier(metadata.name)} WHERE ${where.sql}`,
        where.values,
      );
      if (result.rowCount === 0) return res.status(404).json({ success: false, message: 'Kayıt bulunamadı.' });
      return res.status(204).end();
    } catch (error) {
      return next(error);
    }
  };
  router.delete('/tables/:table', deleteTableRow);
  router.delete('/tables/:table/rows', deleteTableRow);

  return router;
}

module.exports = {
  createAdminRouter,
  quoteIdentifier,
  getTableMetadata,
  buildPrimaryKeyWhere,
  validateColumns,
};
