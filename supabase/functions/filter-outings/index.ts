import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || Deno.env.get('PROJECT_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SERVICE_ROLE_KEY') || '';

serve(async (req: Request) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const userId = url.searchParams.get('user_id');

  if (!userId) {
    return json({ success: false, error: 'user_id required' }, 400, corsHeaders);
  }

  try {
    console.log(`📤 Filtering 5 outings for user ${userId}`);

    // Fetch user preferences
    let prefs: any = null;
    try {
      const prefUrl = `${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/user_preferences?user_id=eq.${userId}&select=*`;
      const prefRes = await fetch(prefUrl, {
        method: 'GET',
        headers: {
          'apikey': SUPABASE_SERVICE_ROLE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
      });
      const prefData = await prefRes.json();
      if (Array.isArray(prefData) && prefData.length > 0) {
        prefs = prefData[0];
        console.log('✅ Found user preferences');
      }
    } catch (e) {
      console.warn('⚠️ Could not fetch user preferences', e);
    }

    // Default preferences
    if (!prefs) {
      prefs = {
        preferred_categories: ['concert', 'soiree', 'electro', 'expo'],
        min_price: 0,
        max_price: 1000,
        exclude_keywords: ['enfant', 'jeune public', 'famille', 'kids'],
      };
      console.log('Using default preferences');
    }

    // Fetch future outings
    const today = new Date().toISOString().substring(0, 10);
    const outingsUrl = `${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/outings?date=gte.${today}&limit=200&order=date.asc`;
    const outingsRes = await fetch(outingsUrl, {
      method: 'GET',
      headers: {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    });
    const outings = await outingsRes.json();
    if (!Array.isArray(outings)) {
      return json({ success: false, error: 'Failed to fetch outings' }, 500, corsHeaders);
    }
    console.log(`📥 Fetched ${outings.length} total outings`);

    // Filter & score events
    const genericWords = ['vidéos', 'videos', 'café', 'bar concert', 'concert', 'expo'];
    const scored = outings
      .filter((event: any) => {
        // Category filter
        const eventCats = Array.isArray(event.categories) 
          ? event.categories.map((c: any) => String(c).toLowerCase()) 
          : [];
        const prefCats = (prefs.preferred_categories || []).map((c: any) => String(c).toLowerCase());
        
        if (prefCats.length > 0 && eventCats.length > 0) {
          const hasMatch = prefCats.some((pc: any) => eventCats.includes(pc));
          if (!hasMatch) return false;
        }

        // Exclude keywords
        const title = (event.title || '').toLowerCase();
        const excludeWords = (prefs.exclude_keywords || []).map((w: any) => String(w).toLowerCase());
        if (excludeWords.some((w: any) => title.includes(w))) {
          return false;
        }

        // Skip overly generic titles (likely scraping artifacts)
        const titleWords = title.split(/\s+/);
        if (titleWords.length <= 2 && genericWords.some(g => title === g.toLowerCase())) {
          return false;
        }

        // Price filter
        if (event.price) {
          try {
            const price = parseFloat(event.price);
            if (!isNaN(price)) {
              if (price < (prefs.min_price || 0) || price > (prefs.max_price || 1000)) {
                return false;
              }
            }
          } catch (e) {
            // ignore
          }
        }

        return true;
      })
      .map((event: any) => {
        let score = 0;
        const eventCats = Array.isArray(event.categories) 
          ? event.categories.map((c: any) => String(c).toLowerCase()) 
          : [];
        const prefCats = (prefs.preferred_categories || []).map((c: any) => String(c).toLowerCase());
        
        // Score: +10 per matching category
        const matchCount = prefCats.filter((pc: any) => eventCats.includes(pc)).length;
        score += matchCount * 10;

        // Score: proximity to today (closer = higher score)
        try {
          const eventDate = new Date(event.date);
          const now = new Date();
          const diffDays = Math.floor((eventDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
          if (diffDays >= 0 && diffDays <= 7) {
            score += (7 - diffDays) * 5; // Today = +35, tomorrow = +30, etc.
          } else if (diffDays > 7) {
            score += 1; // Future events get minimal score
          }
        } catch (e) {
          // ignore date parsing errors
        }

        // Penalty for very long titles (likely low-quality scrapes)
        const titleLength = (event.title || '').length;
        if (titleLength > 100) {
          score -= 5;
        }

        return { ...event, _score: score };
      })
      .sort((a: any, b: any) => (b._score || 0) - (a._score || 0));

    const result = scored.slice(0, 5).map((e: any) => {
      const { _score, ...event } = e;
      return event;
    });
    console.log(`✅ Returning ${result.length} filtered events from ${scored.length} candidates`);

    return json(
      {
        success: true,
        user_id: userId,
        count: result.length,
        events: result,
        preferences_applied: prefs,
        total_candidates: scored.length,
      },
      200,
      corsHeaders
    );
  } catch (e) {
    console.error('❌ Error:', e);
    return json({ success: false, error: String(e) }, 500, corsHeaders);
  }
});

function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}
