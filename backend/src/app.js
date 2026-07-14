const express = require('express');
const cors = require('cors');
const { createAuthMiddleware } = require('./middleware/auth');
const { notFound, errorHandler } = require('./middleware/errors');
const { createAuthRouter } = require('./routes/auth');
const { createProfilesRouter } = require('./routes/profiles');
const { createRestaurantsRouter } = require('./routes/restaurants');
const { createAdminRouter } = require('./routes/admin');

function createApp({ pool, config }) {
  const app = express();
  const api = express.Router();
  const auth = createAuthMiddleware(config.JWT_SECRET);

  app.disable('x-powered-by');
  app.use(cors({
    origin(origin, callback) {
      if (!origin || config.corsOrigins.includes(origin)) return callback(null, true);
      const error = new Error('CORS kaynağına izin verilmiyor.');
      error.status = 403;
      return callback(error);
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }));
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', async (req, res, next) => {
    try {
      await pool.query('SELECT 1');
      res.json({ success: true });
    } catch (error) {
      next(error);
    }
  });
  api.use('/auth', createAuthRouter({
    pool,
    jwtSecret: config.JWT_SECRET,
    authenticate: auth.authenticate,
  }));
  api.use('/users', createProfilesRouter({
    pool,
    authenticate: auth.authenticate,
    requireSelfOrAdmin: auth.requireSelfOrAdmin,
  }));
  api.use('/restaurants', createRestaurantsRouter({
    pool,
    authenticate: auth.authenticate,
    requireSelfOrAdmin: auth.requireSelfOrAdmin,
  }));
  api.use('/admin', createAdminRouter({
    pool,
    authenticate: auth.authenticate,
    requireAdmin: auth.requireAdmin,
  }));
  app.use('/api/v1', api);
  app.use('/v1', api);

  app.use(notFound);
  app.use(errorHandler);
  return app;
}

module.exports = { createApp };
