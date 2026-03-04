import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", this.toggleState.bind(this))
  }

  toggleState() {
    this.element.disabled = true
    setTimeout(() => {
      this.element.disabled = false
    }, 500)
  }
}
