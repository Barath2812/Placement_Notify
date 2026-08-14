const express = require('express');
const router = express.Router();
const { updateFcmToken, markNoticeAsRead } = require('../controllers/userController');
const { authenticateUser } = require('../middlewares/authMiddleware');

// Route: POST /users/token
// Registers student FCM device token for notifications
router.post('/token', authenticateUser, updateFcmToken);

// Route: POST /users/read/:id
// Marks a notice as read in the user's profile
router.post('/read/:id', authenticateUser, markNoticeAsRead);

module.exports = router;
