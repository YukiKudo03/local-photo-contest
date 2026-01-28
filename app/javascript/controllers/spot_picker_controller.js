import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "select", "mapContainer", "mapWrapper",
    "discoverCheckbox", "existingSpotSection", "newSpotSection",
    "newSpotName", "newSpotLatitude", "newSpotLongitude",
    "mapLabel", "mapHelp"
  ]
  static values = {
    spots: { type: Array, default: [] },
    areaLatitude: Number,
    areaLongitude: Number,
    areaBoundary: String
  }

  async connect() {
    this.map = null
    this.markers = {}
    this.selectedMarker = null
    this.polygon = null
    this.discoveryMarker = null
    this.discoverMode = false
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
    if (!this.hasMapContainerTarget) return

    // Determine center point
    const firstSpot = this.spotsValue.find(s => s.latitude && s.longitude)
    const centerLat = this.areaLatitudeValue || firstSpot?.latitude || 35.6812
    const centerLng = this.areaLongitudeValue || firstSpot?.longitude || 139.7671

    this.map = L.map(this.mapContainerTarget, {
      scrollWheelZoom: true,
      dragging: true,
      doubleClickZoom: false
    }).setView([centerLat, centerLng], 14)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Add area boundary if available
    if (this.areaBoundaryValue) {
      this.addAreaBoundary()
    }

    // Add spot markers
    this.addSpotMarkers()

    // Fit bounds to show all spots
    this.fitBoundsToSpots()

    // Sync with initial select value
    if (this.hasSelectTarget && this.selectTarget.value) {
      this.highlightMarker(parseInt(this.selectTarget.value))
    }

    // Enable click to add marker in discovery mode
    this.map.on("click", (e) => this.handleMapClick(e))
  }

  toggleDiscoverMode() {
    this.discoverMode = this.hasDiscoverCheckboxTarget && this.discoverCheckboxTarget.checked

    if (this.hasExistingSpotSectionTarget) {
      this.existingSpotSectionTarget.classList.toggle("hidden", this.discoverMode)
    }
    if (this.hasNewSpotSectionTarget) {
      this.newSpotSectionTarget.classList.toggle("hidden", !this.discoverMode)
    }

    // Update map label and help text
    if (this.hasMapLabelTarget) {
      this.mapLabelTarget.textContent = this.discoverMode ? "発掘スポットの位置" : "スポット位置"
    }
    if (this.hasMapHelpTarget) {
      this.mapHelpTarget.textContent = this.discoverMode
        ? "地図をクリックして発掘スポットの位置を指定してください"
        : "マーカーをクリックしてスポットを選択できます"
    }

    // Clear discovery marker when switching modes
    if (!this.discoverMode && this.discoveryMarker) {
      this.map.removeLayer(this.discoveryMarker)
      this.discoveryMarker = null
      if (this.hasNewSpotLatitudeTarget) this.newSpotLatitudeTarget.value = ""
      if (this.hasNewSpotLongitudeTarget) this.newSpotLongitudeTarget.value = ""
    }

    // Clear spot selection when entering discovery mode
    if (this.discoverMode && this.hasSelectTarget) {
      this.selectTarget.value = ""
      this.highlightMarker(null)
    }
  }

  handleMapClick(e) {
    if (!this.discoverMode) return

    const { lat, lng } = e.latlng

    // Remove existing discovery marker
    if (this.discoveryMarker) {
      this.map.removeLayer(this.discoveryMarker)
    }

    // Add new discovery marker
    this.discoveryMarker = L.marker([lat, lng], {
      icon: this.createDiscoveryIcon(),
      draggable: true
    }).addTo(this.map)

    this.discoveryMarker.bindPopup("発掘スポット").openPopup()

    // Update hidden fields
    this.updateDiscoveryCoordinates(lat, lng)

    // Handle marker drag
    this.discoveryMarker.on("dragend", () => {
      const pos = this.discoveryMarker.getLatLng()
      this.updateDiscoveryCoordinates(pos.lat, pos.lng)
    })
  }

  updateDiscoveryCoordinates(lat, lng) {
    if (this.hasNewSpotLatitudeTarget) {
      this.newSpotLatitudeTarget.value = lat.toFixed(6)
    }
    if (this.hasNewSpotLongitudeTarget) {
      this.newSpotLongitudeTarget.value = lng.toFixed(6)
    }
  }

  createDiscoveryIcon() {
    const color = "#f59e0b" // amber for discovery
    const size = 40

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

  addAreaBoundary() {
    if (!this.areaBoundaryValue) return

    try {
      const geojson = JSON.parse(this.areaBoundaryValue)
      this.polygon = L.geoJSON(geojson, {
        style: {
          color: "#6366f1",
          weight: 2,
          fillColor: "#6366f1",
          fillOpacity: 0.05
        }
      }).addTo(this.map)
    } catch (e) {
      console.error("Invalid GeoJSON:", e)
    }
  }

  addSpotMarkers() {
    this.spotsValue.forEach(spot => {
      if (!spot.latitude || !spot.longitude) return

      const marker = L.marker([spot.latitude, spot.longitude], {
        icon: this.createIcon(false)
      }).addTo(this.map)

      marker.bindPopup(`
        <div class="text-sm">
          <strong>${spot.name}</strong>
          ${spot.category_name ? `<br><span class="text-gray-500">${spot.category_name}</span>` : ''}
        </div>
      `)

      marker.on("click", () => this.selectSpot(spot.id))

      this.markers[spot.id] = marker
    })
  }

  fitBoundsToSpots() {
    const spotsWithCoords = this.spotsValue.filter(s => s.latitude && s.longitude)
    if (spotsWithCoords.length === 0) return

    if (spotsWithCoords.length === 1) {
      this.map.setView([spotsWithCoords[0].latitude, spotsWithCoords[0].longitude], 15)
    } else {
      const bounds = L.latLngBounds(
        spotsWithCoords.map(s => [s.latitude, s.longitude])
      )
      this.map.fitBounds(bounds, { padding: [30, 30] })
    }
  }

  selectSpot(spotId) {
    // Update select dropdown
    if (this.hasSelectTarget) {
      this.selectTarget.value = spotId
      // Trigger change event for form validation
      this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    // Highlight the selected marker
    this.highlightMarker(spotId)
  }

  selectChanged() {
    const selectedId = this.hasSelectTarget ? parseInt(this.selectTarget.value) : null
    this.highlightMarker(selectedId)
  }

  highlightMarker(spotId) {
    // Reset previous selection
    if (this.selectedMarker) {
      this.selectedMarker.setIcon(this.createIcon(false))
    }

    // Highlight new selection
    if (spotId && this.markers[spotId]) {
      this.markers[spotId].setIcon(this.createIcon(true))
      this.selectedMarker = this.markers[spotId]

      // Center map on selected spot
      const spot = this.spotsValue.find(s => s.id === spotId)
      if (spot && spot.latitude && spot.longitude) {
        this.map.panTo([spot.latitude, spot.longitude])
      }
    } else {
      this.selectedMarker = null
    }
  }

  createIcon(selected) {
    const color = selected ? "#059669" : "#3b82f6"  // green for selected, blue for default
    const size = selected ? 40 : 32

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
}
