import { Controller } from "@hotwired/stimulus"

// Map gallery controller using Leaflet with OpenStreetMap
export default class extends Controller {
  static targets = ["mapContainer", "entriesList", "entryCount", "spotPanel"]
  static values = {
    dataUrl: String,
    contestId: String,
    areaId: String,
    discoveryStatus: String,
    initialLat: { type: Number, default: 35.6762 },
    initialLng: { type: Number, default: 139.6503 },
    initialZoom: { type: Number, default: 10 }
  }

  connect() {
    this.markers = []
    this.markerClusterGroup = null
    this.selectedSpot = null
    this.loadLeaflet().catch(error => {
      console.error('Failed to load Leaflet:', error)
    })
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  async loadLeaflet() {
    // Load Leaflet CSS
    if (!document.querySelector('link[href*="leaflet.css"]')) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
      document.head.appendChild(link)

      // Load MarkerCluster CSS
      const clusterLink = document.createElement('link')
      clusterLink.rel = 'stylesheet'
      clusterLink.href = 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css'
      document.head.appendChild(clusterLink)

      const clusterDefaultLink = document.createElement('link')
      clusterDefaultLink.rel = 'stylesheet'
      clusterDefaultLink.href = 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css'
      document.head.appendChild(clusterDefaultLink)
    }

    // Load Leaflet JS
    if (!window.L) {
      await this.loadScript('https://unpkg.com/leaflet@1.9.4/dist/leaflet.js')
      // Wait for L to be available
      await this.waitFor(() => window.L, 5000)
    }

    // Load MarkerCluster JS
    if (!window.L?.MarkerClusterGroup) {
      await this.loadScript('https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js')
      await this.waitFor(() => window.L?.MarkerClusterGroup, 5000)
    }

    this.initMap()
    this.loadMarkers()
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

  loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = src
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  initMap() {
    this.map = L.map(this.mapContainerTarget).setView(
      [this.initialLatValue, this.initialLngValue],
      this.initialZoomValue
    )

    // OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Initialize marker cluster group
    this.markerClusterGroup = L.markerClusterGroup({
      maxClusterRadius: 50,
      spiderfyOnMaxZoom: true,
      showCoverageOnHover: false,
      zoomToBoundsOnClick: true,
      iconCreateFunction: (cluster) => {
        const count = cluster.getChildCount()
        let size = 'small'
        if (count > 50) size = 'large'
        else if (count > 10) size = 'medium'

        return L.divIcon({
          html: `<div><span>${count}</span></div>`,
          className: `marker-cluster marker-cluster-${size}`,
          iconSize: L.point(40, 40)
        })
      }
    })

    this.map.addLayer(this.markerClusterGroup)
  }

  async loadMarkers() {
    try {
      let url = this.dataUrlValue
      const params = new URLSearchParams()

      if (this.contestIdValue) params.set('contest_id', this.contestIdValue)
      if (this.areaIdValue) params.set('area_id', this.areaIdValue)
      if (this.discoveryStatusValue) params.set('discovery_status', this.discoveryStatusValue)

      if (params.toString()) {
        url += '?' + params.toString()
      }

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) throw new Error('Failed to load markers')

      const entries = await response.json()
      this.displayMarkers(entries)
    } catch (error) {
      console.error('Error loading markers:', error)
    }
  }

  displayMarkers(entries) {
    // Clear existing markers
    this.markerClusterGroup.clearLayers()
    this.markers = []

    // Group entries by spot
    const spotGroups = {}
    entries.forEach(entry => {
      const key = `${entry.spot_id}`
      if (!spotGroups[key]) {
        spotGroups[key] = {
          lat: entry.lat,
          lng: entry.lng,
          spot_name: entry.spot_name,
          spot_id: entry.spot_id,
          discovery_status: entry.discovery_status,
          discovered_by_current_user: entry.discovered_by_current_user,
          entries: []
        }
      }
      spotGroups[key].entries.push(entry)
    })

    // Create markers for each spot
    Object.values(spotGroups).forEach(spot => {
      const marker = this.createSpotMarker(spot)
      this.markers.push(marker)
      this.markerClusterGroup.addLayer(marker)
    })

    // Update count
    if (this.hasEntryCountTarget) {
      this.entryCountTarget.textContent = entries.length
    }

    // Fit bounds if we have markers
    if (this.markers.length > 0) {
      const group = new L.featureGroup(this.markers)
      this.map.fitBounds(group.getBounds().pad(0.1))
    }
  }

  createSpotMarker(spot) {
    const count = spot.entries.length
    const firstEntry = spot.entries[0]

    // Determine discovery status class for marker coloring
    const discoveryClass = this.getDiscoveryStatusClass(spot)

    // Custom icon with photo thumbnail
    const icon = L.divIcon({
      className: 'custom-marker',
      html: `
        <div class="marker-pin ${discoveryClass}">
          ${firstEntry.photo_url
            ? `<img src="${firstEntry.photo_url}" alt="" class="marker-photo">`
            : '<div class="marker-placeholder"></div>'
          }
          ${count > 1 ? `<span class="marker-count">${count}</span>` : ''}
        </div>
      `,
      iconSize: [50, 60],
      iconAnchor: [25, 60],
      popupAnchor: [0, -60]
    })

    const marker = L.marker([spot.lat, spot.lng], { icon })

    // Create popup content
    const popupContent = this.createPopupContent(spot)
    marker.bindPopup(popupContent, { maxWidth: 300 })

    // Click handler to show spot panel
    marker.on('click', () => {
      this.showSpotPanel(spot)
    })

    return marker
  }

  createPopupContent(spot) {
    const entries = spot.entries
    const firstEntry = entries[0]

    let html = `
      <div class="map-popup">
        <h3 class="popup-title">${this.escapeHtml(spot.spot_name)}</h3>
        <p class="popup-count">${entries.length}作品</p>
    `

    if (firstEntry.photo_url) {
      html += `
        <a href="${firstEntry.entry_url}" class="popup-image-link">
          <img src="${firstEntry.photo_url}" alt="${this.escapeHtml(firstEntry.title)}" class="popup-image">
        </a>
      `
    }

    html += `
        <p class="popup-entry-title">${this.escapeHtml(firstEntry.title)}</p>
        <a href="${firstEntry.entry_url}" class="popup-link">作品を見る</a>
      </div>
    `

    return html
  }

  showSpotPanel(spot) {
    if (!this.hasSpotPanelTarget) return

    this.selectedSpot = spot
    const panel = this.spotPanelTarget

    let html = `
      <div class="spot-panel-header">
        <h3>${this.escapeHtml(spot.spot_name)}</h3>
        <button type="button" data-action="gallery-map#closeSpotPanel" class="close-btn">&times;</button>
      </div>
      <p class="spot-panel-count">${spot.entries.length}作品</p>
      <div class="spot-panel-entries">
    `

    spot.entries.forEach(entry => {
      html += `
        <a href="${entry.entry_url}" class="spot-entry">
          ${entry.photo_url
            ? `<img src="${entry.photo_url}" alt="${this.escapeHtml(entry.title)}" class="spot-entry-photo">`
            : '<div class="spot-entry-placeholder"></div>'
          }
          <div class="spot-entry-info">
            <p class="spot-entry-title">${this.escapeHtml(entry.title)}</p>
            <p class="spot-entry-meta">${this.escapeHtml(entry.contest_title)}</p>
            <p class="spot-entry-votes">${entry.votes_count} votes</p>
          </div>
        </a>
      `
    })

    html += '</div>'
    panel.innerHTML = html
    panel.classList.add('active')
  }

  closeSpotPanel() {
    if (this.hasSpotPanelTarget) {
      this.spotPanelTarget.classList.remove('active')
      this.selectedSpot = null
    }
  }

  filterByContest(event) {
    this.contestIdValue = event.target.value
    this.loadMarkers()
  }

  filterByArea(event) {
    this.areaIdValue = event.target.value
    this.loadMarkers()
  }

  filterByDiscoveryStatus(event) {
    this.discoveryStatusValue = event.target.value
    this.loadMarkers()
  }

  getDiscoveryStatusClass(spot) {
    // User's own discoveries get blue color
    if (spot.discovered_by_current_user) {
      return 'discovery-mine'
    }

    // Color based on discovery status
    switch (spot.discovery_status) {
      case 'certified':
        return 'discovery-certified'
      case 'discovered':
        return 'discovery-discovered'
      case 'organizer_created':
      default:
        return 'discovery-organizer'
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
