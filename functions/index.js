const functions = require('firebase-functions');
const fetch = require('node-fetch');

/**
 * Cloud Function proxy pour contourner CORS de l'API Shotgun
 * Appelée depuis l'app Flutter web pour récupérer les événements
 */
exports.shotgunProxy = functions.https.onRequest(async (req, res) => {
  // CORS headers pour autoriser l'app web
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const query = `
    query SearchEvents {
      search(input: {query: "Marseille", types: [EVENT], limit: 50}) {
        events {
          id
          title
          slug
          startDate
          description
          location { name city }
          categories
          image { url }
        }
      }
    }
  `;

  try {
    console.log('📡 Calling Shotgun API for events...');
    const response = await fetch('https://shotgun.live/api/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'application/json',
      },
      body: JSON.stringify({ query }),
      timeout: 10000,
    });

    if (!response.ok) {
      console.error(`❌ Shotgun API error: ${response.status}`);
      res.status(response.status).json({ 
        error: 'Shotgun API error', 
        status: response.status 
      });
      return;
    }

    const data = await response.json();
    const events = data?.data?.search?.events || [];
    console.log(`✅ Received ${events.length} events from Shotgun`);
    
    res.json(data);
  } catch (error) {
    console.error('❌ Proxy error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      message: error.message 
    });
  }
});
