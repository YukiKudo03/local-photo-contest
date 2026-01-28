import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["listView", "mapView", "listButton", "mapButton"]

  connect() {
    // Default to list view
    this.currentView = "list"
  }

  showList() {
    this.currentView = "list"
    this.updateView()
  }

  showMap() {
    this.currentView = "map"
    this.updateView()
  }

  updateView() {
    if (this.hasListViewTarget) {
      this.listViewTarget.classList.toggle("hidden", this.currentView !== "list")
    }
    if (this.hasMapViewTarget) {
      this.mapViewTarget.classList.toggle("hidden", this.currentView !== "map")
    }

    // Update button styles
    if (this.hasListButtonTarget) {
      this.listButtonTarget.classList.toggle("bg-indigo-600", this.currentView === "list")
      this.listButtonTarget.classList.toggle("text-white", this.currentView === "list")
      this.listButtonTarget.classList.toggle("bg-white", this.currentView !== "list")
      this.listButtonTarget.classList.toggle("text-gray-700", this.currentView !== "list")
      this.listButtonTarget.classList.toggle("hover:bg-gray-50", this.currentView !== "list")
    }
    if (this.hasMapButtonTarget) {
      this.mapButtonTarget.classList.toggle("bg-indigo-600", this.currentView === "map")
      this.mapButtonTarget.classList.toggle("text-white", this.currentView === "map")
      this.mapButtonTarget.classList.toggle("bg-white", this.currentView !== "map")
      this.mapButtonTarget.classList.toggle("text-gray-700", this.currentView !== "map")
      this.mapButtonTarget.classList.toggle("hover:bg-gray-50", this.currentView !== "map")
    }

    // Dispatch event for map resize
    if (this.currentView === "map") {
      window.dispatchEvent(new Event("resize"))
    }
  }
}
