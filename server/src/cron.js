const cron = require('node-cron');
const { db, admin } = require('./firebase');
const { fetchLatestEmails, getEmailDetails } = require('./gmail');
const { sendNoticeNotification } = require('./notifier');

/**
 * Main notice synchronization pipeline.
 * Fetches matching emails, filters duplicates, saves, and broadcasts notifications.
 */
async function syncNotices() {
  console.log('[Sync] Starting notice sync pipeline...');
  let importedCount = 0;
  let failedCount = 0;

  try {
    // Perform a quick test read to verify if Firestore Database has been created in the Firebase console
    try {
      if (process.env.FIREBASE_PROJECT_ID && !process.env.FIREBASE_PROJECT_ID.includes('placeholder')) {
        await db.collection('notices').limit(1).get();
      }
    } catch (dbError) {
      if (dbError.message.includes('NOT_FOUND') || dbError.code === 5) {
        console.error('\n❌ ======================================================================');
        console.error('⚠️  FIREBASE FIRESTORE DATABASE NOT CREATED IN FIREBASE CONSOLE!');
        console.error('👉 Please go to: https://console.firebase.google.com/project/' + process.env.FIREBASE_PROJECT_ID + '/firestore');
        console.error('👉 Click the "Create Database" button to enable Firestore Database.');
        console.error('👉 Also make sure to enable "Storage" under the Build menu for attachments.');
        console.error('======================================================================\n');
        return { success: false, error: 'Firestore Database not created in Firebase Console' };
      }
      throw dbError;
    }

    const emails = await fetchLatestEmails();
    console.log(`[Sync] Found ${emails.length} matching email messages.`);

    // Fetch existing messageIds once at startup of the sync run
    const noticesSnapshot = await db.collection('notices').select('messageId').get();
    const existingMessageIds = new Set();
    noticesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.messageId) {
        existingMessageIds.add(data.messageId);
      }
    });

    // Process from oldest to newest to ensure chronological insertion
    const reversedEmails = [...emails].reverse();

    for (const email of reversedEmails) {
      try {
        const messageId = email.id;

        // Fast in-memory duplicate check
        if (existingMessageIds.has(messageId)) {
          continue;
        }

        console.log(`[Sync] Message ${messageId} is new. Parsing details...`);
        const parsedNotice = await getEmailDetails(messageId);

        // Prepare document payload
        const noticeDoc = {
          ...parsedNotice,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Save to Firestore
        const docRef = await db.collection('notices').add(noticeDoc);
        console.log(`[Sync] Notice stored with ID: ${docRef.id}`);

        // Broadcast push notification
        await sendNoticeNotification(docRef.id, noticeDoc);
        importedCount++;
      } catch (err) {
        console.error(`[Sync] Failed to process email message ${email.id}:`, err.stack);
        failedCount++;
      }
    }

    console.log(`[Sync] Notice sync complete. Imported: ${importedCount}, Failed: ${failedCount}`);
    return {
      success: true,
      imported: importedCount,
      failed: failedCount
    };
  } catch (error) {
    console.error('[Sync] General error in notice sync pipeline:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Schedules the cron job to run every 5 minutes.
 */
function initCron() {
  // Cron schedule: */5 * * * * (Every 5 minutes)
  cron.schedule('*/5 * * * *', () => {
    console.log('[Cron] Triggering scheduled notice sync...');
    syncNotices().catch(err => {
      console.error('[Cron] Unhandled error during scheduled sync:', err);
    });
  });
  console.log('Sync service cron scheduled: runs every 5 minutes.');
}

module.exports = {
  syncNotices,
  initCron
};
