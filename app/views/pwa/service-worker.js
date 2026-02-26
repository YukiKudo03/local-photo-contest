const CACHE_VERSION = "v1"
const CACHE_NAME = `local-photo-contest-${CACHE_VERSION}`
const OFFLINE_URL = "/offline.html"

// Assets to pre-cache on install
const PRECACHE_ASSETS = [
  OFFLINE_URL,
  "/icon.png",
  "/icon-192.png"
]

// Install: pre-cache essential assets
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS)
    })
  )
  self.skipWaiting()
})

// Activate: clean up old caches
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name.startsWith("local-photo-contest-") && name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      )
    })
  )
  self.clients.claim()
})

// Fetch: apply caching strategies
self.addEventListener("fetch", (event) => {
  const { request } = event

  // Only handle GET requests
  if (request.method !== "GET") return

  const url = new URL(request.url)

  // Skip cross-origin requests (CDNs, external APIs)
  if (url.origin !== self.location.origin) return

  // Cache First: static assets (CSS, JS, images, fonts)
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request))
    return
  }

  // Network First: HTML pages
  if (request.headers.get("Accept")?.includes("text/html")) {
    event.respondWith(networkFirstWithOfflineFallback(request))
    return
  }
})

// Cache First strategy for static assets
async function cacheFirst(request) {
  const cached = await caches.match(request)
  if (cached) return cached

  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    return new Response("", { status: 408, statusText: "Offline" })
  }
}

// Network First strategy with offline fallback for HTML
async function networkFirstWithOfflineFallback(request) {
  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    const cached = await caches.match(request)
    if (cached) return cached

    return caches.match(OFFLINE_URL)
  }
}

// Check if a path is a static asset
function isStaticAsset(pathname) {
  return /\.(css|js|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$/.test(pathname) ||
    pathname.startsWith("/assets/")
}
