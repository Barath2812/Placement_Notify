const express = require('express');
const router = express.Router();
const { handleLogin, handleGetProfile } = require('../controllers/authController');
const { authenticateUser } = require('../middlewares/authMiddleware');

// Route: POST /auth/login
// Verifies credentials, registers if new, and issues JWT access token
router.post('/login', handleLogin);

// Route: GET /auth/me
// Restores user profile using the JWT authorization token
router.get('/me', authenticateUser, handleGetProfile);

module.exports = router;
