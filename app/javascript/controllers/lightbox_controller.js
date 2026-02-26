import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="lightbox"
export default class extends Controller {
  static targets = ["image"]

  connect() {
    this.boundKeyHandler = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeyHandler)
    this.previouslyFocused = null
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeyHandler)
  }

  open(event) {
    event.preventDefault()
    this.previouslyFocused = document.activeElement
    this.element.classList.remove("hidden")
    this.element.setAttribute("role", "dialog")
    this.element.setAttribute("aria-modal", "true")
    this.element.setAttribute("aria-label", "画像プレビュー")
    document.body.classList.add("overflow-hidden")

    // Focus the dialog element
    this.element.setAttribute("tabindex", "-1")
    this.element.focus()
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.element.classList.add("hidden")
    this.element.removeAttribute("role")
    this.element.removeAttribute("aria-modal")
    this.element.removeAttribute("aria-label")
    document.body.classList.remove("overflow-hidden")

    // Restore focus to the element that opened the lightbox
    if (this.previouslyFocused) {
      this.previouslyFocused.focus()
      this.previouslyFocused = null
    }
  }

  handleKeydown(event) {
    if (this.element.classList.contains("hidden")) return

    if (event.key === "Escape") {
      this.close()
      return
    }

    // Focus trap: keep Tab within the dialog
    if (event.key === "Tab") {
      const focusableElements = this.element.querySelectorAll(
        'a[href], button, [tabindex]:not([tabindex="-1"])'
      )
      const focusable = Array.from(focusableElements).filter(el => !el.closest('[hidden]'))

      if (focusable.length === 0) return

      const firstFocusable = focusable[0]
      const lastFocusable = focusable[focusable.length - 1]

      if (event.shiftKey) {
        if (document.activeElement === firstFocusable || document.activeElement === this.element) {
          event.preventDefault()
          lastFocusable.focus()
        }
      } else {
        if (document.activeElement === lastFocusable) {
          event.preventDefault()
          firstFocusable.focus()
        }
      }
    }
  }

  // Close when clicking on the backdrop (not the image)
  backdropClick(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
