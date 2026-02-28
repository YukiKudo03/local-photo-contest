import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "customPanel"]

  connect() {
    if (!this.hasConsent()) {
      this.show()
    }
  }

  acceptAll() {
    this.setConsent("all")
    this.hide()
  }

  acceptEssential() {
    this.setConsent("essential")
    this.hide()
  }

  showCustom() {
    if (this.hasCustomPanelTarget) {
      this.customPanelTarget.classList.remove("hidden")
    }
  }

  saveCustom() {
    const analytics = this.element.querySelector("[data-cookie-type='analytics']")
    const consent = analytics && analytics.checked ? "all" : "essential"
    this.setConsent(consent)
    this.hide()
  }

  // Private

  hasConsent() {
    return document.cookie.split(";").some(c => c.trim().startsWith("cookie_consent="))
  }

  setConsent(value) {
    const expires = new Date()
    expires.setFullYear(expires.getFullYear() + 1)
    document.cookie = `cookie_consent=${value}; path=/; expires=${expires.toUTCString()}; SameSite=Lax`
  }

  show() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden")
    }
  }

  hide() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("hidden")
    }
  }
}
