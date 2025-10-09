// Simple API key authentication middleware
const authMiddleware = (req, res, next) => {
  const apiKey = req.headers['authorization'];
  const expectedKey = process.env.API_KEY;

  // Skip auth for health endpoints
  if (req.path.startsWith('/health')) {
    return next();
  }

  if (!expectedKey) {
    console.warn('⚠️  API_KEY not configured - authentication disabled');
    return next();
  }

  if (!apiKey) {
    return res.status(401).json({
      error: 'Authentication required',
      code: 'MISSING_AUTH_HEADER'
    });
  }

  // Extract Bearer token or use direct API key
  const token = apiKey.startsWith('Bearer ') 
    ? apiKey.substring(7) 
    : apiKey;

  if (token !== expectedKey) {
    console.warn(`⚠️  Authentication failed from IP: ${req.ip}`);
    return res.status(401).json({
      error: 'Invalid authentication credentials',
      code: 'INVALID_AUTH'
    });
  }

  // Authentication successful
  next();
};

module.exports = authMiddleware;