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
      category: notice.category,
      click_action: 'FLUTTER_NOTIFICATION_CLICK' // Required for background click actions in older SDK versions
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

module.exports = {
  sendNoticeNotification,
};
