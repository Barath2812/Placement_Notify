const express = require('express');
const router = express.Router();
const { db } = require('../firebase');
const { sendTestNotificationToTopic, sendTestNotificationToToken } = require('../notifier');
const { authenticateUser } = require('../middlewares/authMiddleware');

/**
 * POST /notifications/test
 * Sends a test FCM notification via the 'college-notices' topic.
 * This tests the exact same path used by production notice notifications.
 */
router.post('/test', authenticateUser, async (req, res) => {
  const { uid } = req.user;
  console.log(`[FCM Test] User ${uid} triggered topic test notification.`);

  try {
    const result = await sendTestNotificationToTopic();

    if (result.success) {
      res.status(200).json({
        success: true,
        message: 'Test notification sent via topic. Check your device.',
        fcmMessageId: result.messageId,
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'FCM topic send failed.',
        error: result.error,
        code: result.code,
      });
    }
  } catch (error) {
    console.error('[FCM Test] Unexpected error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /notifications/test-token
 * Sends a test FCM notification directly to the authenticated user's stored FCM token.
 * This tests direct token delivery independently of topic subscription.
 */
router.post('/test-token', authenticateUser, async (req, res) => {
  const { uid } = req.user;
  console.log(`[FCM Test] User ${uid} triggered direct token test notification.`);

  try {
    // Fetch user's stored FCM token from Firestore
    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'User document not found in Firestore.',
      });
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken || fcmToken === 'mock_token' || fcmToken === 'mock_fcm_token_xyz') {
      return res.status(400).json({
        success: false,
        message: 'No valid FCM token stored for this user.',
        storedToken: fcmToken ? fcmToken.substring(0, 20) + '...' : null,
      });
    }

    console.log(`[FCM Test] Found stored token for user ${uid}: ${fcmToken.substring(0, 20)}...`);

    const result = await sendTestNotificationToToken(fcmToken);

    if (result.success) {
      res.status(200).json({
        success: true,
        message: 'Test notification sent directly to your device token. Check your device.',
        fcmMessageId: result.messageId,
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'FCM direct token send failed.',
        error: result.error,
        code: result.code,
      });
    }
  } catch (error) {
    console.error('[FCM Test] Unexpected error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
