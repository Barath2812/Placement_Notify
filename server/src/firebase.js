const admin = require('firebase-admin');
require('dotenv').config();

const projectId = process.env.FIREBASE_PROJECT_ID;
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
const privateKey = process.env.FIREBASE_PRIVATE_KEY;

let db;
let auth;
let messaging;
let storage;
let isInitialized = false;

// Check if credentials are placeholders or empty
const isConfigured = 
  projectId && 
  clientEmail && 
  privateKey && 
  projectId !== 'campusnotify-firebase-project-id' &&
  !projectId.startsWith('your_');

if (!isConfigured) {
  console.warn('\n======================================================================');
  console.warn('⚠️  WARNING: Firebase credentials are NOT fully configured in server/.env');
  console.warn('👉 Please copy server/.env.example to server/.env and fill in your values.');
  console.warn('🔌 Server will run in LOCAL-MOCK fallback mode for diagnostics.');
  console.warn('======================================================================\n');

  // Helper mocks for Firestore collections and filters
  const mockQuery = {
    where: () => mockQuery,
    orderBy: () => mockQuery,
    limit: () => ({
      get: async () => {
        // Return dummy notices list so home screen shows mock data
        const dummyNotices = [
          {
            id: 'mock_notice_1',
            messageId: 'gmail_id_1',
            subject: 'Semester Exam Hall Tickets Released',
            from: 'cse2027@sathyabama.ac.in',
            date: new Date().toISOString(),
            bodyText: 'Please download your exam hall tickets from the portal immediately. Clear all outstanding dues.',
            bodyHtml: '<p>Please download your exam hall tickets from the portal immediately.</p>',
            category: 'Exam',
            attachments: [],
            isImportant: true,
            createdAt: new Date()
          },
          {
            id: 'mock_notice_2',
            messageId: 'gmail_id_2',
            subject: 'Google Recruitment Placement Drive 2026',
            from: 'cse2027@sathyabama.ac.in',
            date: new Date(Date.now() - 3600000 * 2).toISOString(),
            bodyText: 'Software Engineer placement drive for final year students. Submit resumes before Saturday.',
            bodyHtml: '<p>Software Engineer placement drive for final year students.</p>',
            category: 'Placement',
            attachments: [{ name: 'job_description.pdf', url: 'https://www.google.com', mimeType: 'application/pdf' }],
            isImportant: true,
            createdAt: new Date()
          }
        ];

        return {
          empty: false,
          forEach: (callback) => {
            dummyNotices.forEach(notice => {
              callback({
                id: notice.id,
                data: () => notice
              });
            });
          }
        };
      }
    })
  };

  db = {
    collection: () => ({
      doc: (docId) => ({
        get: async () => ({
          exists: docId === 'demo_student_id_123',
          data: () => ({
            uid: 'demo_student_id_123',
            name: 'Demo Student',
            email: 'student@sathyabama.ac.in',
            fcmToken: 'mock_token',
            bookmarks: [],
            lastLogin: new Date().toISOString()
          })
        }),
        set: async () => {},
        update: async () => {}
      }),
      orderBy: () => mockQuery,
      where: () => mockQuery,
      add: async (data) => {
        console.log('[Mock DB] Notice stored:', data.subject);
        return { id: 'mock_new_notice_id' };
      }
    })
  };

  auth = {
    verifyIdToken: async (token) => {
      console.log(`[Mock Auth] Verifying mock token: ${token ? token.substring(0, 15) : 'null'}...`);
      return {
        uid: 'demo_student_id_123',
        name: 'Demo Student',
        email: 'student@sathyabama.ac.in',
        picture: ''
      };
    }
  };

  messaging = {
    send: async (msg) => {
      console.log('[Mock FCM] Broadcasting notification payload:', msg);
      return 'mock-message-id-12345';
    }
  };

  storage = {
    bucket: () => ({
      file: () => ({
        save: async () => {},
      }),
      name: 'mock-bucket'
    })
  };

} else {
  try {
    const formattedPrivateKey = privateKey.replace(/\\n/g, '\n');
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey: formattedPrivateKey,
      }),
      storageBucket: `${projectId}.appspot.com`
    });
    console.log('Firebase Admin SDK initialized successfully.');
    
    db = admin.firestore();
    auth = admin.auth();
    messaging = admin.messaging();
    storage = admin.storage();
    isInitialized = true;
  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error.message);
    process.exit(1);
  }
}

module.exports = {
  admin,
  db,
  auth,
  messaging,
  storage,
  isInitialized
};
