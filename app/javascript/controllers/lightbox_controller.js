import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="lightbox"
export default class extends Controller {
  static targets = ["image"]

  connect() {
    // Close on escape key
    this.boundKeyHandler = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeyHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeyHandler)
  }

  open(event) {
    event.preventDefault()
    this.element.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.element.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close()
    }
  }

  // Close when clicking on the backdrop (not the image)
  backdropClick(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
