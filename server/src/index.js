const express = require('express');
const cors = require('cors');
const { initCron } = require('./cron');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS
const allowedOrigin = process.env.ALLOWED_ORIGIN || '*';
app.use(cors({
  origin: allowedOrigin,
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Process JSON payloads
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const path = require('path');
const fs = require('fs');
const { google } = require('googleapis');

app.get('/attachments/:filename', async (req, res) => {
  const { filename } = req.params;
  const localPath = path.resolve(__dirname, '../public/attachments', filename);

  if (fs.existsSync(localPath)) {
    return res.download(localPath);
  }

  console.log(`[Attachment Server] Local file not found. Fetching from Gmail on-demand: ${filename}`);

  try {
    const firstUnderscore = filename.indexOf('_');
    if (firstUnderscore === -1) {
      return res.status(404).send('Attachment not found.');
    }

    const messageId = filename.substring(0, firstUnderscore);
    const attachmentName = filename.substring(firstUnderscore + 1);

    // Init Gmail Client
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET
    );
    oauth2Client.setCredentials({
      refresh_token: process.env.GMAIL_REFRESH_TOKEN
    });
    const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

    // Retrieve email details
    const emailRes = await gmail.users.messages.get({
      userId: 'me',
      id: messageId,
    });

    const findAttachmentId = (parts) => {
      for (const part of parts) {
        if (part.filename && part.filename === attachmentName && part.body && part.body.attachmentId) {
          return part.body.attachmentId;
        }
        if (part.parts) {
          const found = findAttachmentId(part.parts);
          if (found) return found;
        }
      }
      return null;
    };

    let attachmentId = null;
    if (emailRes.data.payload.parts) {
      attachmentId = findAttachmentId(emailRes.data.payload.parts);
    } else if (emailRes.data.payload.body && emailRes.data.payload.body.attachmentId) {
      attachmentId = emailRes.data.payload.body.attachmentId;
    }

    if (!attachmentId) {
      return res.status(404).send('Attachment file not found in Gmail message.');
    }

    // Get attachment payload
    const attachRes = await gmail.users.messages.attachments.get({
      userId: 'me',
      messageId: messageId,
      id: attachmentId,
    });

    const base64Data = attachRes.data.data;
    if (!base64Data) {
      return res.status(404).send('Empty payload received from Google API.');
    }

    const buffer = Buffer.from(base64Data, 'base64');
    
    // Save to cache
    const localDir = path.dirname(localPath);
    if (!fs.existsSync(localDir)) {
      fs.mkdirSync(localDir, { recursive: true });
    }
    fs.writeFileSync(localPath, buffer);
    console.log(`[Attachment Server] Cached file locally: ${localPath}`);

    return res.download(localPath);
  } catch (err) {
    console.error(`[Attachment Server] On-demand download failed:`, err.message);
    return res.status(500).send(`Failed to fetch attachment: ${err.message}`);
  }
});

// Log incoming requests (simplified)
app.use((req, res, next) => {
  console.log(`[HTTP] ${req.method} ${req.originalUrl} - ${new Date().toISOString()}`);
  next();
});

// Import route handlers
const authRoutes = require('./routes/auth');
const noticeRoutes = require('./routes/notices');
const userRoutes = require('./routes/users');
const bookmarkRoutes = require('./routes/bookmarks');
const notificationRoutes = require('./routes/notifications');

// Mount routes
app.use('/auth', authRoutes);
app.use('/notices', noticeRoutes);
app.use('/users', userRoutes);
app.use('/bookmarks', bookmarkRoutes);
app.use('/notifications', notificationRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development'
  });
});

// Privacy Policy page (required for Google OAuth consent screen)
app.get('/privacy', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>CampusNotify Privacy Policy</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 40px auto;
          padding: 0 20px;
          line-height: 1.6;
          color: #222;
        }
        h1, h2 {
          color: #1a73e8;
        }
      </style>
    </head>
    <body>
      <h1>CampusNotify Privacy Policy</h1>

      <p><strong>Last updated:</strong> August 26, 2026</p>

      <h2>1. Overview</h2>
      <p>
        CampusNotify is a college placement notification application
        designed to provide students with placement and campus-related
        announcements.
      </p>

      <h2>2. Information We Access</h2>
      <p>
        CampusNotify may access Gmail messages from the authorized Gmail
        account to identify placement-related announcements distributed
        through the designated college Google Group.
      </p>

      <h2>3. Gmail Access</h2>
      <p>
        Gmail access is used only to retrieve relevant placement
        announcements. CampusNotify does not use Gmail access to send
        emails on behalf of users.
      </p>

      <h2>4. Data Storage</h2>
      <p>
        Relevant placement announcements may be stored in Firebase
        Firestore so that authenticated users can view them through the
        CampusNotify application.
      </p>

      <h2>5. Notifications</h2>
      <p>
        CampusNotify may use Firebase Cloud Messaging to send placement
        notifications to users who have enabled notifications.
      </p>

      <h2>6. Data Sharing</h2>
      <p>
        CampusNotify does not sell or share users' personal information
        for advertising purposes.
      </p>

      <h2>7. Data Security</h2>
      <p>
        Authentication credentials and API credentials are stored on the
        server and are not included in the mobile application.
      </p>

      <h2>8. Contact</h2>
      <p>
        For questions regarding this application or this privacy policy,
        contact:
        <strong>braj83018@gmail.com</strong>
      </p>
    </body>
    </html>
  `);
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Error] Unhandled Exception:', err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`CampusNotify backend running on port: ${PORT}`);
  console.log(`Node Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('CLIENT ID:', process.env.GOOGLE_CLIENT_ID);
  console.log('CLIENT SECRET EXISTS:', !!process.env.GOOGLE_CLIENT_SECRET);
  console.log('REFRESH TOKEN EXISTS:', !!process.env.GMAIL_REFRESH_TOKEN);
  // Initialize Gmail sync cron job
  try {
    initCron();
  } catch (error) {
    console.error('Failed to initialize sync cron job:', error.message);
  }

  // Keep-alive self-pinging to prevent Render free-tier spin down
  const keepAliveUrl = process.env.BACKEND_URL;
  if (keepAliveUrl && !keepAliveUrl.includes('localhost') && !keepAliveUrl.includes('127.0.0.1')) {
    const PING_INTERVAL = 10 * 60 * 1000; // 10 minutes
    console.log(`[Keep-Alive] Initializing self-ping service targeting: ${keepAliveUrl}/health`);
    const https = require('https');
    setInterval(() => {
      https.get(`${keepAliveUrl}/health`, (res) => {
        console.log(`[Keep-Alive] Self-ping sent successfully. Response status: ${res.statusCode}`);
      }).on('error', (err) => {
        console.error('[Keep-Alive] Self-ping failed:', err.message);
      });
    }, PING_INTERVAL);
  }
});
