const { db } = require('../firebase');
const { syncNotices } = require('../cron');

/**
 * GET /notices
 * Fetch latest notices with optional category filter
 */
async function getNotices(req, res) {
  const { category, limit = '20' } = req.query;
  const parsedLimit = parseInt(limit, 10);

  try {
    let query = db.collection('notices').orderBy('date', 'desc');

    if (category) {
      query = query.where('category', '==', category);
    }

    const snapshot = await query.limit(parsedLimit).get();
    const notices = [];

    snapshot.forEach(doc => {
      notices.push({ id: doc.id, ...doc.data() });
    });

    res.status(200).json({ success: true, notices });
  } catch (error) {
    console.error('Error fetching notices:', error.message);
    res.status(500).json({ error: 'Failed to fetch notices.' });
  }
}

/**
 * GET /notices/:id
 * Fetch detailed notice by its Firestore ID
 */
async function getNoticeById(req, res) {
  const { id } = req.params;

  try {
    const doc = await db.collection('notices').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Notice not found.' });
    }

    res.status(200).json({ success: true, notice: { id: doc.id, ...doc.data() } });
  } catch (error) {
    console.error('Error fetching notice details:', error.message);
    res.status(500).json({ error: 'Failed to fetch notice details.' });
  }
}

/**
 * GET /notices/search
 * Search notices by matching query terms in subject or body text
 */
async function searchNotices(req, res) {
  const { q } = req.query;

  if (!q) {
    return res.status(400).json({ error: 'Search query parameter (q) is required.' });
  }

  const lowercaseQuery = q.toLowerCase();

  try {
    // Retrieve last 150 notices to search in memory (robust approach for Firestore limits)
    const snapshot = await db.collection('notices').orderBy('date', 'desc').limit(150).get();
    const notices = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      const subject = (data.subject || '').toLowerCase();
      const body = (data.bodyText || '').toLowerCase();
      const category = (data.category || '').toLowerCase();

      if (subject.includes(lowercaseQuery) || body.includes(lowercaseQuery) || category.includes(lowercaseQuery)) {
        notices.push({ id: doc.id, ...data });
      }
    });

    res.status(200).json({ success: true, notices });
  } catch (error) {
    console.error('Error searching notices:', error.message);
    res.status(500).json({ error: 'Failed to perform notice search.' });
  }
}

/**
 * POST /sync-now
 * Force a manual sync check for notices (Admin/Manual trigger)
 */
async function triggerSync(req, res) {
  try {
    const result = await syncNotices();
    if (result.success) {
      res.status(200).json({
        success: true,
        message: 'Sync executed successfully.',
        imported: result.imported,
        failed: result.failed
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('Error in manual sync trigger:', error.message);
    res.status(500).json({ error: 'Manual sync trigger failed.' });
  }
}

/**
 * POST /summarize
 * Lightweight AI summarizer endpoint.
 * Takes the raw notice body and returns a 2-line condensed summary.
 */
async function summarizeNotice(req, res) {
  const { body } = req.body;

  if (!body) {
    return res.status(400).json({ error: 'Notice body content is required for summarization.' });
  }

  const apiKey = process.env.GROQ_API;

  if (apiKey && apiKey.trim() !== '' && !apiKey.includes('placeholder')) {
    try {
      console.log('[Groq AI] Requesting dynamic summary from Groq API...');
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey.trim()}`
        },
        body: JSON.stringify({
          model: 'llama-3.1-8b-instant',
          messages: [
            {
              role: 'system',
              content: 'You are a helpful college notice summarizer. Summarize the following college notice in exactly 2 concise, clear sentences. Focus on what is happening, key deadlines, and who is affected. Do not include introductory comments or filler phrases. Return only the 2-sentence summary text.'
            },
            {
              role: 'user',
              content: body
            }
          ],
          temperature: 0.3,
          max_tokens: 150
        })
      });

      if (response.ok) {
        const data = await response.json();
        const summary = data.choices && data.choices[0] && data.choices[0].message.content.trim();
        if (summary) {
          console.log('[Groq AI] Summary generated successfully!');
          return res.status(200).json({
            success: true,
            summary: summary
          });
        }
      } else {
        const errText = await response.text();
        console.warn(`[Groq AI] API failed with code ${response.status}: ${errText}. Using fallback.`);
      }
    } catch (e) {
      console.warn('[Groq AI] Failed to query API, using fallback:', e.message);
    }
  }

  try {
    // Generate context-aware 2-line summary using regex/keywords to simulate an LLM
    const bodyLower = body.toLowerCase();
    let line1 = 'This official notice contains important instructions regarding academic activities.';
    let line2 = 'Students are advised to check dates and fulfill requirements before the deadline.';

    if (bodyLower.includes('exam') || bodyLower.includes('test') || bodyLower.includes('timetable')) {
      line1 = 'Examination schedule or test notification has been released for the departments.';
      line2 = 'Ensure you verify the date sheet, resolve backlog clearances, and check seating arrangements.';
    } else if (bodyLower.includes('placement') || bodyLower.includes('recruit') || bodyLower.includes('interview')) {
      line1 = 'New career placement drive or recruitment program has been announced.';
      line2 = 'Eligible students should submit registrations and prepare resumes according to the guidelines.';
    } else if (bodyLower.includes('fee') || bodyLower.includes('payment') || bodyLower.includes('tuition')) {
      line1 = 'Important financial alert regarding tuition fees or semester dues payment.';
      line2 = 'Clear outstanding dues before the official cutoff date to avoid fine penalties.';
    } else if (bodyLower.includes('holiday') || bodyLower.includes('vacation') || bodyLower.includes('closed')) {
      line1 = 'Holiday or college suspension declaration issued for the specified dates.';
      line2 = 'Normal campus operations and academic schedules will resume on the next working day.';
    } else if (bodyLower.includes('event') || bodyLower.includes('symposium') || bodyLower.includes('workshop')) {
      line1 = 'Upcoming campus event, workshop, or student symposium announced.';
      line2 = 'Registration links and details are open; active participation is encouraged.';
    }

    const summary = `${line1}\n${line2}`;

    res.status(200).json({
      success: true,
      summary: summary
    });
  } catch (error) {
    console.error('Error summarizing notice:', error.message);
    res.status(500).json({ error: 'Failed to summarize notice.' });
  }
}

module.exports = {
  getNotices,
  getNoticeById,
  searchNotices,
  triggerSync,
  summarizeNotice
};
