import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="infinite-scroll"
// Uses Intersection Observer to trigger lazy loading of Turbo Frames
export default class extends Controller {
  static values = {
    rootMargin: { type: String, default: "100px" }
  }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      {
        rootMargin: this.rootMarginValue
      }
    )

    // Observe the element itself (which contains the turbo-frame)
    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // The turbo-frame will load automatically due to loading="lazy"
        // But we can add visual feedback here if needed
        this.element.classList.add("loading")

        // Once loaded, stop observing
        this.observer.unobserve(this.element)
      }
    })
  }
}
