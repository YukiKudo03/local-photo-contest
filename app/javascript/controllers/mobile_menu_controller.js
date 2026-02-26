import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle() {
    const isOpen = !this.menuTarget.classList.contains("hidden")
    if (isOpen) {
      this.menuTarget.classList.add("hidden")
    } else {
      this.menuTarget.classList.remove("hidden")
    }
    this.buttonTarget.setAttribute("aria-expanded", !isOpen)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  connect() {
    this.boundKeyHandler = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeyHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeyHandler)
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.menuTarget.classList.contains("hidden")) {
      this.close()
      this.buttonTarget.focus()
    }
  }
}
