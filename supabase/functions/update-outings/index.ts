import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';

// Note: do not polyfill with @xmldom (noisy warnings). Use `parseHTML` which
// prefers native DOMParser and falls back to `linkedom` for full DOM APIs.

// Nouveau endpoint /shotgun-proxy pour contourner CORS web Flutter
const SHOTGUN_GRAPHQL_ENDPOINT = 'https://shotgun.live/api/graphql';

const SOURCES = [
  { name: 'tarpin-bien', url: 'https://tarpin-bien.com/' },
  { name: 'sortiramarseille', url: 'https://sortiramarseille.fr/soirees-marseille' },
  { name: 'marseille-tourisme', url: 'https://www.marseille-tourisme.com/agenda/' },
];

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || Deno.env.get('PROJECT_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SERVICE_ROLE_KEY') || '';

// Robust HTML parser: prefer native DOMParser when it provides querySelectorAll,
// otherwise fall back to linkedom which implements the DOM APIs used below.
async function parseHTML(body: string) {
  try {
    if (typeof (globalThis as any).DOMParser !== 'undefined') {
      try {
        const doc = new (globalThis as any).DOMParser().parseFromString(body, 'text/html');
        if (doc && typeof (doc as any).querySelectorAll === 'function') return doc;
      } catch (e) {
        // ignore and fallback
      }
    }
    // dynamic import linkedom for full querySelector support
    const linkedom = await import('https://esm.sh/linkedom@0.15.0');
    const parsed = linkedom.parseHTML(body as string);
    return parsed.document;
  } catch (e) {
    console.warn('parseHTML fallback failed', e);
    return null;
  }
}

// Validate and normalize date: return ISO string or null if invalid
function normalizeDate(dateStr: string | null): string | null {
  if (!dateStr) return null;
  const cleaned = dateStr.trim();
  
  // Already ISO format (YYYY-MM-DD or full ISO 8601)
  if (/^\d{4}-\d{2}-\d{2}/.test(cleaned)) {
    try {
      new Date(cleaned); // validate
      return cleaned.substring(0, 10); // return just date part
    } catch (e) {
      return null;
    }
  }
  
  // Try to parse French date format: "Le X Mois YYYY" or "X Mois YYYY"
  const frenchMonths: Record<string, number> = {
    janvier: 1, février: 2, mars: 3, avril: 4, mai: 5, juin: 6,
    juillet: 7, août: 8, septembre: 9, octobre: 10, novembre: 11, décembre: 12,
  };
  
  const match = cleaned.match(/(\d{1,2})\s+(\w+)\s+(\d{4})/i);
  if (match) {
    const day = parseInt(match[1], 10);
    const monthName = match[2].toLowerCase();
    const month = frenchMonths[monthName];
    const year = parseInt(match[3], 10);
    
    if (month && year > 2000 && year < 2100 && day > 0 && day <= 31) {
      const date = new Date(year, month - 1, day);
      return date.toISOString().substring(0, 10);
    }
  }
  
  // If contains only partial text like "Le " or other non-date junk, return null
  if (cleaned.length < 8 || /^(le|la|du|au|à|et)$/i.test(cleaned)) {
    return null;
  }
  
  // Try general date parsing as last resort
  try {
    const d = new Date(cleaned);
    if (!isNaN(d.getTime())) {
      return d.toISOString().substring(0, 10);
    }
  } catch (e) {
    // ignore
  }
  
  return null;
}

async function fetchActiveSourcesFromDB() {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return null;
  try {
    const url = `${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/scrape_sources?enabled=eq.true&select=source,url`;
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    });
    if (!res.ok) {
      console.error('fetchActiveSourcesFromDB error status', res.status);
      return null;
    }
    const data = await res.json();
    return data;
  } catch (e) {
    console.error('fetchActiveSourcesFromDB exception', e);
    return null;
  }
}

async function upsertOutingsToDB(rows: any[]) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ upsertOutingsToDB: missing credentials', { url: !!SUPABASE_URL, key: !!SUPABASE_SERVICE_ROLE_KEY });
    return { ok: false, error: 'no_service_key' };
  }
  try {
    // Use ?on_conflict=url to upsert on url column (update if exists, insert if new)
    const url = `${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/outings?on_conflict=url`;
    console.log('📤 Attempting upsert to', url, 'with', rows.length, 'rows');
    console.log('First row sample:', JSON.stringify(rows[0]));
    const res = await fetch(url, {
      method: 'POST',
      headers: {
          'apikey': SUPABASE_SERVICE_ROLE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates, return=representation'
      },
      body: JSON.stringify(rows)
    });
      const text = await res.text();
      console.log('upsertOutingsToDB status', res.status, 'bodyBytes', text ? text.length : 0);
      let jsonRes = null;
      try { jsonRes = text ? JSON.parse(text) : null; } catch(e){ jsonRes = text; }
      if (!res.ok) {
        console.error('❌ upsertOutingsToDB error status', res.status, 'response:', jsonRes);
      } else {
        console.log('✅ upsertOutingsToDB success, returned', Array.isArray(jsonRes) ? jsonRes.length + ' rows' : '1 row or object');
      }
      return { ok: res.ok, status: res.status, data: jsonRes };
  } catch (e) {
    console.error('❌ upsertOutingsToDB exception', e);
    return { ok: false, error: String(e) };
  }
}

async function fetchOutingsBatch(limit = 200) {
  if (!SUPABASE_URL) return [];
  try {
    const url = `${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/outings?select=*&limit=${limit}`;
    const res = await fetch(url, { method: 'GET', headers: { 'apikey': SUPABASE_SERVICE_ROLE_KEY, 'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` } });
    if (!res.ok) { console.error('fetchOutingsBatch error', res.status); return []; }
    return await res.json();
  } catch (e) { console.error('fetchOutingsBatch exception', e); return []; }
}

// Parser for tarpin-bien.com (WordPress search results with événementCheck=1)
// Structure: div.post-container > div.et_pb_post (ou article.post)
async function scrapeTarpinBien(url: string, sourceName: string) {
  try {
    const res = await fetch(url, { method: 'GET', headers: { 'User-Agent': 'Mozilla/5.0' } });
    if (!res.ok) {
      console.warn(`scrapeTarpinBien fetch not ok: ${res.status}`);
      return [];
    }
    const body = await res.text();
    console.log(`scrapeTarpinBien fetched: status=${res.status}, bytes=${body.length}`);
    const doc = await parseHTML(body);
    if (!doc) return [];

    const items: Array<any> = [];
    let counter = 0;
    const seen = new Set<string>();

    // TARGET 1: Divi posts (.et_pb_post) - WordPress Divi theme structure
    let posts = Array.from(doc.querySelectorAll('.et_pb_post, article.post, .post-container article')) as Element[];
    console.log(`scrapeTarpinBien: found ${posts.length} .et_pb_post items`);
    
    for (const post of posts) {
      try {
        // Titre: h2.entry-title ou h2 dans le post
        let titleEl = post.querySelector('h2.entry-title');
        if (!titleEl) titleEl = post.querySelector('h2');
        const title = titleEl ? (titleEl.textContent || '').trim() : '';
        
        if (!title || title.length < 3) continue;
        if (title.toLowerCase().includes('cookie') || title.toLowerCase().includes('politique')) continue;
        
        // Lien: Chercher le <a> DANS LE TITRE (priorité)
        let href = '';
        if (titleEl) {
          const titleLink = titleEl.querySelector('a[href]');
          if (titleLink) {
            href = titleLink.getAttribute('href') || '';
          }
        }
        
        // Fallback: chercher .entry-title-link ou .post-title-link
        if (!href) {
          const titleLink = post.querySelector('.entry-title-link, .post-title-link, h2 a[href]');
          if (titleLink) href = titleLink.getAttribute('href') || '';
        }
        
        // Dernier fallback: premier lien pertinent du post
        if (!href) {
          const allLinks = Array.from(post.querySelectorAll('a[href]')) as Element[];
          const relevant = allLinks.find(l => {
            const h = l.getAttribute('href') || '';
            return h.length > 10 && !h.includes('#') && !h.includes('javascript') && !h.includes('comment') && !h.includes('/category/');
          });
          if (relevant) href = relevant.getAttribute('href') || '';
        }
        
        if (!href || seen.has(href)) continue;
        seen.add(href);
        
        let fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();

        // DATE: Chercher la date (très important!)
        // Essayer: <time datetime>, .published, .posted-on, data-publish-date
        let date: string | null = null;
        
        // 1. time[datetime]
        const timeEl = post.querySelector('time[datetime]');
        if (timeEl) {
          date = timeEl.getAttribute('datetime');
        }
        
        // 2. .published ou .posted-on (span/div class)
        if (!date) {
          const pubEl = post.querySelector('.published, .posted-on, .entry-date');
          if (pubEl) {
            const dateText = pubEl.getAttribute('datetime') || pubEl.textContent || '';
            date = dateText.trim();
          }
        }
        
        // 3. Chercher dans le meta du post
        if (!date) {
          const metaEl = post.querySelector('.entry-meta, .post-meta');
          if (metaEl) {
            const dateText = metaEl.textContent || '';
            // Extraire date au format YYYY-MM-DD si présente
            const match = dateText.match(/\d{1,2}\s+\w+\s+\d{4}/);
            if (match) date = match[0];
          }
        }

        // IMAGE: Chercher image dans le post
        let image: string | null = null;
        
        // 1. .entry-featured-image-url ou figure img
        let imgEl = post.querySelector('.entry-featured-image-url, figure img, .et_pb_image img');
        if (imgEl) {
          image = imgEl.getAttribute('src') || imgEl.getAttribute('data-src');
        }
        
        // 2. Premier img du post (fallback)
        if (!image) {
          imgEl = post.querySelector('img');
          if (imgEl) image = imgEl.getAttribute('src') || imgEl.getAttribute('data-src');
        }
        
        if (image && !image.startsWith('http')) {
          try {
            image = new URL(image, url).toString();
          } catch (e) {
            image = null;
          }
        }

        // DESCRIPTION: .entry-content, .post-content, .excerpt
        let description: string | null = null;
        let descEl = post.querySelector('.entry-content, .post-content');
        if (descEl) {
          const pEl = descEl.querySelector('p');
          if (pEl) description = (pEl.textContent || '').trim().substring(0, 300);
        }
        
        if (!description) {
          const excerptEl = post.querySelector('.excerpt, .post-excerpt');
          if (excerptEl) description = (excerptEl.textContent || '').trim().substring(0, 300);
        }

        // LOCATION: Chercher dans le texte ou attributs spécialisés
        let location: string | null = null;
        const locEl = post.querySelector('[data-location], .location, .venue, .event-location');
        if (locEl) {
          location = locEl.getAttribute('data-location') || locEl.textContent || '';
          location = location.trim();
        }

        // CATÉGORIES: heuristique sur titre + meta-categories
        const cats: string[] = [];
        
        // D'abord chercher les catégories Wordpress
        const catLinks = Array.from(post.querySelectorAll('a[rel*="category"], .cat-links a')) as Element[];
        if (catLinks.length > 0) {
          for (const catLink of catLinks) {
            const catText = (catLink.textContent || '').toLowerCase();
            if (catText.includes('concert') || catText.includes('musique')) cats.push('concert');
            if (catText.includes('expo') || catText.includes('exhibition')) cats.push('expo');
            if (catText.includes('soirée') || catText.includes('soiree') || catText.includes('club')) cats.push('soiree');
            if (catText.includes('spectacle') || catText.includes('théâtre')) cats.push('spectacle');
          }
        }
        
        // Sinon: heuristique sur titre
        if (cats.length === 0) {
          const lower = title.toLowerCase();
          if (lower.includes('concert') || lower.includes('spectacle') || lower.includes('musique') || lower.includes('dj')) cats.push('concert');
          if (lower.includes('expo') || lower.includes('exposition') || lower.includes('vernissage') || lower.includes('art')) cats.push('expo');
          if (lower.includes('soirée') || lower.includes('soiree') || lower.includes('club') || lower.includes('night')) cats.push('soiree');
          if (lower.includes('spectacle') || lower.includes('théâtre') || lower.includes('theatre')) cats.push('spectacle');
        }

        items.push({
          id: `${sourceName}_${counter++}`,
          title: title.substring(0, 255),
          url: fullUrl,
          source: sourceName,
          categories: cats.length > 0 ? cats : ['event'],
          date,
          image,
          description,
          location: location || 'Marseille',
          organizer: null,
          price: null,
        });
      } catch (e) {
        console.warn('scrapeTarpinBien item error', e);
      }
    }
    
    console.log(`scrapeTarpinBien parsed ${items.length} items from ${url}`);
    return items;
  } catch (e) {
    console.error('scrapeTarpinBien error', e);
    return [];
  }
}

// Parser for marseille-tourisme.com/agenda
async function scrapeMarseilleTourisme(url: string, sourceName: string) {
  try {
    const res = await fetch(url, { method: 'GET', headers: { 'User-Agent': 'Mozilla/5.0' } });
    if (!res.ok) {
      console.warn(`scrapeMarseilleTourisme fetch not ok: ${res.status}`);
      return [];
    }
    const body = await res.text();
    console.log(`scrapeMarseilleTourisme fetched: status=${res.status}, bytes=${body.length}`);
    const doc = await parseHTML(body);
    if (!doc) return [];

    const items: Array<any> = [];
    let counter = 0;
    const seen = new Set<string>();

    // Cibler les blocs événements: .event, .agenda-item, article.post
    const eventEls = Array.from(doc.querySelectorAll('.event, .agenda-item, .event-card, article.post')) as Element[];
    console.log(`scrapeMarseilleTourisme: found ${eventEls.length} event blocks`);
    
    for (const el of eventEls) {
      try {
        // Titre: h2, h3, .event-title
        const titleEl = el.querySelector('h2, h3, .event-title, .post-title');
        const title = titleEl ? (titleEl.textContent || '').trim() : '';
        
        // Lien: chercher le lien dans le titre en priorité, puis ailleurs
        let linkEl = null;
        if (titleEl) {
          linkEl = titleEl.querySelector('a[href]');
          if (!linkEl) linkEl = titleEl.closest('a[href]');
        }
        if (!linkEl) {
          const allLinks = Array.from(el.querySelectorAll('a[href]')) as Element[];
          linkEl = allLinks.find(l => {
            const href = l.getAttribute('href') || '';
            return !href.includes('#') && !href.includes('javascript') && !href.includes('comment');
          });
        }
        const href = linkEl ? linkEl.getAttribute('href') || '' : '';
        
        if (!href || !title || title.length < 3 || seen.has(href)) continue;
        seen.add(href);

        let fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();

        // Date: .event-date, time, data-date
        let date: string | null = null;
        const timeEl = el.querySelector('time[datetime]');
        if (timeEl) {
          date = timeEl.getAttribute('datetime');
        } else {
          const dateEl = el.querySelector('.event-date, .date, .agenda-date');
          if (dateEl) date = (dateEl.textContent || '').trim();
        }

        // Image
        let image: string | null = null;
        const imgEl = el.querySelector('img');
        if (imgEl) {
          image = imgEl.getAttribute('src') || imgEl.getAttribute('data-src');
          if (image && !image.startsWith('http')) {
            image = new URL(image, url).toString();
          }
        }

        // Description
        let description: string | null = null;
        const descEl = el.querySelector('.event-description, .description, .excerpt, p');
        if (descEl) description = (descEl.textContent || '').trim().substring(0, 300);

        // Location
        let location: string | null = null;
        const locEl = el.querySelector('.event-location, .location, .venue');
        if (locEl) {
          location = (locEl.textContent || '').trim();
        } else {
          // Fallback: chercher "à X" dans le texte
          const allText = el.textContent || '';
          const locMatch = allText.match(/à\s+([A-Za-zÀ-ÿ\s-]+)/i);
          if (locMatch) location = locMatch[1].trim().substring(0, 100);
        }

        // Catégories
        const cats: string[] = [];
        const lower = title.toLowerCase();
        if (lower.includes('concert') || lower.includes('musique')) cats.push('concert');
        if (lower.includes('expo') || lower.includes('exposition') || lower.includes('art')) cats.push('expo');
        if (lower.includes('spectacle') || lower.includes('théâtre')) cats.push('spectacle');

        items.push({
          id: `${sourceName}_${counter++}`,
          title: title.substring(0, 255),
          url: fullUrl,
          source: sourceName,
          categories: cats.length > 0 ? cats : ['event'],
          date,
          image,
          description,
          location: location || 'Marseille',
          organizer: null,
          price: null,
        });
      } catch (e) {
        console.warn('scrapeMarseilleTourisme item error', e);
      }
    }
    
    // Fallback: chercher tous les liens avec /agenda/ ou /vivez-marseille/
    if (items.length === 0) {
      const allLinks = Array.from(doc.querySelectorAll('a[href*="agenda"], a[href*="vivez-marseille"]')) as Element[];
      for (const link of allLinks.slice(0, 20)) {
        const href = link.getAttribute('href') || '';
        const text = (link.textContent || '').trim();
        if (!href || !text || seen.has(href)) continue;
        seen.add(href);
        const fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();
        items.push({
          id: `${sourceName}_${counter++}`,
          title: text.substring(0, 255),
          url: fullUrl,
          source: sourceName,
          categories: ['event'],
          date: null,
          image: null,
          description: null,
          location: 'Marseille',
          organizer: null,
          price: null,
        });
      }
    }
    
    console.log(`scrapeMarseilleTourisme parsed ${items.length} events from ${url}`);
    return items;
  } catch (e) {
    console.error('scrapeMarseilleTourisme error', e);
    return [];
  }
}

// Parser for sortiramarseille.fr
async function scrapeSortiraMarseille(url: string, sourceName: string) {
  try {
    const res = await fetch(url, { method: 'GET', headers: { 'User-Agent': 'Mozilla/5.0' } });
    if (!res.ok) {
      console.warn(`scrapeSortiraMarseille fetch not ok: ${res.status}`);
      return [];
    }
    const body = await res.text();
    console.log(`scrapeSortiraMarseille fetched: status=${res.status}, bytes=${body.length}`);
    const doc = await parseHTML(body);
    if (!doc) return [];

    const items: Array<any> = [];
    let counter = 0;
    const seen = new Set<string>();

    // Cibler les blocs événements: .event, .sortie, article, .item
    const eventEls = Array.from(doc.querySelectorAll('.event, .sortie, .item, article, .agenda-item')) as Element[];
    console.log(`scrapeSortiraMarseille: found ${eventEls.length} event blocks`);
    
    for (const el of eventEls) {
      try {
        // Titre
        const titleEl = el.querySelector('h2, h3, .event-title, .title');
        const title = titleEl ? (titleEl.textContent || '').trim() : '';
        
        // Lien: chercher dans le titre d'abord
        let linkEl = null;
        if (titleEl) {
          linkEl = titleEl.querySelector('a[href]');
          if (!linkEl) linkEl = titleEl.closest('a[href]');
        }
        if (!linkEl) {
          const allLinks = Array.from(el.querySelectorAll('a[href]')) as Element[];
          linkEl = allLinks.find(l => {
            const href = l.getAttribute('href') || '';
            return !href.includes('#') && !href.includes('javascript') && !href.includes('comment');
          });
        }
        const href = linkEl ? linkEl.getAttribute('href') || '' : '';
        
        if (!href || !title || title.length < 3 || seen.has(href)) continue;
        if (title.toLowerCase().includes('cookie') || title.toLowerCase().includes('politique')) continue;
        
        seen.add(href);
        let fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();

        // Date
        let date: string | null = null;
        const timeEl = el.querySelector('time[datetime]');
        if (timeEl) {
          date = timeEl.getAttribute('datetime');
        } else {
          const dateEl = el.querySelector('.date, .event-date, .day');
          if (dateEl) date = (dateEl.textContent || '').trim();
        }

        // Image
        let image: string | null = null;
        const imgEl = el.querySelector('img');
        if (imgEl) {
          image = imgEl.getAttribute('src') || imgEl.getAttribute('data-src');
          if (image && !image.startsWith('http')) {
            image = new URL(image, url).toString();
          }
        }

        // Description
        let description: string | null = null;
        const descEl = el.querySelector('.description, .excerpt, p');
        if (descEl) description = (descEl.textContent || '').trim().substring(0, 300);

        // Location
        let location: string | null = null;
        const locEl = el.querySelector('.location, .venue, .place');
        if (locEl) location = (locEl.textContent || '').trim();

        // Catégories
        const cats: string[] = [];
        const lower = title.toLowerCase();
        if (lower.includes('concert') || lower.includes('musique') || lower.includes('dj')) cats.push('concert');
        if (lower.includes('expo') || lower.includes('exposition') || lower.includes('art')) cats.push('expo');
        if (lower.includes('soirée') || lower.includes('soiree') || lower.includes('club')) cats.push('soiree');
        if (lower.includes('spectacle') || lower.includes('théâtre')) cats.push('spectacle');

        items.push({
          id: `${sourceName}_${counter++}`,
          title: title.substring(0, 255),
          url: fullUrl,
          source: sourceName,
          categories: cats.length > 0 ? cats : ['event'],
          date,
          image,
          description,
          location: location || 'Marseille',
          organizer: null,
          price: null,
        });
      } catch (e) {
        console.warn('scrapeSortiraMarseille item error', e);
      }
    }
    
    // Fallback: chercher tous les liens événements
    if (items.length === 0) {
      const allLinks = Array.from(doc.querySelectorAll('a[href*="sortir"], a[href*="event"], a[href*="agenda"]')) as Element[];
      for (const link of allLinks.slice(0, 20)) {
        const href = link.getAttribute('href') || '';
        const text = (link.textContent || '').trim();
        if (!href || !text || text.length < 3 || seen.has(href)) continue;
        if (text.toLowerCase().includes('cookie') || text.toLowerCase().includes('politique')) continue;
        seen.add(href);
        const fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();
        items.push({
          id: `${sourceName}_${counter++}`,
          title: text.substring(0, 255),
          url: fullUrl,
          source: sourceName,
          categories: ['event'],
          date: null,
          image: null,
          description: null,
          location: 'Marseille',
          organizer: null,
          price: null,
        });
      }
    }
    
    console.log(`scrapeSortiraMarseille parsed ${items.length} items from ${url}`);
    return items;
  } catch (e) {
    console.error('scrapeSortiraMarseille error', e);
    return [];
  }
}

// Generic fallback scraper for unknown sources
async function scrapeSite(url: string, sourceName: string) {
  try {
    const res = await fetch(url, { method: 'GET' });
    if (!res.ok) {
      console.warn(`scrapeSite fetch not ok for ${url}: ${res.status}`);
      return [];
    }
    const body = await res.text();
    console.log(`scrapeSite fetched ${url}: status=${res.status}, bytes=${body.length}`);

    const doc = await parseHTML(body);
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

      let date: string | null = null;
      const iso = title.match(/20\d{2}-\d{2}-\d{2}/);
      if (iso) date = iso[0];
      else {
        const dm = title.match(/(\d{1,2}[\/\.-]\d{1,2}[\/\.-](?:20)?\d{2})/);
        if (dm) date = dm[0];
      }

      const fullUrl = href.startsWith('http') ? href : new URL(href, url).toString();
      items.push({ 
        id: `${sourceName}_${counter++}`, 
        title, 
        url: fullUrl, 
        source: sourceName, 
        categories: cats.length > 0 ? cats : ['event'], 
        date,
        image: null,
        description: null,
        location: null,
        organizer: null,
        price: null,
      });
    }
    console.log(`scrapeSite parsed ${items.length} candidate anchors from ${url}`);
    return items;
  } catch (e) {
    console.error('scrape error', e);
    return [];
  }
}

async function scrapeFacebookEvents(url: string, sourceName: string) {
  try {
    const res = await fetch(url, { method: 'GET' });
    if (!res.ok) {
      console.warn(`scrapeFacebookEvents fetch not ok for ${url}: ${res.status}`);
      return [];
    }
    const body = await res.text();
    console.log(`scrapeFacebookEvents fetched ${url}: status=${res.status}, bytes=${body.length}`);
    const doc = await parseHTML(body);
    if (!doc) {
      console.warn('scrapeFacebookEvents: parser returned null for', url);
      return [];
    }

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
    console.log(`scrapeFacebookEvents parsed ${items.length} items from ${url}`);
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
    const doc = await parseHTML(body);
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
  if (req.method === 'POST' && (url.pathname === '/' || url.pathname.endsWith('/update-outings'))) {
    try {
      const started = Date.now();
      let results: any[] = [];
      const perSourceErrors: Record<string, string> = {};
      
      try {
        // 1. Shotgun API (données fiables)
        console.log('🎯 Fetching events from Shotgun API...');
        
        const shotgunQuery = `
          query SearchEvents {
            search(input: {query: "Marseille", types: [EVENT], limit: 100}) {
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
        
        const shotgunResponse = await fetch(SHOTGUN_GRAPHQL_ENDPOINT, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0',
            'Accept': 'application/json',
          },
          body: JSON.stringify({ query: shotgunQuery }),
        });
        
        if (shotgunResponse.ok) {
          const shotgunData = await shotgunResponse.json();
          const shotgunEvents = shotgunData?.data?.search?.events || [];
          console.log(`✅ Shotgun API returned ${shotgunEvents.length} events`);
          
          const now = new Date();
          let counter = 0;
          
          for (const event of shotgunEvents) {
            try {
              const startDate = event.startDate ? new Date(event.startDate) : null;
              
              // Ignorer événements passés de plus de 2h
              if (startDate && startDate < new Date(now.getTime() - 2 * 60 * 60 * 1000)) {
                continue;
              }
              
              const categories = (event.categories || [])
                .map((c: string) => c.toLowerCase())
                .filter(Boolean);
              
              results.push({
                id: `shotgun_${counter++}`,
                title: event.title || '(Sans titre)',
                url: `https://shotgun.live/fr/events/${event.slug}`,
                source: 'shotgun',
                categories: categories.length > 0 ? categories : ['event'],
                date: startDate ? startDate.toISOString().substring(0, 10) : null,
                image: event.image?.url || null,
                description: event.description || null,
                location: event.location?.name || event.location?.city || 'Marseille',
                organizer: null,
                price: null,
              });
            } catch (parseErr) {
              console.warn('⚠️ Error parsing Shotgun event', parseErr);
            }
          }
          
          console.log(`✅ Parsed ${results.length} valid events from Shotgun`);
        } else {
          console.error(`❌ Shotgun API error: ${shotgunResponse.status}`);
          perSourceErrors['shotgun'] = `HTTP ${shotgunResponse.status}`;
        }
        
        // 2. Les 3 scrapers (données supplémentaires)
        console.log('🌐 Scraping 3 additional sources...');
        
        const scrapePromises = SOURCES.map(async (s) => {
          try {
            let items: any[] = [];
            if (s.name === 'tarpin-bien') {
              items = await scrapeTarpinBien(s.url, s.name);
            } else if (s.name === 'sortiramarseille') {
              items = await scrapeSortiraMarseille(s.url, s.name);
            } else if (s.name === 'marseille-tourisme') {
              items = await scrapeMarseilleTourisme(s.url, s.name);
            }
            return items;
          } catch (e) {
            console.error(`Source scrape error (${s.name})`, e);
            perSourceErrors[s.name] = String(e);
            return [];
          }
        });
        
        const allScraped = await Promise.all(scrapePromises);
        for (const items of allScraped) {
          results.push(...items);
        }
        
        console.log(`✅ Total events: ${results.length} (Shotgun + 3 scrapers)`);
        
      } catch (e) {
        console.error('❌ Global scrape error', e);
        perSourceErrors['global'] = String(e);
      }

      // Déduplication par URL
      const map: Record<string, any> = {};
      for (const it of results) {
        if (it.url) map[it.url] = it;
      }
      const deduped = Object.values(map);

      // Enrichir les 10 premiers événements avec og:image et meta description
      console.log('🔍 Enriching event details (sample)...');
      const toEnrich = deduped.slice(0, 10);
      const enrichPromises = toEnrich.map((item: any) => enrichEventDetails(item, 3000));
      const enriched = await Promise.all(enrichPromises);
      
      // Remplacer les éléments enrichis dans deduped
      for (let i = 0; i < enriched.length; i++) {
        deduped[i] = enriched[i];
      }
      console.log(`✅ Enriched ${enriched.length} events`);

      // Normalisation avec tous les champs enrichis + UUID pour id
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const defaultDate = tomorrow.toISOString().substring(0, 10);
      
      const normalized = deduped.map((r: any) => {
        try {
          // Generate UUID for id (required by outings table)
          const id = crypto.randomUUID();
          const parsedDate = normalizeDate(r.date);
          return {
            id,
            url: r.url,
            title: (r.title || '').substring(0, 255),
            source: (r.source || '').substring(0, 50),
            categories: Array.isArray(r.categories) ? r.categories : [],
            date: parsedDate || defaultDate,  // Use default date if parsing fails (required NOT NULL)
            image: r.image || null,
            description: r.description ? r.description.substring(0, 500) : null,
            location: r.location || 'Marseille',
            last_seen: new Date().toISOString(),
          };
        } catch (e) {
          console.error('Error normalizing row', r, e);
          return null;
        }
      }).filter((r: any) => r !== null);

      console.log('Scrape completed', {
        total_raw: results.length,
        total_deduped: deduped.length,
        total_normalized: normalized.length,
        sources: SOURCES.map(s => s.name),
        errors: perSourceErrors,
        ms: Date.now() - started,
      });

      // Try to upsert normalized events into `outings` table via Supabase REST
      let inserted_count = 0;
      try {
        // Validate: ensure all URLs are non-empty
        const validRows = normalized.filter((row: any) => row && row.url && String(row.url).trim());
        console.log(`upsertOutingsToDB: ${validRows.length}/${normalized.length} rows have non-empty URL`);
        if (validRows.length === 0) {
          console.warn('upsertOutingsToDB: no valid rows to upsert (all URLs empty)');
        } else {
          const upsertRes = await upsertOutingsToDB(validRows);
          console.log('upsertOutingsToDB response:', { ok: upsertRes.ok, status: upsertRes.status, dataType: typeof upsertRes.data, dataIsArray: Array.isArray(upsertRes.data) });
          if (!upsertRes.ok) {
            console.error('upsert error status', upsertRes.status, 'data:', upsertRes.data);
          } else if (Array.isArray(upsertRes.data)) {
            inserted_count = upsertRes.data.length;
            console.log('✅ upsertOutingsToDB success: inserted', inserted_count, 'rows');
          } else if (upsertRes.data && typeof upsertRes.data === 'object') {
            inserted_count = 1;
            console.log('✅ upsertOutingsToDB success: inserted 1 row');
          }
        }
      } catch (e) {
        console.error('Error upserting outings', e);
      }

      return json({
        success: true,
        inserted_count,
        events_preview: normalized.slice(0, 5),
        total_events: normalized.length,
        errors: perSourceErrors,
        elapsed_ms: Date.now() - started,
        note: inserted_count && inserted_count > 0 ? 'Inserted/updated into outings table' : 'No inserted outings (preview only)'
      });
    } catch (e) {
      console.error('Fatal error in /update-outings endpoint', e);
      return json({ success: false, error: 'Fatal error', detail: String(e) }, 500);
    }
  }

  // GET /suggestions?limit=3&cats=electro,expo -> retourne 3-5 événements aléatoires filtrés
  if (req.method === 'GET' && url.pathname.endsWith('/suggestions')) {
    try {
      const qp = url.searchParams;
      const limit = Math.min(10, Math.max(1, parseInt(qp.get('limit') || '3')));
      const catsParam = qp.get('cats');
      const cats = catsParam ? catsParam.split(',').map(s => s.trim().toLowerCase()).filter(Boolean) : [];

      // Fetch a batch and sample server-side to allow random selection
      const rows = await fetchOutingsBatch(200);
      let candidates = Array.isArray(rows) ? rows : [];
      if (cats.length > 0) {
        candidates = candidates.filter((r: any) => {
          const rcats = Array.isArray(r.categories) ? r.categories.map((c: any) => String(c).toLowerCase()) : [];
          return cats.some(c => rcats.includes(c));
        });
      }

      // Shuffle
      for (let i = candidates.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [candidates[i], candidates[j]] = [candidates[j], candidates[i]];
      }

      const chosen = candidates.slice(0, limit);
      return json({ success: true, count: chosen.length, events: chosen });
    } catch (e) {
      console.error('suggestions handler error', e);
      return json({ success: false, error: String(e) }, 500);
    }
  }

  // GET existant (renvoie juste la liste brute pour debug)
  if (req.method === 'GET') {
    try {
      const results: any[] = [];
      // Try to fetch active sources from DB
      let activeSources = SOURCES;
      try {
        const rows = await fetchActiveSourcesFromDB();
        if (rows && Array.isArray(rows) && rows.length > 0) activeSources = rows.map((r: any) => ({ name: r.source || r.name, url: r.url }));
      } catch (e) {
        console.error('Error fetching scrape_sources for GET', e);
      }

      // Parallelize all sources to avoid timeout
      const scrapePromises = activeSources.map(async (s) => {
        try {
          if (s.name === 'vortex_fb') {
            return await scrapeFacebookEvents(s.url, s.name);
          } else {
            return await scrapeSite(s.url, s.name);
          }
        } catch (e) {
          console.error(`GET source error ${s.name}`, e);
          return [];
        }
      });
      const allScraped = await Promise.all(scrapePromises);
      for (const items of allScraped) {
        results.push(...items);
      }
      const map: Record<string, any> = {};
      for (const it of results) if (it.url) map[it.url] = it;
      return json({ success: true, total: Object.keys(map).length, data: Object.values(map).slice(0, 20) });
    } catch (e) {
      console.error('GET handler error', e);
      return json({ success: false, error: String(e) }, 500);
    }
  }

  // GET /outings-filtered?user_id=<uuid> -> retourne 5 événements filtrés par préférences
  if (req.method === 'GET' && url.pathname === '/') {
    const userIdParam = url.searchParams.get('user_id');
    if (userIdParam) {
      try {
        const userId = userIdParam;
        console.log(`📤 Filtering outings for user ${userId}`);

        // Fetch user preferences from DB
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
          }
        } catch (e) {
          console.warn('Could not fetch user preferences', e);
        }

        // Default preferences if not found
        if (!prefs) {
          prefs = {
            preferred_categories: ['concert', 'soiree', 'electro', 'expo'],
            preferred_start_time: '19:00',
            preferred_end_time: '03:00',
            min_price: 0,
            max_price: 1000,
            exclude_keywords: ['enfant', 'jeune public', 'famille', 'kids'],
          };
        }

        // Fetch outings from DB (future events, limit 100 for filtering)
        const today = new Date().toISOString().substring(0, 10);
        const outingsUrl = `${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/outings?date=gte.${today}&limit=100&order=date.asc`;
        const outingsRes = await fetch(outingsUrl, {
          method: 'GET',
          headers: {
            'apikey': SUPABASE_SERVICE_ROLE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          },
        });
        const outings = await outingsRes.json();
        if (!Array.isArray(outings)) return json({ success: false, error: 'Failed to fetch outings' }, 500);

        // Filter by preferences
        const filtered = outings.filter((event: any) => {
          // 1. Category filter
          const eventCats = Array.isArray(event.categories) ? event.categories.map((c: any) => String(c).toLowerCase()) : [];
          const prefCats = (prefs.preferred_categories || []).map((c: any) => String(c).toLowerCase());
          if (prefCats.length > 0 && !prefCats.some((pc: any) => eventCats.includes(pc))) {
            return false;
          }

          // 2. Exclude keywords
          const title = (event.title || '').toLowerCase();
          const excludeWords = (prefs.exclude_keywords || []).map((w: any) => String(w).toLowerCase());
          if (excludeWords.some((w: any) => title.includes(w))) {
            return false;
          }

          // 3. Price filter (if available)
          if (event.price) {
            try {
              const price = parseFloat(event.price);
              if (!isNaN(price)) {
                if (price < (prefs.min_price || 0) || price > (prefs.max_price || 1000)) {
                  return false;
                }
              }
            } catch (e) {
              // ignore price filter errors
            }
          }

          return true;
        });

        // Return top 5 events
        const result = filtered.slice(0, 5);
        console.log(`✅ Found ${filtered.length}/${outings.length} matching events for user ${userId}, returning ${result.length}`);

        return json({
          success: true,
          user_id: userId,
          count: result.length,
          events: result,
          preferences: prefs,
          total_available: filtered.length,
        });
      } catch (e) {
        console.error('filter-outings handler error', e);
        return json({ success: false, error: String(e) }, 500);
      }
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
