const { ZodError } = require('zod');

function notFound(req, res) {
  res.status(404).json({ success: false, message: 'Endpoint bulunamadı.' });
}

function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  if (error instanceof ZodError) {
    return res.status(400).json({
      success: false,
      message: 'İstek verileri geçersiz.',
      errors: error.issues.map((issue) => ({
        path: issue.path.join('.'),
        message: issue.message,
      })),
    });
  }

  if (error.code === '23505') {
    return res.status(409).json({ success: false, message: 'Bu kayıt zaten mevcut.' });
  }
  if (error.code === '23503' || error.code === '23514' || error.code === '22P02') {
    return res.status(400).json({ success: false, message: 'Veri veritabanı kurallarına uymuyor.' });
  }

  console.error(error);
  return res.status(error.status || 500).json({
    success: false,
    message: error.status ? error.message : 'Beklenmeyen bir sunucu hatası oluştu.',
  });
}

module.exports = { notFound, errorHandler };
