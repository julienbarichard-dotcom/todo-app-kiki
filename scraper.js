#!/usr/bin/env node

/**
 * Standalone scraper Node.js pour tester et remplir la DB outings
 * Usage: node scraper.js
 */

const https = require('https');
const http = require('http');

const SUPABASE_URL = 'https://joupiybyhoytfuncqmyv.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjU5NzIwNSwiZXhwIjoyMDQ4MTczMjA1fQ.FaP0XW3OlhxXvjOWjhKLxgUu0EH1L0wVl0sVY9mVqkA';

async function fetch(url, options = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const protocol = urlObj.protocol === 'https:' ? https : http;
    const defaultHeaders = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'apikey': SUPABASE_KEY,
    };
    
    const opts = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: options.method || 'GET',
      headers: { ...defaultHeaders, ...options.headers },
      timeout: options.timeout || 30000,
    };
    
    const req = protocol.request(opts, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ ok: res.statusCode >= 200 && res.statusCode < 300, status: res.statusCode, data: json });
        } catch (e) {
          resolve({ ok: res.statusCode >= 200 && res.statusCode < 300, status: res.statusCode, data });
        }
      });
    });
    
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
    
    if (options.body) req.write(JSON.stringify(options.body));
    req.end();
  });
}

async function scrapeTarpinBien() {
  console.log('🌐 Scraping tarpin-bien.com...');
  try {
    const res = await fetch('https://tarpin-bien.com/?evenementCheck=1');
    if (!res.ok) {
      console.error('❌ tarpin-bien status:', res.status);
      return [];
    }
    
    // Simple regex parsing
    const html = res.data;
    const items = [];
    const regex = /<h2[^>]*class="entry-title"[^>]*>[\s\S]*?<a[^>]*href="([^"]+)"[^>]*>([^<]+)<\/a>/g;
    let match;
    while ((match = regex.exec(html)) !== null) {
      const url = match[1];
      const title = match[2];
      if (title && url && !items.find(i => i.url === url)) {
        items.push({
          title: title.trim().substring(0, 255),
          url: url.startsWith('http') ? url : new URL(url, 'https://tarpin-bien.com').toString(),
          source: 'tarpin-bien',
          categories: ['event'],
          date: null,
          image: null,
          description: null,
          location: 'Marseille',
        });
      }
    }
    console.log(`✅ Found ${items.length} events from tarpin-bien`);
    return items;
  } catch (e) {
    console.error('❌ tarpin-bien error:', e.message);
    return [];
  }
}

async function upsertToDB(events) {
  console.log(`\n💾 Upserting ${events.length} events to DB...`);
  if (events.length === 0) {
    console.log('⚠️  No events to upsert');
    return;
  }
  
  const rows = events.map((e, i) => ({
    id: require('crypto').randomUUID(),
    url: e.url,
    title: e.title,
    source: e.source,
    categories: e.categories || [],
    date: e.date || new Date().toISOString().substring(0, 10),
    image: e.image,
    description: e.description,
    location: e.location,
    last_seen: new Date().toISOString(),
  }));
  
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/outings?on_conflict=url`, {
      method: 'POST',
      headers: {
        'Prefer': 'resolution=merge-duplicates, return=representation',
      },
      body: rows,
    });
    
    if (!res.ok) {
      console.error('❌ Upsert failed:', res.status, res.data);
      return;
    }
    
    console.log(`✅ Upserted ${rows.length} rows successfully`);
    if (Array.isArray(res.data)) {
      console.log(`   Inserted/updated count: ${res.data.length}`);
      console.log('\n📊 Sample events:');
      res.data.slice(0, 3).forEach(e => {
        console.log(`   - [${e.source}] ${e.title}`);
        console.log(`     📅 ${e.date} | 📍 ${e.location}`);
      });
    }
  } catch (e) {
    console.error('❌ Upsert error:', e.message);
  }
}

async function main() {
  console.log('🚀 Standalone Event Scraper\n');
  
  const events = [];
  
  // Scrape sources
  events.push(...await scrapeTarpinBien());
  
  // Upsert to DB
  await upsertToDB(events);
  
  console.log('\n✨ Done!');
}

main().catch(console.error);
