import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="template-selector"
export default class extends Controller {
  static targets = ["select"]

  select() {
    const templateId = this.selectTarget.value
    if (templateId) {
      window.location.href = `/organizers/contests/new?template_id=${templateId}`
    } else {
      window.location.href = "/organizers/contests/new"
    }
  }
}
