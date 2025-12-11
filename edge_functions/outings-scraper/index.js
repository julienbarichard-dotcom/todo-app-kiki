const express = require('express');
const fetch = require('node-fetch');
const cheerio = require('cheerio');

const app = express();
app.use(express.json());

const SOURCES = [
  { name: 'sortiramarseille', url: 'https://www.sortiramarseille.fr/' },
  { name: 'tarpin-bien', url: 'https://tarpin-bien.com/' },
  { name: 'marseille-tourisme', url: 'https://www.marseille-tourisme.com/vivez-marseille-blog/agenda/' },
];

async function scrapeSite(url, sourceName) {
  try {
    const res = await fetch(url, { timeout: 6000 });
    if (!res.ok) return [];
    const body = await res.text();
    const $ = cheerio.load(body);
    const items = [];

    // Heuristic: iterate anchors and keep those containing keywords
    $('a').each((i, el) => {
      const href = $(el).attr('href') || '';
      let title = $(el).text() || '';
      title = title.trim();
      if (!title) return;
      const low = title.toLowerCase();
      const cats = [];
      if (low.includes('electro') || low.includes('dj') || low.includes('concert')) cats.push('electro');
      if (low.includes('expo') || low.includes('vernissage') || low.includes('exposition')) cats.push('expo');
      if (cats.length === 0) return;

      items.push({
        id: `${sourceName}_${i}`,
        title: title,
        url: href.startsWith('http') ? href : (url + href),
        source: sourceName,
        categories: cats
      });
    });

    return items;
  } catch (e) {
    console.error('scrape error', e);
    return [];
  }
}

app.get('/events', async (req, res) => {
  const results = [];
  for (const s of SOURCES) {
    const items = await scrapeSite(s.url, s.name);
    results.push(...items);
  }
  // dedupe by url
  const map = {};
  for (const it of results) map[it.url] = it;
  res.json(Object.values(map));
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Outings scraper listening on ${port}`));
