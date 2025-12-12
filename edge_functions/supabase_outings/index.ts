import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';

// Nouveau endpoint /shotgun-proxy pour contourner CORS web Flutter
const SHOTGUN_GRAPHQL_ENDPOINT = 'https://shotgun.live/api/graphql';

const SOURCES = [
  { name: 'vortex_fb', url: 'https://m.facebook.com/vortexfrommars/events' },
  { name: 'vortexfrommars', url: 'https://vortexfrommars.net/' },
  { name: 'shotgun', url: 'https://shotgun.co/' },
  { name: 'agenda_culturel', url: 'https://agenda-culturel.com/' },
];

async function scrapeSite(url: string, sourceName: string) {
  try {
    const res = await fetch(url, { method: 'GET' });
    if (!res.ok) return [];
    const body = await res.text();

    // DOMParser works in Deno Deploy environment
    const doc = new DOMParser().parseFromString(body, 'text/html');
    if (!doc) return [];

    const anchors = Array.from(doc.querySelectorAll('a')) as Element[];
    const items: Array<any> = [];
    let counter = 0;
    for (const a of anchors) {
      const title = (a.textContent || '').trim();
      const href = (a.getAttribute('href') || '').trim();
      if (!title || !href) continue;
      const low = title.toLowerCase();
      const cats: string[] = [];
      if (low.includes('electro') || low.includes('dj') || low.includes('concert')) cats.push('electro');
      if (low.includes('expo') || low.includes('vernissage') || low.includes('exposition')) cats.push('expo');
      if (cats.length === 0) continue;

      // try to find a date in title text (YYYY-MM-DD or dd/mm/YYYY)
      let date: string | null = null;
      const iso = title.match(/20\d{2}-\d{2}-\d{2}/);
      if (iso) date = iso[0];
      else {
        const dm = title.match(/(\d{1,2}[\/\.-]\d{1,2}[\/\.-](?:20)?\d{2})/);
        if (dm) date = dm[0];
      }

      const fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();
      items.push({ id: `${sourceName}_${counter++}`, title, url: fullUrl, source: sourceName, categories: cats, date });
    }
    return items;
  } catch (e) {
    console.error('scrape error', e);
    return [];
  }
}

async function scrapeFacebookEvents(url: string, sourceName: string) {
  try {
    const res = await fetch(url, { method: 'GET' });
    if (!res.ok) return [];
    const body = await res.text();
    const doc = new DOMParser().parseFromString(body, 'text/html');
    if (!doc) return [];

    const items: Array<any> = [];
    // Look for links containing '/events/' or anchors with event-like text
    const anchors = Array.from(doc.querySelectorAll('a')) as Element[];
    let counter = 0;
    for (const a of anchors) {
      const href = (a.getAttribute('href') || '').trim();
      const title = (a.textContent || '').trim();
      if (!href) continue;
      // mobile facebook event links usually contain '/events/' or 'events' in path
      if (!href.includes('/events') && !href.toLowerCase().includes('events')) continue;

      // try to locate a nearby date/text
      let date: string | null = null;
      const parent = a.parentElement;
      if (parent) {
        const textNearby = (parent.textContent || '').trim();
        const iso = textNearby.match(/20\d{2}-\d{2}-\d{2}/);
        if (iso) date = iso[0];
        else {
          const dm = textNearby.match(/(\d{1,2}[\/\.-]\d{1,2}[\/\.-](?:20)?\d{2})/);
          if (dm) date = dm[0];
        }
      }

      const fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();

      // Normalize title fallback: try aria-label or alt attributes
      let finalTitle = title;
      if (!finalTitle) {
        const aria = a.getAttribute('aria-label') || '';
        finalTitle = aria.trim();
      }

      items.push({ id: `${sourceName}_${counter++}`, title: finalTitle || 'Événement Facebook', url: fullUrl, source: sourceName, categories: ['music'], date, image: null, description: null });
    }
    return items;
  } catch (e) {
    console.error('fb scrape error', e);
    return [];
  }
}

// Fetch event detail page (best-effort) to extract og:image or meta description
async function enrichEventDetails(item: any, timeoutMs = 2500) {
  try {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeoutMs);
    const res = await fetch(item.url, { method: 'GET', signal: controller.signal });
    clearTimeout(id);
    if (!res.ok) return item;
    const body = await res.text();
    const doc = new DOMParser().parseFromString(body, 'text/html');
    if (!doc) return item;

    // og:image
    const ogImage = doc.querySelector("meta[property='og:image']") as Element | null;
    if (ogImage != null) {
      const content = ogImage.getAttribute('content');
      if (content) item.image = content;
    }

    // meta description
    const metaDesc = doc.querySelector("meta[name='description']") as Element | null;
    if (metaDesc != null) {
      const content = metaDesc.getAttribute('content');
      if (content) item.description = content;
    }

    // fallback: first article img or any img
    if (!item.image) {
      const articleImg = doc.querySelector('article img') as Element | null;
      if (articleImg != null) {
        const src = articleImg.getAttribute('src') || articleImg.getAttribute('data-src');
        if (src) item.image = src;
      }
    }

    // fallback: look for a paragraph text as description
    if (!item.description) {
      const p = doc.querySelector('article p') as Element | null;
      if (p != null) {
        const txt = (p.textContent || '').trim();
        if (txt) item.description = txt.substring(0, 300);
      }
    }
  } catch (e) {
    // ignore enrich errors (timeout / fetch issues)
  }
  return item;
}

serve(async (req: Request) => {
  const url = new URL(req.url);

  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  // Nouveau endpoint POST /shotgun-proxy pour Flutter web (contourner CORS)
  if (req.method === 'POST' && url.pathname.endsWith('/shotgun-proxy')) {
    try {
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

      console.log('📡 Proxying request to Shotgun API...');
      const response = await fetch(SHOTGUN_GRAPHQL_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          'Accept': 'application/json',
        },
        body: JSON.stringify({ query }),
      });

      if (!response.ok) {
        console.error(`❌ Shotgun API error: ${response.status}`);
        return json({ error: 'Shotgun API error', status: response.status }, response.status);
      }

      const data = await response.json();
      const events = data?.data?.search?.events || [];
      console.log(`✅ Proxied ${events.length} events from Shotgun`);
      
      return json(data);
    } catch (e) {
      console.error('❌ Proxy error:', e);
      return json({ error: 'Internal server error', detail: String(e) }, 500);
    }
  }

  // Nouveau endpoint POST /update-outings avec logs détaillés
  if (req.method === 'POST' && url.pathname.endsWith('/update-outings')) {
    const started = Date.now();
    let results: any[] = [];
    const perSourceErrors: Record<string, string> = {};
    try {
      for (const s of SOURCES) {
        try {
          let items: any[] = [];
          if (s.name === 'vortex_fb') {
            items = await scrapeFacebookEvents(s.url, s.name);
            for (const it of items) {
              try { await enrichEventDetails(it, 2500); } catch (e) { /* ignore */ }
            }
          } else {
            items = await scrapeSite(s.url, s.name);
            for (const it of items) {
              try { await enrichEventDetails(it, 2000); } catch (e) { /* ignore */ }
            }
          }
          results.push(...items);
        } catch (e) {
          console.error(`Source scrape error (${s.name})`, e);
          perSourceErrors[s.name] = String(e);
        }
      }
    } catch (e) {
      console.error('Global scrape loop error', e);
      return json({ success: false, error: 'scrape_failed', detail: String(e) }, 500);
    }

    // Déduplication par URL
    const map: Record<string, any> = {};
    for (const it of results) {
      if (it.url) map[it.url] = it;
    }
    const deduped = Object.values(map);

    // Normalisation simple ( prépare pour insertion future )
    const normalized = deduped.map((r: any) => ({
      id: r.id,
      title: r.title,
      url: r.url,
      source: r.source,
      categories: r.categories || [],
      date: r.date || null,
      image: r.image || null,
      description: r.description || null,
    }));

    console.log('Scrape completed', {
      total_raw: results.length,
      total_deduped: deduped.length,
      sources: SOURCES.map(s => s.name),
      errors: perSourceErrors,
      ms: Date.now() - started,
    });

    return json({
      success: true,
      inserted_count: 0, // insertion dans l’étape suivante
      events_preview: normalized.slice(0, 5),
      total_events: normalized.length,
      errors: perSourceErrors,
      elapsed_ms: Date.now() - started,
      note: 'Étape 1: POST endpoint ok, pas encore d’insertion DB.'
    });
  }

  // GET existant (renvoie juste la liste brute pour debug)
  if (req.method === 'GET') {
    try {
      const results: any[] = [];
      for (const s of SOURCES) {
        try {
          if (s.name === 'vortex_fb') {
            const items = await scrapeFacebookEvents(s.url, s.name);
            for (const it of items) { try { await enrichEventDetails(it, 1500); } catch (_) {} }
            results.push(...items);
          } else {
            const items = await scrapeSite(s.url, s.name);
            for (const it of items) { try { await enrichEventDetails(it, 1000); } catch (_) {} }
            results.push(...items);
          }
        } catch (e) {
          console.error(`GET source error ${s.name}`, e);
        }
      }
      const map: Record<string, any> = {};
      for (const it of results) if (it.url) map[it.url] = it;
      return json({ success: true, total: Object.keys(map).length, data: Object.values(map).slice(0, 20) });
    } catch (e) {
      console.error('GET handler error', e);
      return json({ success: false, error: String(e) }, 500);
    }
  }

  return json({ success: false, error: 'Not found' }, 404);
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey, x-client-info',
};
