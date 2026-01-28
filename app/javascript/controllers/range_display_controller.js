import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="range-display"
export default class extends Controller {
  static targets = ["slider", "value"]

  connect() {
    this.update()
  }

  update() {
    if (this.hasSliderTarget && this.hasValueTarget) {
      this.valueTarget.textContent = this.sliderTarget.value
    }
  }
}
