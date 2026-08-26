const express = require('express');
const router = express.Router();
const path = require('path');

// ──────────────────────────────────────────────────────────────────────
// Shared HTML layout helpers — keeps pages consistent and DRY
// ──────────────────────────────────────────────────────────────────────

const SITE_NAME = 'CampusNotify';
const CONTACT_EMAIL = 'braj83018@gmail.com';
const LAST_UPDATED = 'August 26, 2026';

function pageHead(title) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — ${SITE_NAME}</title>
  <meta name="description" content="${SITE_NAME} is a student placement-notification application that automatically collects placement and recruitment notices and delivers them to registered students.">
  <link rel="icon" href="/logo.jpg" type="image/jpeg">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #1e293b;
      background: #f8fafc;
      line-height: 1.7;
      -webkit-font-smoothing: antialiased;
    }

    /* ── Navigation ──────────────────────────────── */
    .nav {
      background: #fff;
      border-bottom: 1px solid #e2e8f0;
      padding: 0 24px;
      position: sticky;
      top: 0;
      z-index: 100;
    }
    .nav-inner {
      max-width: 1100px;
      margin: 0 auto;
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 64px;
    }
    .nav-brand {
      display: flex;
      align-items: center;
      gap: 10px;
      text-decoration: none;
      color: #1e3a8a;
      font-weight: 700;
      font-size: 1.25rem;
    }
    .nav-brand img {
      width: 36px;
      height: 36px;
      border-radius: 8px;
    }
    .nav-links {
      display: flex;
      gap: 24px;
      list-style: none;
    }
    .nav-links a {
      color: #475569;
      text-decoration: none;
      font-size: 0.9rem;
      font-weight: 500;
      transition: color 0.2s;
    }
    .nav-links a:hover { color: #2563eb; }

    /* ── Page wrapper ────────────────────────────── */
    .page { max-width: 1100px; margin: 0 auto; padding: 0 24px; }

    /* ── Hero ─────────────────────────────────────── */
    .hero {
      text-align: center;
      padding: 80px 24px 60px;
    }
    .hero-logo {
      width: 100px;
      height: 100px;
      border-radius: 24px;
      box-shadow: 0 8px 30px rgba(30,58,138,0.15);
      margin-bottom: 28px;
    }
    .hero h1 {
      font-size: 2.75rem;
      font-weight: 800;
      color: #1e3a8a;
      margin-bottom: 16px;
      letter-spacing: -0.5px;
    }
    .hero p {
      font-size: 1.15rem;
      color: #475569;
      max-width: 640px;
      margin: 0 auto 36px;
    }
    .hero-badges {
      display: flex;
      gap: 12px;
      justify-content: center;
      flex-wrap: wrap;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #eff6ff;
      color: #2563eb;
      padding: 8px 18px;
      border-radius: 99px;
      font-size: 0.85rem;
      font-weight: 600;
      border: 1px solid #bfdbfe;
    }

    /* ── Feature cards ────────────────────────────── */
    .features {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 24px;
      padding: 20px 0 60px;
    }
    .feature-card {
      background: #fff;
      border: 1px solid #e2e8f0;
      border-radius: 16px;
      padding: 32px 28px;
      transition: box-shadow 0.25s, transform 0.25s;
    }
    .feature-card:hover {
      box-shadow: 0 8px 24px rgba(0,0,0,0.06);
      transform: translateY(-2px);
    }
    .feature-icon {
      font-size: 2rem;
      margin-bottom: 14px;
    }
    .feature-card h3 {
      font-size: 1.1rem;
      font-weight: 700;
      color: #1e3a8a;
      margin-bottom: 8px;
    }
    .feature-card p {
      font-size: 0.92rem;
      color: #64748b;
    }

    /* ── Sections ─────────────────────────────────── */
    .section {
      padding: 48px 0;
      border-top: 1px solid #e2e8f0;
    }
    .section h2 {
      font-size: 1.75rem;
      font-weight: 700;
      color: #1e3a8a;
      margin-bottom: 20px;
    }
    .section p, .section li {
      color: #475569;
      font-size: 0.95rem;
      margin-bottom: 12px;
    }
    .section ul { padding-left: 20px; }

    /* ── Footer ───────────────────────────────────── */
    .footer {
      background: #1e293b;
      color: #94a3b8;
      padding: 48px 24px;
      margin-top: 40px;
    }
    .footer-inner {
      max-width: 1100px;
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 32px;
    }
    .footer-brand {
      display: flex;
      align-items: center;
      gap: 10px;
      color: #fff;
      font-weight: 700;
      font-size: 1.15rem;
      margin-bottom: 8px;
    }
    .footer-brand img {
      width: 28px;
      height: 28px;
      border-radius: 6px;
    }
    .footer a {
      color: #93c5fd;
      text-decoration: none;
    }
    .footer a:hover { text-decoration: underline; }
    .footer-links {
      display: flex;
      gap: 24px;
      list-style: none;
      font-size: 0.9rem;
    }
    .footer-copy {
      width: 100%;
      text-align: center;
      margin-top: 24px;
      padding-top: 24px;
      border-top: 1px solid #334155;
      font-size: 0.82rem;
    }

    /* ── Legal pages ──────────────────────────────── */
    .legal {
      max-width: 800px;
      margin: 0 auto;
      padding: 48px 24px 80px;
    }
    .legal h1 {
      font-size: 2rem;
      font-weight: 800;
      color: #1e3a8a;
      margin-bottom: 8px;
    }
    .legal .updated {
      color: #64748b;
      font-size: 0.9rem;
      margin-bottom: 36px;
    }
    .legal h2 {
      font-size: 1.25rem;
      font-weight: 700;
      color: #1e3a8a;
      margin-top: 32px;
      margin-bottom: 12px;
    }
    .legal p {
      color: #475569;
      font-size: 0.95rem;
      margin-bottom: 14px;
    }

    @media (max-width: 640px) {
      .hero h1 { font-size: 2rem; }
      .hero { padding: 48px 16px 40px; }
      .nav-links { gap: 12px; }
      .nav-links a { font-size: 0.8rem; }
      .footer-inner { flex-direction: column; }
    }
  </style>
</head>
<body>`;
}

function navbar() {
  return `
  <nav class="nav">
    <div class="nav-inner">
      <a href="/" class="nav-brand">
        <img src="/logo.jpg" alt="CampusNotify Logo">
        ${SITE_NAME}
      </a>
      <ul class="nav-links">
        <li><a href="/">Home</a></li>
        <li><a href="/privacy">Privacy Policy</a></li>
        <li><a href="/terms">Terms of Service</a></li>
      </ul>
    </div>
  </nav>`;
}

function footer() {
  return `
  <footer class="footer">
    <div class="footer-inner">
      <div>
        <div class="footer-brand">
          <img src="/logo.jpg" alt="CampusNotify Logo">
          ${SITE_NAME}
        </div>
        <p style="font-size:0.88rem;">A student placement-notification application.</p>
      </div>
      <ul class="footer-links">
        <li><a href="/">Home</a></li>
        <li><a href="/privacy">Privacy Policy</a></li>
        <li><a href="/terms">Terms of Service</a></li>
        <li><a href="mailto:${CONTACT_EMAIL}">Contact</a></li>
      </ul>
      <p class="footer-copy">&copy; ${new Date().getFullYear()} ${SITE_NAME}. All rights reserved. Contact: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a></p>
    </div>
  </footer>
</body>
</html>`;
}

// ──────────────────────────────────────────────────────────────────────
// GET / — Public Homepage
// ──────────────────────────────────────────────────────────────────────
router.get('/', (req, res) => {
  res.send(`${pageHead('Home')}
  ${navbar()}

  <div class="page">
    <!-- Hero -->
    <section class="hero">
      <img src="/logo.jpg" alt="CampusNotify Logo" class="hero-logo">
      <h1>${SITE_NAME}</h1>
      <p>
        ${SITE_NAME} is a student placement-notification application that automatically
        collects placement and recruitment notices and delivers them to registered
        students through the mobile application.
      </p>
      <div class="hero-badges">
        <span class="badge">📱 Android App</span>
        <span class="badge">🔔 Push Notifications</span>
        <span class="badge">📧 Gmail Integration</span>
        <span class="badge">🎓 For Students</span>
      </div>
    </section>

    <!-- What CampusNotify Does -->
    <section class="section">
      <h2>What ${SITE_NAME} Does</h2>
      <div class="features">
        <div class="feature-card">
          <div class="feature-icon">📧</div>
          <h3>Automatic Notice Collection</h3>
          <p>Automatically monitors the official college Google Group email for new placement and campus announcements, so students never miss an important notice.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🔔</div>
          <h3>Instant Push Notifications</h3>
          <p>Delivers real-time push notifications to your Android device the moment a new placement notice, exam update, or event announcement is published.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">📋</div>
          <h3>Smart Categorization</h3>
          <p>Automatically categorizes notices into Placement, Exam, Fee, Event, Holiday, and Academic categories for quick filtering and search.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🔖</div>
          <h3>Bookmarks &amp; Search</h3>
          <p>Save important notices to your bookmarks and search across all announcements by keyword, category, or date.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">📎</div>
          <h3>Attachment Support</h3>
          <p>View and download attached documents like PDFs, images, and spreadsheets directly within the app.</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🔒</div>
          <h3>Secure Authentication</h3>
          <p>Students sign in with their verified college Google account. No external registration or passwords required.</p>
        </div>
      </div>
    </section>

    <!-- Who It Is For -->
    <section class="section">
      <h2>Who ${SITE_NAME} Is For</h2>
      <p>
        ${SITE_NAME} is built for <strong>college students</strong> who receive placement
        and campus announcements through their institution's official Google Group.
        It is especially useful for:
      </p>
      <ul>
        <li><strong>Final-year students</strong> preparing for campus placements and recruitment drives</li>
        <li><strong>All enrolled students</strong> who need timely access to exam schedules, fee reminders, event announcements, and academic notices</li>
        <li><strong>Students on the go</strong> who want instant mobile notifications rather than checking email manually</li>
      </ul>
      <p>
        Currently deployed for Sathyabama Institute of Science and Technology, Chennai.
        The system can be adapted for any institution that uses Google Groups for official announcements.
      </p>
    </section>

    <!-- Developer & Contact -->
    <section class="section">
      <h2>Developer &amp; Contact</h2>
      <p>
        ${SITE_NAME} is developed and maintained by <strong>Barath Raj B</strong>,
        a student at Sathyabama Institute of Science and Technology.
      </p>
      <p>
        For questions, feedback, or support, please contact:
        <strong><a href="mailto:${CONTACT_EMAIL}" style="color:#2563eb;">${CONTACT_EMAIL}</a></strong>
      </p>
    </section>
  </div>

  ${footer()}`);
});

// ──────────────────────────────────────────────────────────────────────
// GET /privacy — Privacy Policy (public, no auth)
// ──────────────────────────────────────────────────────────────────────
router.get('/privacy', (req, res) => {
  res.send(`${pageHead('Privacy Policy')}
  ${navbar()}

  <div class="legal">
    <h1>Privacy Policy</h1>
    <p class="updated"><strong>Last updated:</strong> ${LAST_UPDATED}</p>

    <h2>1. Overview</h2>
    <p>
      ${SITE_NAME} is a college placement notification application designed to
      provide students with placement and campus-related announcements. This
      privacy policy explains how the application collects, uses, and protects
      user information.
    </p>

    <h2>2. Information We Collect</h2>
    <p>
      When you sign in with your Google account, we receive your name, email
      address, and profile picture from Google. We also generate a device
      notification token to deliver push notifications.
    </p>

    <h2>3. Gmail Access</h2>
    <p>
      ${SITE_NAME} accesses Gmail messages <strong>only</strong> from a single
      authorized administrative account to retrieve placement-related
      announcements distributed through the designated college Google Group.
      The application does not access end-user Gmail accounts. ${SITE_NAME}
      does not use Gmail access to send emails on behalf of any user.
    </p>

    <h2>4. How We Use Your Information</h2>
    <p>Your information is used solely to:</p>
    <ul>
      <li>Authenticate you as a registered student</li>
      <li>Deliver push notifications for new notices</li>
      <li>Store your bookmarks and read-status preferences</li>
    </ul>

    <h2>5. Data Storage</h2>
    <p>
      Placement announcements are stored in Google Firebase Firestore so that
      authenticated users can view them through the ${SITE_NAME} mobile
      application. User profile data (name, email, device token) is also
      stored in Firestore.
    </p>

    <h2>6. Data Sharing</h2>
    <p>
      ${SITE_NAME} does not sell, rent, or share users' personal information
      with third parties for advertising or marketing purposes. Data is only
      shared with Google Firebase services for application functionality.
    </p>

    <h2>7. Data Security</h2>
    <p>
      Authentication is handled through Google Sign-In and secured with JWT
      tokens. All API credentials and server secrets are stored securely on the
      server and are never included in the mobile application.
    </p>

    <h2>8. Data Retention</h2>
    <p>
      Your account data is retained as long as you use the application. You may
      request deletion of your data by contacting the developer at the email
      address below.
    </p>

    <h2>9. Changes to This Policy</h2>
    <p>
      We may update this privacy policy from time to time. Changes will be
      reflected on this page with an updated revision date.
    </p>

    <h2>10. Contact</h2>
    <p>
      For questions or concerns regarding this privacy policy, contact:
      <strong><a href="mailto:${CONTACT_EMAIL}" style="color:#2563eb;">${CONTACT_EMAIL}</a></strong>
    </p>
  </div>

  ${footer()}`);
});

// ──────────────────────────────────────────────────────────────────────
// GET /terms — Terms of Service (public, no auth)
// ──────────────────────────────────────────────────────────────────────
router.get('/terms', (req, res) => {
  res.send(`${pageHead('Terms of Service')}
  ${navbar()}

  <div class="legal">
    <h1>Terms of Service</h1>
    <p class="updated"><strong>Last updated:</strong> ${LAST_UPDATED}</p>

    <h2>1. Acceptance of Terms</h2>
    <p>
      By accessing or using ${SITE_NAME}, you agree to be bound by these Terms
      of Service. If you do not agree, please do not use the application.
    </p>

    <h2>2. Description of Service</h2>
    <p>
      ${SITE_NAME} is a student placement-notification application that
      automatically collects placement and recruitment notices from an
      authorized college Google Group email account and delivers them to
      registered students via a mobile application and push notifications.
    </p>

    <h2>3. User Accounts</h2>
    <p>
      You must sign in using a valid Google account to access ${SITE_NAME}. You
      are responsible for maintaining the confidentiality of your account and
      for all activities that occur under your account.
    </p>

    <h2>4. Acceptable Use</h2>
    <p>You agree not to:</p>
    <ul>
      <li>Use the application for any unlawful purpose</li>
      <li>Attempt to gain unauthorized access to the application's backend systems</li>
      <li>Interfere with or disrupt the application or its servers</li>
      <li>Redistribute or republish content from the application without permission</li>
    </ul>

    <h2>5. Content Disclaimer</h2>
    <p>
      ${SITE_NAME} aggregates and displays notices from institutional email
      sources. The application does not create, endorse, or verify the accuracy
      of the notices it displays. The original notice content remains the
      responsibility of the issuing institution.
    </p>

    <h2>6. Availability</h2>
    <p>
      ${SITE_NAME} is provided on an "as-is" basis. We do not guarantee
      uninterrupted or error-free operation of the application. The service may
      be temporarily unavailable due to maintenance or server limitations.
    </p>

    <h2>7. Limitation of Liability</h2>
    <p>
      To the fullest extent permitted by law, ${SITE_NAME} and its developer
      shall not be liable for any direct, indirect, incidental, or
      consequential damages arising from the use of or inability to use the
      application.
    </p>

    <h2>8. Changes to Terms</h2>
    <p>
      We reserve the right to modify these terms at any time. Continued use of
      the application after changes constitutes acceptance of the revised terms.
    </p>

    <h2>9. Contact</h2>
    <p>
      For questions about these terms, contact:
      <strong><a href="mailto:${CONTACT_EMAIL}" style="color:#2563eb;">${CONTACT_EMAIL}</a></strong>
    </p>
  </div>

  ${footer()}`);
});

module.exports = router;
