import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (this.hasSubmitTarget && this.hasCheckboxTarget) {
      this.submitTarget.disabled = !this.checkboxTarget.checked
    }
  }
}
