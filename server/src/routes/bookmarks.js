const express = require('express');
const router = express.Router();
const { addBookmark, removeBookmark } = require('../controllers/userController');
const { authenticateUser } = require('../middlewares/authMiddleware');

// Route: POST /bookmarks/:id (Add bookmark)
// Route: DELETE /bookmarks/:id (Remove bookmark)
router.post('/:id', authenticateUser, addBookmark);
router.delete('/:id', authenticateUser, removeBookmark);

module.exports = router;
