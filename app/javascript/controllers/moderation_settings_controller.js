import { Controller } from "@hotwired/stimulus"

// Handles the moderation settings form UI interactions
// Shows/hides threshold settings based on enabled checkbox state
export default class extends Controller {
  static targets = ["enableCheckbox", "thresholdSection", "thresholdSlider", "thresholdValue"]

  connect() {
    this.toggleSettings()
  }

  toggleSettings() {
    if (this.hasThresholdSectionTarget) {
      if (this.enableCheckboxTarget.checked) {
        this.thresholdSectionTarget.classList.remove("hidden")
      } else {
        this.thresholdSectionTarget.classList.add("hidden")
      }
    }
  }

  updateThresholdDisplay() {
    if (this.hasThresholdValueTarget && this.hasThresholdSliderTarget) {
      this.thresholdValueTarget.textContent = `${this.thresholdSliderTarget.value}%`
    }
  }
}
