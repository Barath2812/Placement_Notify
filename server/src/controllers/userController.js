const { db, admin } = require('../firebase');

/**
 * POST /users/token
 * Register or update the user's FCM token.
 */
async function updateFcmToken(req, res) {
  const { fcmToken } = req.body;
  const { uid } = req.user;

  if (!fcmToken) {
    return res.status(400).json({ error: 'FCM Token is required.' });
  }

  try {
    const userRef = db.collection('users').doc(uid);
    await userRef.update({
      fcmToken: fcmToken,
      lastLogin: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Updated FCM token for user ${uid}`);
    res.status(200).json({ success: true, message: 'FCM token updated successfully.' });
  } catch (error) {
    console.error('Error updating FCM token:', error.message);
    res.status(500).json({ error: 'Failed to update FCM token.' });
  }
}

/**
 * POST /bookmarks/:id
 * Add a notice ID to the user's bookmark list.
 */
async function addBookmark(req, res) {
  const { id } = req.params; // noticeId
  const { uid } = req.user;

  try {
    // Verify notice exists first
    const noticeDoc = await db.collection('notices').doc(id).get();
    if (!noticeDoc.exists) {
      return res.status(404).json({ error: 'Notice not found.' });
    }

    const userRef = db.collection('users').doc(uid);
    await userRef.update({
      bookmarks: admin.firestore.FieldValue.arrayUnion(id)
    });

    console.log(`User ${uid} bookmarked notice ${id}`);
    res.status(200).json({ success: true, message: 'Notice bookmarked successfully.' });
  } catch (error) {
    console.error('Error adding bookmark:', error.message);
    res.status(500).json({ error: 'Failed to add bookmark.' });
  }
}

/**
 * DELETE /bookmarks/:id
 * Remove a notice ID from the user's bookmark list.
 */
async function removeBookmark(req, res) {
  const { id } = req.params; // noticeId
  const { uid } = req.user;

  try {
    const userRef = db.collection('users').doc(uid);
    await userRef.update({
      bookmarks: admin.firestore.FieldValue.arrayRemove(id)
    });

    console.log(`User ${uid} removed bookmark for notice ${id}`);
    res.status(200).json({ success: true, message: 'Bookmark removed successfully.' });
  } catch (error) {
    console.error('Error removing bookmark:', error.message);
    res.status(500).json({ error: 'Failed to remove bookmark.' });
  }
}

/**
 * POST /users/read/:id
 * Mark a notice as read.
 */
async function markNoticeAsRead(req, res) {
  const { id } = req.params; // noticeId
  const { uid } = req.user;

  try {
    const userRef = db.collection('users').doc(uid);
    await userRef.update({
      readNotices: admin.firestore.FieldValue.arrayUnion(id)
    });

    console.log(`User ${uid} marked notice ${id} as read`);
    res.status(200).json({ success: true, message: 'Notice marked as read.' });
  } catch (error) {
    console.error('Error marking notice as read:', error.message);
    res.status(500).json({ error: 'Failed to update read status.' });
  }
}

module.exports = {
  updateFcmToken,
  addBookmark,
  removeBookmark,
  markNoticeAsRead
};
