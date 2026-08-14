# CampusNotify 📢

CampusNotify is a production-ready, full-stack campus notification portal that automatically reads announcements from specific Google Group lists delivered to a Gmail inbox, parses/categorizes them on a Node.js + Express backend, stores them in Firebase, and dispatches real-time push alerts to students via Firebase Cloud Messaging (FCM) to display in a Material 3 Flutter application.

---

## 🛠️ System Architecture

```text
Google Group → Gmail Inbox → Gmail API (OAuth 2) → Node.js Express Sync Backend 
                                                     │
                                                     ├── Firestore Database (Notices & Users)
                                                     ├── Firebase Storage (PDF Attachments)
                                                     └── Firebase Cloud Messaging (Topic Broadcasting)
                                                               │
                                                               └── Flutter Mobile App (iOS/Android Client)
```

---

## 📁 Repository Folder Structure

```text
Campus-Notice/
├── firestore.rules          # Firestore Database rules configuration
├── storage.rules            # Firebase Storage file rules
├── pubspec.yaml             # Flutter client app dependency configuration
├── README.md                # System integration manual (this document)
├── lib/                     # Flutter Client Application Source
│   ├── main.dart            # Flutter entrypoint, routing & notification triggers
│   ├── core/
│   │   └── constants.dart   # AppTheme, Colors, and API Endpoint definitions
│   ├── models/
│   │   ├── notice.dart      # Notice model & attachment structures
│   │   └── user_model.dart  # User account & bookmarks structure
│   ├── services/
│   │   ├── api_service.dart # Server connection handlers & token interceptor
│   │   └── notification_service.dart # FCM subscription & local notification engine
│   ├── providers/
│   │   ├── auth_provider.dart    # Google Auth, Firebase linking, session state
│   │   └── notice_provider.dart  # Feed caching, filters, read flags & AI summaries
│   ├── widgets/
│   │   └── notice_card.dart      # Dashboard notice chip & indicator card
│   └── screens/
│       ├── splash_screen.dart    # Branding delay and router gatekeeper
│       ├── login_screen.dart     # Google Sign-In panel
│       ├── home_screen.dart      # Notices dashboard with category filters
│       ├── notice_detail_screen.dart # Announcement text reader, summaries & files
│       ├── search_screen.dart    # Keyword indices filtering screen
│       ├── bookmarks_screen.dart # Bookmark feeds list screen
│       ├── settings_screen.dart  # FCM tokens debug list & switch settings
│       └── about_screen.dart     # Architecture details dashboard
└── server/                  # Backend Node.js Web Server & Cron Sync
    ├── package.json         # Node module specifications
    ├── .env.example         # App environment config template
    └── src/
        ├── index.js         # Express main launcher
        ├── firebase.js      # Firebase Admin SDK setups
        ├── gmail.js         # Gmail API integration & email decoder
        ├── notifier.js      # FCM payload dispatcher
        ├── cron.js          # 5-minute background sync cron job
        ├── middlewares/
        │   └── authMiddleware.js # Firebase token verification middleware
        ├── controllers/
        │   ├── authController.js   # User profiles initializer
        │   ├── noticeController.js # Notice lists, search & AI summarizer
        │   └── userController.js   # Bookmarks & tokens modifier
        └── routes/
            ├── auth.js      # auth/google routes
            ├── notices.js   # notice fetch & search routes
            ├── users.js     # FCM token register routes
            └── bookmarks.js # bookmark toggle routes
```

---

## ⚡ Deployment Instructions

### 1. Firebase Console Configuration
1. Create a new Firebase project: **CampusNotify**.
2. **Cloud Firestore**: Enable it in production mode. Set the rules to upload [firestore.rules](file:///d:/Placement-Notice/firestore.rules).
3. **Firebase Cloud Messaging**: Enable FCM. Copy the Server Key/Private Config.
4. **Cloud Storage**: Enable it. Upload the rules from [storage.rules](file:///d:/Placement-Notice/storage.rules).
5. **Add Android App**: Register Android package name `com.example.campus_notify`. Download `google-services.json` and move it to `android/app/`.
6. **Authentication**: Enable Google Sign-In provider under Build > Authentication > Sign-in method.

### 2. Google Cloud Platform (GCP) Gmail API Setup
1. Open [Google Cloud Console](https://console.cloud.google.com/) for the created Firebase project.
2. Go to **APIs & Services** > **Library** and search for **Gmail API**. Click **Enable**.
3. Go to **OAuth Consent Screen**:
   - Choose User Type: **External**.
   - Fill in app name, emails, and add scope `/auth/gmail.readonly`.
   - Add test email address of the account receiving notices.
4. Go to **Credentials** > **Create Credentials** > **OAuth Client ID**:
   - Select **Web Application**.
   - Add Authorized redirect URIs: `https://developers.google.com/oauthplayground`.
   - Click Create and note down **Client ID** and **Client Secret**.
5. Get the **Gmail Refresh Token**:
   - Go to [Google OAuth 2.0 Playground](https://developers.google.com/oauthplayground).
   - In configuration (gear icon top right), check "Use own OAuth credentials" and paste Client ID and Client Secret.
   - Enter Scope `https://mail.google.com/` or `https://www.googleapis.com/auth/gmail.readonly` and click **Authorize APIs**.
   - Log in with the target Gmail account, grant permissions, and exchange the authorization code for a **Refresh Token**. Copy this token.

### 3. Backend Deployment to Render / Railway
1. Push the `server` folder to a GitHub repository.
2. In [Render](https://render.com/), create a new **Web Service** linked to your repository.
3. Configure the build parameters:
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node src/index.js`
4. Set the **Environment Variables** in Render's dashboard matching `.env.example`:
   - `PORT`: `10000` or default
   - `GOOGLE_CLIENT_ID`: Your GCP Client ID
   - `GOOGLE_CLIENT_SECRET`: Your GCP Client Secret
   - `GMAIL_REFRESH_TOKEN`: The Refresh Token generated above
   - `GMAIL_USER_EMAIL`: Gmail account listening to group
   - `GOOGLE_GROUP_EMAIL`: `cse2027@sathyabama.ac.in`
   - `FIREBASE_PROJECT_ID`: Your Firebase project ID
   - `FIREBASE_CLIENT_EMAIL`: Service Account client email
   - `FIREBASE_PRIVATE_KEY`: Service Account private key string

---

## 📡 API Documentation

All endpoints (except health) expect the Firebase ID token in the header:
`Authorization: Bearer <Firebase_ID_Token>`

| Endpoint | Method | Description | Payload Example |
|---|---|---|---|
| `/auth/google` | `POST` | Registers or updates student login session profile | None |
| `/notices` | `GET` | Fetch latest notice lists. Supports optional query `?category=` | None |
| `/notices/search` | `GET` | Search notice details containing matching terms. Query `?q=` | None |
| `/notices/:id` | `GET` | Fetch complete announcement fields and attachments | None |
| `/notices/sync-now` | `POST` | Force Gmail mailbox sync & alert broadcasts | None |
| `/notices/summarize` | `POST` | Request an AI 2-line summary on notice body | `{"body": "Notice body text..."}` |
| `/users/token` | `POST` | Updates client FCM token for notifications | `{"fcmToken": "fcm_token_string"}` |
| `/bookmarks/:id` | `POST` | Bookmarks an announcement for the active student | None |
| `/bookmarks/:id` | `DELETE` | Removes notice ID from bookmarks collection | None |

---

## 🧪 Testing Instructions

### 1. Sample Gmail Test Message
Send an email to the configured group folder containing:
- **Sender**: `cse2027@sathyabama.ac.in`
- **Subject**: `[URGENT] semester exam schedule timetable release`
- **Body**: `Dear Students, The timetable for the upcoming Semester Examinations has been published. Clear all fee dues. Find attached schedule.`
- **Attachment**: `timetable.pdf`

### 2. Manual Sync and Notification Verification
- Run a `POST` request to `/notices/sync-now` on the server using Postman or click the floating sync button in the Flutter app.
- Check server logs to verify it discovers the mock email, parses the attachment, uploads it to Firebase Storage, inserts a Firestore record, and triggers FCM.
- A push notification will be delivered to devices subscribed to the `college-notices` topic.

### 3. Postman Collection
```json
{
  "info": {
    "name": "CampusNotify Backend API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Manual Cron Sync Now",
      "request": {
        "method": "POST",
        "header": [
          { "key": "Authorization", "value": "Bearer {{FIREBASE_ID_TOKEN}}" }
        ],
        "url": { "raw": "{{BASE_URL}}/notices/sync-now" }
      }
    },
    {
      "name": "AI Summarize Notice",
      "request": {
        "method": "POST",
        "header": [
          { "key": "Authorization", "value": "Bearer {{FIREBASE_ID_TOKEN}}" },
          { "key": "Content-Type", "value": "application/json" }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"body\": \"TIMETABLE exams schedule. Clear your tuition fees dues.\"\n}"
        },
        "url": { "raw": "{{BASE_URL}}/notices/summarize" }
      }
    }
  ]
}
```

---

## 📱 User Interface Mockup Layouts

### 1. Splash Screen
A clean deep blue background (`#1E3A8A`) displaying a centered megaphone icon and logo text "CampusNotify" with a spinning white circular loader indicating system check status.

### 2. Login Screen
A modern interface with a deep-blue top curvature fading into slate white (`#F8FAFC`). It contains a card prompting "Welcome Student" and a customized elevated "Sign in with Google" button with the brand G icon.

### 3. Home Screen notices List
Features a search icon and bookmark quick access in the action bar, followed by a horizontal scrolling list of category filter chips:
- `All` (Slate Blue), `Exam` (Red), `Placement` (Green), `Fee` (Amber), etc.
- Below the chips, a ListView lists announcements. Each notice card features a category indicator chip, subject title in bold, short text snippet, attachments count indicator, unread blue dot, and a bookmark toggle icon.

### 4. Notice Detail Screen
Opens the selected notice. It includes an **AI Smart Summary** card styled with a light blue background and a bulb icon. A tap triggers the "Summarize" callback, displaying the AI's 2-line summary. Attachment files below the notice content feature standard PDF icons that launch files in external apps on tap.

---

## 🚀 Future Enhancements
1. **Gemini Live AI Summary Integration**: Upgrade the placeholder AI summarizer to call the Google Gemini API for highly customized summaries.
2. **Channel Subscription Management**: Allow students to toggle notifications for specific categories (e.g., get alerts only for Placement and Exams, mute Events).
3. **In-App PDF Viewer**: Embed an offline PDF viewer directly in the Flutter app to view documents without leaving the app.
#   P l a c e m e n t _ N o t i f y  
 