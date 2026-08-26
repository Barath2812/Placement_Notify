const { messaging } = require('./firebase');

/**
 * Sends a push notification to all users subscribed to the 'college-notices' topic.
 * 
 * @param {string} noticeId - Firestore document ID of the notice
 * @param {object} notice - Notice data
 */
async function sendNoticeNotification(noticeId, notice) {
  const shortBody = notice.bodyText 
    ? (notice.bodyText.length > 100 ? `${notice.bodyText.substring(0, 97)}...` : notice.bodyText)
    : 'New notice uploaded.';

  const message = {
    notification: {
      title: notice.subject,
      body: `[${notice.category}] ${shortBody}`,
    },
    // Custom data payload sent to Flutter app
    data: {
      noticeId: noticeId,
      category: notice.category || 'General',
      click_action: 'FLUTTER_NOTIFICATION_CLICK' // Required for background click actions
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'campus_notices_channel',
        priority: 'max',
        defaultSound: true,
        defaultVibrateTimings: true,
        icon: '@mipmap/ic_launcher',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
    topic: 'college-notices',
  };

  try {
    const response = await messaging.send(message);
    console.log(`Successfully sent push notification for notice ID: ${noticeId}. Message ID:`, response);
    return response;
  } catch (error) {
    console.error(`Error sending push notification for notice ${noticeId}:`, error.message);
    // Don't throw the error, allow the sync flow to continue
    return null;
  }
}

/**
 * Sends a test notification via the 'college-notices' topic.
 * Used to verify that FCM topic delivery is working end-to-end.
 */
async function sendTestNotificationToTopic() {
  const message = {
    notification: {
      title: '🔔 CampusNotify Test',
      body: 'FCM topic delivery is working correctly!',
    },
    data: {
      noticeId: 'test_notification',
      category: 'Test',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'campus_notices_channel',
        priority: 'max',
        defaultSound: true,
        defaultVibrateTimings: true,
        icon: '@mipmap/ic_launcher',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
    topic: 'college-notices',
  };

  try {
    console.log('[FCM Test] Sending test notification to topic: college-notices');
    console.log('[FCM Test] Payload:', JSON.stringify(message, null, 2));
    const response = await messaging.send(message);
    console.log('[FCM Test] ✅ Successfully sent topic notification. FCM Message ID:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('[FCM Test] ❌ Error sending topic notification:', error.code, error.message);
    return { success: false, error: error.message, code: error.code };
  }
}

/**
 * Sends a test notification directly to a specific FCM token.
 * Used to verify direct token delivery independently of topic subscription.
 * 
 * @param {string} fcmToken - The device FCM token to send to
 */
async function sendTestNotificationToToken(fcmToken) {
  const message = {
    notification: {
      title: '🔔 CampusNotify Test (Direct)',
      body: 'FCM direct token delivery is working!',
    },
    data: {
      noticeId: 'test_notification_direct',
      category: 'Test',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'campus_notices_channel',
        priority: 'max',
        defaultSound: true,
        defaultVibrateTimings: true,
        icon: '@mipmap/ic_launcher',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
    token: fcmToken,
  };

  try {
    console.log('[FCM Test] Sending test notification to token:', fcmToken.substring(0, 20) + '...');
    console.log('[FCM Test] Payload:', JSON.stringify(message, null, 2));
    const response = await messaging.send(message);
    console.log('[FCM Test] ✅ Successfully sent direct notification. FCM Message ID:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('[FCM Test] ❌ Error sending direct notification:', error.code, error.message);
    return { success: false, error: error.message, code: error.code };
  }
}

module.exports = {
  sendNoticeNotification,
  sendTestNotificationToTopic,
  sendTestNotificationToToken,
};
