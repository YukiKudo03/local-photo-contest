import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // Default to hidden on mobile
    if (window.innerWidth < 768) {
      this.contentTarget.classList.add("hidden")
      this.updateIcon(false)
    }
  }

  toggle() {
    const isHidden = this.contentTarget.classList.toggle("hidden")
    this.updateIcon(!isHidden)
  }

  updateIcon(isOpen) {
    if (this.hasIconTarget) {
      // Rotate the chevron icon
      if (isOpen) {
        this.iconTarget.classList.add("rotate-180")
      } else {
        this.iconTarget.classList.remove("rotate-180")
      }
    }
  }
}
