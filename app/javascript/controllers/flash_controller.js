import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Auto-dismiss after 5 seconds
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    this.element.style.transition = "transform 0.3s ease-in, opacity 0.3s ease-in"
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
