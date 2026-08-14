require('dotenv').config();

console.log('Loaded token:', process.env.GMAIL_REFRESH_TOKEN);

const { google } = require('googleapis');

async function test() {
    const oauth2Client = new google.auth.OAuth2(
        process.env.GOOGLE_CLIENT_ID,
        process.env.GOOGLE_CLIENT_SECRET
    );

    oauth2Client.setCredentials({
        refresh_token: process.env.GMAIL_REFRESH_TOKEN,
    });

    const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

    const profile = await gmail.users.getProfile({ userId: 'me' });

    console.log('Connected Gmail:', profile.data.emailAddress);
}

test().catch(err => {
    console.error('FULL ERROR:', err.response?.data || err.message);
});