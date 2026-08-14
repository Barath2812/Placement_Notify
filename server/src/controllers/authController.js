const { db, admin } = require('../firebase');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'campusnotify_jwt_secret_key_123';

/**
 * Handle password-based authentication. Updates or auto-creates
 * student profiles in Firestore.
 * 
 * POST /auth/login
 * Body: { username, password }
 */
async function handleLogin(req, res) {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  // Sanitize username
  const cleanUsername = username.trim().toLowerCase();

  // Enforce range check: 43120245 to 43120306
  const parsedUsername = parseInt(cleanUsername, 10);
  if (isNaN(parsedUsername) || parsedUsername < 43120245 || parsedUsername > 43120306) {
    return res.status(400).json({ error: 'Access Denied: Username must be a register number between 43120245 and 43120306.' });
  }

  // Enforce password matches username exactly
  if (password.trim() !== username.trim()) {
    return res.status(401).json({ error: 'Incorrect password. Your password must match your Sathyabama register number.' });
  }

  try {
    const userRef = db.collection('users').doc(cleanUsername);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      // Auto-register for ease of deployment and testing within the range
      const userData = {
        uid: cleanUsername,
        username: cleanUsername,
        password: password.trim(), 
        name: `Student ${cleanUsername}`,
        bookmarks: [],
        readNotices: [],
        fcmToken: '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: admin.firestore.FieldValue.serverTimestamp()
      };

      await userRef.set(userData);
      console.log(`Auto-registered Sathyabama student: ${cleanUsername}`);

      const token = jwt.sign(
        { uid: cleanUsername, name: userData.name },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      return res.status(200).json({
        success: true,
        token,
        user: {
          uid: userData.uid,
          name: userData.name,
          email: `${cleanUsername}@sathyabama.ac.in`,
          bookmarks: userData.bookmarks,
          readNotices: userData.readNotices,
          fcmToken: userData.fcmToken
        }
      });
    }

    const userData = userDoc.data();

    // Verify password matches
    if (userData.password !== password.trim()) {
      return res.status(401).json({ error: 'Incorrect password.' });
    }

    // Update last login timestamp
    await userRef.update({
      lastLogin: admin.firestore.FieldValue.serverTimestamp()
    });

    const token = jwt.sign(
      { uid: cleanUsername, name: userData.name },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(200).json({
      success: true,
      token,
      user: {
        uid: userData.uid,
        name: userData.name,
        email: userData.email || `${cleanUsername}@sathyabama.ac.in`,
        bookmarks: userData.bookmarks || [],
        readNotices: userData.readNotices || [],
        fcmToken: userData.fcmToken || ''
      }
    });

  } catch (error) {
    console.error('Error in login controller:', error.message);
    res.status(500).json({ error: 'Authentication failed. Please check your Firestore connection.' });
  }
}

/**
 * Retrieves the current authenticated user's profile details.
 * 
 * GET /auth/me
 * Headers: Authorization: Bearer <JWT_Token>
 */
async function handleGetProfile(req, res) {
  const { uid } = req.user; // Set by authenticateUser middleware

  try {
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User profile not found.' });
    }

    const userData = userDoc.data();
    res.status(200).json({
      success: true,
      user: {
        uid: userData.uid,
        name: userData.name,
        email: userData.email || `${userData.uid}@sathyabama.ac.in`,
        bookmarks: userData.bookmarks || [],
        readNotices: userData.readNotices || [],
        fcmToken: userData.fcmToken || ''
      }
    });
  } catch (error) {
    console.error('Error fetching profile in controller:', error.message);
    res.status(500).json({ error: 'Failed to retrieve profile.' });
  }
}

module.exports = {
  handleLogin,
  handleGetProfile
};
