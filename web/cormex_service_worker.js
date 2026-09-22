const scopeKey = new URL(self.registration.scope).pathname
  .replace(/[^a-z0-9]+/gi, '-')
  .replace(/^-+|-+$/g, '') || 'root';
const cachePrefix = 'cormex-easy-' + scopeKey + '-';
const cacheName = cachePrefix + 'offline-v3';
const shellAssets = [
  './',
  './index.html',
  './flutter_bootstrap.js',
  './main.dart.js',
  './manifest.json',
  './assets/AssetManifest.bin',
  './assets/FontManifest.json',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(cacheName);
    await Promise.all(shellAssets.map(async (path) => {
      try {
        const url = new URL(path, self.registration.scope);
        const response = await fetch(url, { cache: 'reload' });
        if (response.ok) await cache.put(url, response);
      } catch (_) {
        // O restante do shell continua disponível se um item for opcional.
      }
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((key) => key.startsWith(cachePrefix) && key !== cacheName)
          .map((key) => caches.delete(key)),
      ))
      .then(() => self.clients.claim()),
  );
});

async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok || response.type === 'opaque') {
      try {
        const cache = await caches.open(cacheName);
        await cache.put(request, response.clone());
      } catch (_) {
        // Alguns tipos de resposta não podem ser armazenados.
      }
    }
    return response;
  } catch (_) {
    const cached = await caches.match(request, { ignoreSearch: true });
    if (cached) return cached;
    if (request.mode === 'navigate') {
      const root = new URL('./', self.registration.scope);
      const fallback = await caches.match(root, { ignoreSearch: true });
      if (fallback) return fallback;
    }
    return new Response('CormeX Easy está sem conexão.', {
      status: 503,
      headers: { 'Content-Type': 'text/plain; charset=utf-8' },
    });
  }
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  const sameOrigin = url.origin === self.location.origin;
  const cacheableImage = request.destination === 'image';
  if (!sameOrigin && !cacheableImage) return;
  event.respondWith(networkFirst(request));
});

self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
