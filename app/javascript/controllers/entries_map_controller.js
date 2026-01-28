import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    entries: { type: Array, default: [] },
    centerLat: { type: Number, default: 35.6812 },
    centerLng: { type: Number, default: 139.7671 },
    boundary: String
  }

  async connect() {
    this.map = null
    this.markers = []
    this.boundaryLayer = null
    await this.loadLeaflet()
    this.initMap()
  }

  async loadLeaflet() {
    if (window.L) return

    if (!document.querySelector('link[href*="leaflet.css"]')) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
      document.head.appendChild(link)
    }

    await this.loadScript('https://unpkg.com/leaflet@1.9.4/dist/leaflet.js')
    await this.waitFor(() => window.L, 5000)
  }

  loadScript(src) {
    return new Promise((resolve, reject) => {
      if (document.querySelector(`script[src="${src}"]`)) {
        resolve()
        return
      }
      const script = document.createElement('script')
      script.src = src
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  waitFor(condition, timeout = 5000) {
    return new Promise((resolve, reject) => {
      const start = Date.now()
      const check = () => {
        if (condition()) {
          resolve()
        } else if (Date.now() - start > timeout) {
          reject(new Error('Timeout waiting for condition'))
        } else {
          setTimeout(check, 50)
        }
      }
      check()
    })
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  initMap() {
    if (!this.hasContainerTarget) return

    // Initialize map
    this.map = L.map(this.containerTarget, {
      scrollWheelZoom: true,
      dragging: true
    }).setView([this.centerLatValue, this.centerLngValue], 14)

    // Add OpenStreetMap tiles
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Add boundary if present
    if (this.hasBoundaryValue && this.boundaryValue) {
      this.addBoundary()
    }

    // Add entry markers
    if (this.entriesValue.length > 0) {
      this.addEntryMarkers()
    }

    // Handle resize
    this.resizeObserver = new ResizeObserver(() => {
      if (this.map) {
        this.map.invalidateSize()
      }
    })
    this.resizeObserver.observe(this.containerTarget)
  }

  addBoundary() {
    try {
      const geojson = JSON.parse(this.boundaryValue)
      this.boundaryLayer = L.geoJSON(geojson, {
        style: {
          color: "#6366f1",
          weight: 2,
          fillColor: "#6366f1",
          fillOpacity: 0.05
        }
      }).addTo(this.map)
    } catch (e) {
      console.error("Invalid boundary GeoJSON:", e)
    }
  }

  addEntryMarkers() {
    // Group entries by spot (same coordinates)
    const spotGroups = new Map()

    this.entriesValue.forEach(entry => {
      const key = `${entry.lat},${entry.lng}`
      if (!spotGroups.has(key)) {
        spotGroups.set(key, [])
      }
      spotGroups.get(key).push(entry)
    })

    const bounds = L.latLngBounds([])

    spotGroups.forEach((entries, key) => {
      const [lat, lng] = key.split(",").map(Number)
      bounds.extend([lat, lng])

      if (entries.length === 1) {
        // Single entry at this location
        this.addSingleMarker(entries[0])
      } else {
        // Multiple entries at this location - create cluster marker
        this.addClusterMarker(lat, lng, entries)
      }
    })

    // Fit map to show all markers
    if (bounds.isValid()) {
      this.map.fitBounds(bounds, { padding: [30, 30] })
    }
  }

  addSingleMarker(entry) {
    const marker = L.marker([entry.lat, entry.lng], {
      icon: this.createIcon(1)
    }).addTo(this.map)

    const popupContent = this.createEntryPopup(entry)
    marker.bindPopup(popupContent)

    this.markers.push(marker)
  }

  addClusterMarker(lat, lng, entries) {
    const marker = L.marker([lat, lng], {
      icon: this.createIcon(entries.length)
    }).addTo(this.map)

    const popupContent = this.createClusterPopup(entries)
    marker.bindPopup(popupContent, {
      maxWidth: 300,
      maxHeight: 400
    })

    this.markers.push(marker)
  }

  createIcon(count) {
    const size = count > 1 ? 40 : 32
    const color = count > 1 ? "#f59e0b" : "#3b82f6"  // Orange for clusters, blue for single

    if (count > 1) {
      return L.divIcon({
        className: "custom-cluster-marker",
        html: `
          <div style="
            background-color: ${color};
            width: ${size}px;
            height: ${size}px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 14px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.3);
            border: 2px solid white;
          ">${count}</div>
        `,
        iconSize: [size, size],
        iconAnchor: [size / 2, size / 2],
        popupAnchor: [0, -size / 2]
      })
    }

    return L.divIcon({
      className: "custom-marker",
      html: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${color}" width="${size}" height="${size}">
        <path fill-rule="evenodd" d="m11.54 22.351.07.04.028.016a.76.76 0 0 0 .723 0l.028-.015.071-.041a16.975 16.975 0 0 0 1.144-.742 19.58 19.58 0 0 0 2.683-2.282c1.944-1.99 3.963-4.98 3.963-8.827a8.25 8.25 0 0 0-16.5 0c0 3.846 2.02 6.837 3.963 8.827a19.58 19.58 0 0 0 2.682 2.282 16.975 16.975 0 0 0 1.145.742ZM12 13.5a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" clip-rule="evenodd" />
      </svg>`,
      iconSize: [size, size],
      iconAnchor: [size / 2, size],
      popupAnchor: [0, -size]
    })
  }

  createEntryPopup(entry) {
    const popup = entry.popup || {}
    return `
      <div class="entry-popup" style="min-width: 200px;">
        <div style="font-weight: 600; font-size: 14px; margin-bottom: 4px;">${this.escapeHtml(popup.title || "無題")}</div>
        ${popup.subtitle ? `<div style="color: #10b981; font-size: 12px; margin-bottom: 4px;">${this.escapeHtml(popup.subtitle)}</div>` : ""}
        ${popup.description ? `<div style="color: #6b7280; font-size: 11px; margin-bottom: 8px;">${this.escapeHtml(popup.description)}</div>` : ""}
        <a href="${entry.entryPath}" style="color: #4f46e5; font-size: 12px; text-decoration: none;">詳細を見る →</a>
      </div>
    `
  }

  createClusterPopup(entries) {
    const spotName = entries[0].popup?.subtitle || "スポット"
    const entriesHtml = entries.map(entry => {
      const popup = entry.popup || {}
      return `
        <div style="padding: 8px 0; border-bottom: 1px solid #e5e7eb;">
          <div style="font-weight: 500; font-size: 13px;">${this.escapeHtml(popup.title || "無題")}</div>
          ${popup.description ? `<div style="color: #6b7280; font-size: 11px; margin: 2px 0;">${this.escapeHtml(popup.description)}</div>` : ""}
          <a href="${entry.entryPath}" style="color: #4f46e5; font-size: 11px; text-decoration: none;">詳細 →</a>
        </div>
      `
    }).join("")

    return `
      <div class="cluster-popup">
        <div style="font-weight: 600; font-size: 14px; color: #10b981; margin-bottom: 8px; border-bottom: 2px solid #10b981; padding-bottom: 4px;">
          📍 ${this.escapeHtml(spotName)} (${entries.length}件)
        </div>
        <div style="max-height: 250px; overflow-y: auto;">
          ${entriesHtml}
        </div>
      </div>
    `
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
