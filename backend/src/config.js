const { z } = require('zod');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().min(1),
  DATABASE_SSL: z.enum(['true', 'false']).default('false'),
  JWT_SECRET: z.string().min(32),
  CORS_ORIGIN: z.string().default('http://localhost:5173'),
  ADMIN_EMAIL: z.string().email().optional(),
  ADMIN_PASSWORD: z.string().min(12).optional(),
  ADMIN_NICKNAME: z.string().min(3).max(32).optional(),
  ADMIN_USERNAME: z.string().min(1).max(64).optional(),
});

function loadConfig(env = process.env) {
  const parsed = envSchema.safeParse(env);
  if (!parsed.success) {
    throw new Error(`Geçersiz ortam değişkenleri: ${z.prettifyError(parsed.error)}`);
  }

  const values = parsed.data;
  const adminFields = [
    values.ADMIN_EMAIL,
    values.ADMIN_PASSWORD,
    values.ADMIN_NICKNAME,
    values.ADMIN_USERNAME,
  ];
  if (adminFields.some(Boolean) && !adminFields.every(Boolean)) {
    throw new Error('ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_NICKNAME ve ADMIN_USERNAME birlikte tanımlanmalıdır.');
  }

  return {
    ...values,
    databaseSsl: values.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false,
    corsOrigins: values.CORS_ORIGIN.split(',').map((origin) => origin.trim()).filter(Boolean),
  };
}

module.exports = { loadConfig };
