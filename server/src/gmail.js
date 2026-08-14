const { google } = require('googleapis');
const { storage, db } = require('./firebase');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Initialize OAuth2 client
const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET
);

oauth2Client.setCredentials({
  refresh_token: process.env.GMAIL_REFRESH_TOKEN
});

const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

/**
 * Searches for notices/emails from the specified Google Group.
 * Query: from:groupAddress newer_than:30d
 */
async function fetchLatestEmails() {
  const groupEmail = process.env.GOOGLE_GROUP_EMAIL || 'cse2027@sathyabama.ac.in';
  
  let newerThan = '30d'; // initial import scans 30 days
  try {
    const snapshot = await db.collection('notices').limit(1).get();
    if (!snapshot.empty) {
      newerThan = '3d'; // incremental sync only scans the last 3 days
    }
  } catch (err) {
    console.warn('[Sync] Could not determine database state, defaulting to 30d scan:', err.message);
  }

  // Broad search for Google Group address (since it appears in To/List header rather than From)
  const query = groupEmail.endsWith('googlegroups.com')
    ? `to:${groupEmail} newer_than:${newerThan}`
    : `from:${groupEmail} newer_than:${newerThan}`;

  console.log(`[Sync] Triggering Gmail query: "${query}"`);

  try {
    const response = await gmail.users.messages.list({
      userId: 'me',
      q: query,
    });

    return response.data.messages || [];
  } catch (error) {
    console.error('Error fetching emails from Gmail API:', error.message);
    return [];
  }
}

/**
 * Helper to decode base64url content.
 */
function decodeBase64(data) {
  if (!data) return '';
  return Buffer.from(data, 'base64').toString('utf-8');
}

/**
 * Parses body and attachments recursively from message parts.
 */
function parseMessageParts(parts, messageId, parsedData = { bodyText: '', bodyHtml: '', attachments: [] }) {
  if (!parts) return parsedData;

  for (const part of parts) {
    const mimeType = part.mimeType;
    const body = part.body;

    if (mimeType === 'text/plain' && body && body.data) {
      parsedData.bodyText += decodeBase64(body.data);
    } else if (mimeType === 'text/html' && body && body.data) {
      parsedData.bodyHtml += decodeBase64(body.data);
    } else if (part.filename && body && body.attachmentId) {
      parsedData.attachments.push({
        name: part.filename,
        attachmentId: body.attachmentId,
        mimeType: mimeType,
        size: body.size,
      });
    }

    if (part.parts) {
      parseMessageParts(part.parts, messageId, parsedData);
    }
  }

  return parsedData;
}

/**
 * Downloads attachment from Gmail API and uploads to Firebase Storage
 */
async function uploadAttachmentToFirebase(messageId, attachment) {
  try {
    const response = await gmail.users.messages.attachments.get({
      userId: 'me',
      messageId: messageId,
      id: attachment.attachmentId,
    });

    const base64Data = response.data.data;
    if (!base64Data) {
      throw new Error(`Empty data for attachment ${attachment.name}`);
    }

    const buffer = Buffer.from(base64Data, 'base64');
    
    // Always save locally to ensure attachment downloads work immediately
    const localDir = path.join(__dirname, '../public/attachments');
    if (!fs.existsSync(localDir)) {
      fs.mkdirSync(localDir, { recursive: true });
    }
    const localFileName = `${messageId}_${attachment.name}`;
    const localPath = path.join(localDir, localFileName);
    fs.writeFileSync(localPath, buffer);
    console.log(`[Sync] Saved attachment locally to: ${localPath}`);

    // Build local server URL
    const backendUrl = process.env.BACKEND_URL || 'http://localhost:5000';
    const localUrl = `${backendUrl}/attachments/${encodeURIComponent(localFileName)}`;

    try {
      // Try uploading to Firebase Storage as primary
      const bucket = storage.bucket();
      const destinationPath = `attachments/${messageId}_${attachment.name}`;
      const file = bucket.file(destinationPath);

      await file.save(buffer, {
        metadata: {
          contentType: attachment.mimeType,
        },
        public: true,
      });

      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${destinationPath}`;
      console.log(`[Sync] Uploaded attachment to Firebase Storage: ${publicUrl}`);
      return publicUrl;
    } catch (firebaseErr) {
      console.warn(`[Sync] Firebase Storage upload failed, using local server URL fallback: ${firebaseErr.message}`);
      return localUrl;
    }
  } catch (error) {
    console.error(`Failed to process attachment ${attachment.name}:`, error.message);
    const localFileName = `${messageId}_${attachment.name}`;
    const backendUrl = process.env.BACKEND_URL || 'http://localhost:5000';
    return `${backendUrl}/attachments/${encodeURIComponent(localFileName)}`;
  }
}

/**
 * Gets details of a single email message, parses headers, content and process attachments.
 */
async function getEmailDetails(messageId) {
  try {
    const response = await gmail.users.messages.get({
      userId: 'me',
      id: messageId,
    });

    const msg = response.data;
    const headers = msg.payload.headers;

    const subject = headers.find(h => h.name.toLowerCase() === 'subject')?.value || 'No Subject';
    const from = headers.find(h => h.name.toLowerCase() === 'from')?.value || '';
    const dateStr = headers.find(h => h.name.toLowerCase() === 'date')?.value || '';
    const date = dateStr ? new Date(dateStr).toISOString() : new Date().toISOString();

    let parsedContent = { bodyText: '', bodyHtml: '', attachments: [] };

    if (msg.payload.parts) {
      parsedContent = parseMessageParts(msg.payload.parts, messageId);
    } else if (msg.payload.body && msg.payload.body.data) {
      // Single-part message
      const text = decodeBase64(msg.payload.body.data);
      if (msg.payload.mimeType === 'text/html') {
        parsedContent.bodyHtml = text;
      } else {
        parsedContent.bodyText = text;
      }
    }

    // Process attachments by downloading and uploading to Firebase Storage
    const processedAttachments = [];
    for (const attach of parsedContent.attachments) {
      const publicUrl = await uploadAttachmentToFirebase(messageId, attach);
      processedAttachments.push({
        name: attach.name,
        url: publicUrl,
        mimeType: attach.mimeType
      });
    }

    // Determine category based on keywords
    const category = categorizeNotice(subject, parsedContent.bodyText);

    return {
      messageId: messageId,
      subject: subject,
      from: from,
      date: date,
      bodyText: parsedContent.bodyText || parsedContent.bodyHtml.replace(/<[^>]*>/g, ''), // Fallback
      bodyHtml: parsedContent.bodyHtml || `<p>${parsedContent.bodyText}</p>`, // Fallback
      category: category,
      attachments: processedAttachments,
      isImportant: subject.toLowerCase().includes('urgent') || subject.toLowerCase().includes('important'),
    };
  } catch (error) {
    console.error(`Error loading details for message ${messageId}:`, error.message);
    throw error;
  }
}

/**
 * Automatical categorization based on notice keywords.
 * Categories: Exam, Placement, Fee, Event, Holiday, Academic.
 */
function categorizeNotice(subject, bodyText) {
  const textToAnalyze = `${subject} ${bodyText}`.toLowerCase();

  if (textToAnalyze.includes('placement') || textToAnalyze.includes('job') || textToAnalyze.includes('recruit') || textToAnalyze.includes('career') || textToAnalyze.includes('interview')) {
    return 'Placement';
  }
  if (textToAnalyze.includes('exam') || textToAnalyze.includes('test') || textToAnalyze.includes('timetable') || textToAnalyze.includes('hall ticket') || textToAnalyze.includes('backlog')) {
    return 'Exam';
  }
  if (textToAnalyze.includes('fee') || textToAnalyze.includes('payment') || textToAnalyze.includes('tuition') || textToAnalyze.includes('fine') || textToAnalyze.includes('instalment')) {
    return 'Fee';
  }
  if (textToAnalyze.includes('holiday') || textToAnalyze.includes('vacation') || textToAnalyze.includes('closed') || textToAnalyze.includes('independence day') || textToAnalyze.includes('diwali') || textToAnalyze.includes('pongal')) {
    return 'Holiday';
  }
  if (textToAnalyze.includes('event') || textToAnalyze.includes('symposium') || textToAnalyze.includes('culturals') || textToAnalyze.includes('workshop') || textToAnalyze.includes('webinar') || textToAnalyze.includes('conference')) {
    return 'Event';
  }

  // Default fallback
  return 'Academic';
}

module.exports = {
  fetchLatestEmails,
  getEmailDetails,
  categorizeNotice
};
