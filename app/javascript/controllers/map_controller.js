import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    latitude: { type: Number, default: 35.6812 },  // Tokyo Station as default
    longitude: { type: Number, default: 139.7671 },
    zoom: { type: Number, default: 13 },
    boundaryGeojson: String,
    markers: { type: Array, default: [] },
    interactive: { type: Boolean, default: true }
  }

  connect() {
    this.map = null
    this.markerLayer = null
    this.boundaryLayer = null
    this.loadLeaflet().then(() => this.initMap())
  }

  async loadLeaflet() {
    if (window.L) return

    // Load Leaflet CSS
    if (!document.querySelector('link[href*="leaflet.css"]')) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
      document.head.appendChild(link)
    }

    // Load Leaflet JS
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
      scrollWheelZoom: this.interactiveValue,
      dragging: this.interactiveValue,
      doubleClickZoom: this.interactiveValue,
      touchZoom: this.interactiveValue
    }).setView([this.latitudeValue, this.longitudeValue], this.zoomValue)

    // Add OpenStreetMap tiles
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Initialize layers
    this.markerLayer = L.layerGroup().addTo(this.map)
    this.boundaryLayer = L.layerGroup().addTo(this.map)

    // Load initial data
    if (this.hasBoundaryGeojsonValue && this.boundaryGeojsonValue) {
      this.addPolygon(this.boundaryGeojsonValue)
    }

    if (this.markersValue.length > 0) {
      this.addMarkers(this.markersValue)
    } else if (!this.hasBoundaryGeojsonValue || !this.boundaryGeojsonValue) {
      // Add center marker if no boundary and no markers
      this.addCenterMarker()
    }

    // Handle resize
    this.resizeObserver = new ResizeObserver(() => {
      if (this.map) {
        this.map.invalidateSize()
      }
    })
    this.resizeObserver.observe(this.containerTarget)
  }

  addCenterMarker() {
    if (!this.map) return
    const marker = L.marker([this.latitudeValue, this.longitudeValue])
    this.markerLayer.addLayer(marker)
  }

  setCenter(lat, lng, zoom = null) {
    if (!this.map) return
    this.map.setView([lat, lng], zoom || this.zoomValue)
  }

  addMarker(lat, lng, options = {}) {
    if (!this.map) return null

    const markerOptions = {}
    if (options.icon) {
      markerOptions.icon = this.createIcon(options.icon)
    }

    const marker = L.marker([lat, lng], markerOptions)

    if (options.popup) {
      marker.bindPopup(this.createPopupContent(options.popup))
    }

    if (options.onClick) {
      marker.on("click", options.onClick)
    }

    this.markerLayer.addLayer(marker)
    return marker
  }

  addMarkers(markers) {
    if (!this.map || !markers.length) return

    markers.forEach(markerData => {
      if (markerData.lat && markerData.lng) {
        this.addMarker(markerData.lat, markerData.lng, {
          popup: markerData.popup,
          icon: markerData.icon
        })
      }
    })

    this.fitToMarkers()
  }

  clearMarkers() {
    if (this.markerLayer) {
      this.markerLayer.clearLayers()
    }
  }

  addPolygon(geojsonString) {
    if (!this.map) return null

    try {
      const geojson = typeof geojsonString === "string"
        ? JSON.parse(geojsonString)
        : geojsonString

      const polygon = L.geoJSON(geojson, {
        style: {
          color: "#3b82f6",
          weight: 2,
          opacity: 0.8,
          fillColor: "#3b82f6",
          fillOpacity: 0.15
        }
      })

      this.boundaryLayer.addLayer(polygon)
      this.fitBounds(polygon.getBounds())
      return polygon
    } catch (e) {
      console.error("Invalid GeoJSON:", e)
      return null
    }
  }

  clearBoundary() {
    if (this.boundaryLayer) {
      this.boundaryLayer.clearLayers()
    }
  }

  fitBounds(bounds) {
    if (!this.map || !bounds || !bounds.isValid()) return
    this.map.fitBounds(bounds, { padding: [20, 20] })
  }

  fitToMarkers() {
    if (!this.markerLayer || this.markerLayer.getLayers().length === 0) return

    const bounds = L.latLngBounds([])
    this.markerLayer.eachLayer(layer => {
      if (layer.getLatLng) {
        bounds.extend(layer.getLatLng())
      }
    })

    if (bounds.isValid()) {
      this.fitBounds(bounds)
    }
  }

  createPopupContent(popup) {
    if (typeof popup === "string") return popup

    let html = ""
    if (popup.title) {
      html += `<div class="popup-title">${this.escapeHtml(popup.title)}</div>`
    }
    if (popup.subtitle) {
      html += `<div class="popup-subtitle">${this.escapeHtml(popup.subtitle)}</div>`
    }
    if (popup.description) {
      html += `<div class="popup-description">${this.escapeHtml(popup.description)}</div>`
    }
    return html || this.escapeHtml(String(popup))
  }

  createIcon(iconType) {
    // Custom icon colors
    const colors = {
      default: "#3b82f6",
      selected: "#10b981",
      restaurant: "#ef4444",
      retail: "#f59e0b",
      landmark: "#8b5cf6",
      park: "#22c55e"
    }

    const color = colors[iconType] || colors.default

    return L.divIcon({
      className: "custom-marker",
      html: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${color}" width="32" height="32">
        <path fill-rule="evenodd" d="m11.54 22.351.07.04.028.016a.76.76 0 0 0 .723 0l.028-.015.071-.041a16.975 16.975 0 0 0 1.144-.742 19.58 19.58 0 0 0 2.683-2.282c1.944-1.99 3.963-4.98 3.963-8.827a8.25 8.25 0 0 0-16.5 0c0 3.846 2.02 6.837 3.963 8.827a19.58 19.58 0 0 0 2.682 2.282 16.975 16.975 0 0 0 1.145.742ZM12 13.5a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" clip-rule="evenodd" />
      </svg>`,
      iconSize: [32, 32],
      iconAnchor: [16, 32],
      popupAnchor: [0, -32]
    })
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // Value change callbacks
  latitudeValueChanged() {
    if (this.map && !this.hasBoundaryGeojsonValue) {
      this.setCenter(this.latitudeValue, this.longitudeValue)
    }
  }

  longitudeValueChanged() {
    if (this.map && !this.hasBoundaryGeojsonValue) {
      this.setCenter(this.latitudeValue, this.longitudeValue)
    }
  }

  markersValueChanged() {
    if (this.map) {
      this.clearMarkers()
      this.addMarkers(this.markersValue)
    }
  }

  boundaryGeojsonValueChanged() {
    if (this.map) {
      this.clearBoundary()
      if (this.boundaryGeojsonValue) {
        this.addPolygon(this.boundaryGeojsonValue)
      }
    }
  }
}
