const jwt = require('jsonwebtoken');

function createAuthMiddleware(jwtSecret) {
  function authenticate(req, res, next) {
    const [scheme, token] = (req.headers.authorization || '').split(' ');
    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ success: false, message: 'Kimlik doğrulama gerekli.' });
    }

    try {
      req.auth = jwt.verify(token, jwtSecret);
      return next();
    } catch {
      return res.status(401).json({ success: false, message: 'Geçersiz veya süresi dolmuş token.' });
    }
  }

  function requireAdmin(req, res, next) {
    if (req.auth?.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Yönetici yetkisi gerekli.' });
    }
    return next();
  }

  function requireSelfOrAdmin(parameter = 'userId') {
    return (req, res, next) => {
      if (req.auth?.role !== 'admin' && req.auth?.sub !== req.params[parameter]) {
        return res.status(403).json({ success: false, message: 'Bu işlem için yetkiniz yok.' });
      }
      return next();
    };
  }

  return { authenticate, requireAdmin, requireSelfOrAdmin };
}

module.exports = { createAuthMiddleware };
