const environment = self.registration.scope.includes('/qa/')
  ? 'qa'
  : 'production';
const cachePrefix = `cormex-easy-${environment}-`;
const cacheName = `${cachePrefix}v1`;
const scopeUrl = new URL('./', self.registration.scope);
const shellFiles = [
  './',
  'index.html',
  'manifest.json',
  'pwa_install.js',
  'flutter_bootstrap.js',
  'main.dart.js',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
].map((path) => new URL(path, scopeUrl).toString());

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(cacheName)
      .then((cache) => Promise.allSettled(
        shellFiles.map((file) => cache.add(file)),
      ))
      .then(() => self.skipWaiting()),
  );
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

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);

  if (
    request.method !== 'GET' ||
    url.origin !== self.location.origin ||
    !request.url.startsWith(self.registration.scope)
  ) {
    return;
  }

  if (request.mode === 'navigate') {
    event.respondWith(networkFirstNavigation(request));
    return;
  }

  event.respondWith(networkFirstAsset(request));
});

async function networkFirstNavigation(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      await cache.put(request, response.clone());
    }
    return response;
  } catch (_) {
    const cache = await caches.open(cacheName);
    return await cache.match(request) ||
      await cache.match(new URL('./', scopeUrl).toString()) ||
      await cache.match(new URL('index.html', scopeUrl).toString()) ||
      Response.error();
  }
}

async function networkFirstAsset(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      await cache.put(request, response.clone());
    }
    return response;
  } catch (_) {
    return await caches.match(request) || Response.error();
  }
}

self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
