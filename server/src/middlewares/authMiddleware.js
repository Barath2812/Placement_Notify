const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'campusnotify_jwt_secret_key_123';

/**
 * Express middleware to authenticate requests using JSON Web Tokens (JWT).
 * Expects header: Authorization: Bearer <JWT_Token>
 */
async function authenticateUser(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: No token provided' });
  }

  const token = authHeader.split('Bearer ')[1];

  // Keep 'mock_token' fallback for initial setup diagnostics
  if (token === 'mock_token') {
    req.user = {
      uid: 'demo_student_id_123',
      name: 'Demo Student',
      email: 'student@sathyabama.ac.in'
    };
    return next();
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // decoded contains { uid, name }
    next();
  } catch (error) {
    console.error('Error verifying JWT token in AuthMiddleware:', error.message);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
}

module.exports = {
  authenticateUser
};
