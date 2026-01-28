import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "latitudeInput", "longitudeInput", "display"]
  static values = {
    latitude: { type: Number, default: 35.6812 },  // Tokyo Station as default
    longitude: { type: Number, default: 139.7671 },
    zoom: { type: Number, default: 13 }
  }

  async connect() {
    this.map = null
    this.marker = null
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

    // Initialize map with interaction enabled
    this.map = L.map(this.containerTarget, {
      scrollWheelZoom: true,
      dragging: true,
      doubleClickZoom: false, // We use click for selection, not double-click zoom
      touchZoom: true
    }).setView([this.latitudeValue, this.longitudeValue], this.zoomValue)

    // Add OpenStreetMap tiles
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Add click handler for coordinate selection
    this.map.on("click", (e) => this.handleMapClick(e))

    // If there are existing coordinates in the inputs, show the marker
    if (this.hasLatitudeInputTarget && this.hasLongitudeInputTarget) {
      const lat = parseFloat(this.latitudeInputTarget.value)
      const lng = parseFloat(this.longitudeInputTarget.value)
      if (!isNaN(lat) && !isNaN(lng)) {
        this.setMarker(lat, lng)
        this.map.setView([lat, lng], this.zoomValue)
      }
    }

    // Handle resize
    this.resizeObserver = new ResizeObserver(() => {
      if (this.map) {
        this.map.invalidateSize()
      }
    })
    this.resizeObserver.observe(this.containerTarget)
  }

  handleMapClick(e) {
    const { lat, lng } = e.latlng
    this.setCoordinates(lat, lng)
  }

  setCoordinates(lat, lng) {
    // Round to 7 decimal places (about 1cm precision)
    const roundedLat = Math.round(lat * 10000000) / 10000000
    const roundedLng = Math.round(lng * 10000000) / 10000000

    // Update hidden inputs
    if (this.hasLatitudeInputTarget) {
      this.latitudeInputTarget.value = roundedLat
    }
    if (this.hasLongitudeInputTarget) {
      this.longitudeInputTarget.value = roundedLng
    }

    // Update display
    this.updateDisplay(roundedLat, roundedLng)

    // Update marker
    this.setMarker(roundedLat, roundedLng)
  }

  setMarker(lat, lng) {
    if (this.marker) {
      this.marker.setLatLng([lat, lng])
    } else {
      this.marker = L.marker([lat, lng], {
        icon: this.createIcon()
      }).addTo(this.map)
    }
  }

  updateDisplay(lat, lng) {
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = `緯度: ${lat}, 経度: ${lng}`
      this.displayTarget.classList.remove("text-gray-400")
      this.displayTarget.classList.add("text-gray-700")
    }
  }

  clear() {
    // Clear inputs
    if (this.hasLatitudeInputTarget) {
      this.latitudeInputTarget.value = ""
    }
    if (this.hasLongitudeInputTarget) {
      this.longitudeInputTarget.value = ""
    }

    // Clear display
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = "地図をクリックして座標を選択してください"
      this.displayTarget.classList.add("text-gray-400")
      this.displayTarget.classList.remove("text-gray-700")
    }

    // Remove marker
    if (this.marker) {
      this.map.removeLayer(this.marker)
      this.marker = null
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

  // Value change callbacks - if values change from outside, update the map
  latitudeValueChanged() {
    if (this.map && this.longitudeValue) {
      this.setMarker(this.latitudeValue, this.longitudeValue)
      this.updateDisplay(this.latitudeValue, this.longitudeValue)
    }
  }

  longitudeValueChanged() {
    if (this.map && this.latitudeValue) {
      this.setMarker(this.latitudeValue, this.longitudeValue)
      this.updateDisplay(this.latitudeValue, this.longitudeValue)
    }
  }
}
