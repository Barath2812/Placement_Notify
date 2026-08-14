const express = require('express');
const router = express.Router();
const { 
  getNotices, 
  getNoticeById, 
  searchNotices, 
  triggerSync, 
  summarizeNotice 
} = require('../controllers/noticeController');
const { authenticateUser } = require('../middlewares/authMiddleware');

// Public or Authenticated routes depending on design. We secure them as requested.
router.get('/', authenticateUser, getNotices);
router.get('/search', authenticateUser, searchNotices);
router.get('/:id', authenticateUser, getNoticeById);

// Admin / utility routes (Authenticated)
router.post('/sync-now', authenticateUser, triggerSync);
router.post('/summarize', authenticateUser, summarizeNotice);

module.exports = router;
