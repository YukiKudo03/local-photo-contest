import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "mapContainer", "mapWrapper"]
  static values = {
    areas: { type: Array, default: [] }
  }

  connect() {
    this.map = null
    this.marker = null
    this.polygon = null
    this.updateMapVisibility()
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

  areaChanged() {
    this.updateMapVisibility()
  }

  updateMapVisibility() {
    const selectedAreaId = this.selectTarget.value
    const area = this.findArea(selectedAreaId)

    if (area && (area.latitude || area.boundary_geojson)) {
      this.showMap(area)
    } else {
      this.hideMap()
    }
  }

  findArea(id) {
    if (!id) return null
    return this.areasValue.find(a => a.id === parseInt(id))
  }

  async showMap(area) {
    if (this.hasMapWrapperTarget) {
      this.mapWrapperTarget.classList.remove("hidden")
    }

    // Load Leaflet first
    await this.loadLeaflet()

    // Initialize map if not already done
    if (!this.map && this.hasMapContainerTarget) {
      const lat = area.latitude || 35.6812
      const lng = area.longitude || 139.7671

      this.map = L.map(this.mapContainerTarget, {
        scrollWheelZoom: false,
        dragging: true,
        doubleClickZoom: false
      }).setView([lat, lng], 13)

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 19
      }).addTo(this.map)
    }

    this.updateMapContent(area)
  }

  updateMapContent(area) {
    if (!this.map) return

    // Clear existing layers
    if (this.marker) {
      this.map.removeLayer(this.marker)
      this.marker = null
    }
    if (this.polygon) {
      this.map.removeLayer(this.polygon)
      this.polygon = null
    }

    // Add boundary polygon if available
    if (area.boundary_geojson) {
      try {
        const geojson = typeof area.boundary_geojson === "string"
          ? JSON.parse(area.boundary_geojson)
          : area.boundary_geojson

        this.polygon = L.geoJSON(geojson, {
          style: {
            color: "#3b82f6",
            weight: 2,
            fillColor: "#3b82f6",
            fillOpacity: 0.1
          }
        }).addTo(this.map)

        this.map.fitBounds(this.polygon.getBounds(), { padding: [20, 20] })
      } catch (e) {
        console.error("Invalid GeoJSON:", e)
      }
    }

    // Add marker at center
    if (area.latitude && area.longitude) {
      this.marker = L.marker([area.latitude, area.longitude], {
        icon: this.createIcon()
      }).addTo(this.map)

      if (!this.polygon) {
        this.map.setView([area.latitude, area.longitude], 14)
      }
    }
  }

  hideMap() {
    if (this.hasMapWrapperTarget) {
      this.mapWrapperTarget.classList.add("hidden")
    }
  }

  createIcon() {
    return L.divIcon({
      className: "custom-marker",
      html: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#3b82f6" width="32" height="32">
        <path fill-rule="evenodd" d="m11.54 22.351.07.04.028.016a.76.76 0 0 0 .723 0l.028-.015.071-.041a16.975 16.975 0 0 0 1.144-.742 19.58 19.58 0 0 0 2.683-2.282c1.944-1.99 3.963-4.98 3.963-8.827a8.25 8.25 0 0 0-16.5 0c0 3.846 2.02 6.837 3.963 8.827a19.58 19.58 0 0 0 2.682 2.282 16.975 16.975 0 0 0 1.145.742ZM12 13.5a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" clip-rule="evenodd" />
      </svg>`,
      iconSize: [32, 32],
      iconAnchor: [16, 32],
      popupAnchor: [0, -32]
    })
  }
}
