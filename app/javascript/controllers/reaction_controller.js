import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", this.animate.bind(this))
  }

  animate() {
    this.element.classList.add("scale-110")
    setTimeout(() => {
      this.element.classList.remove("scale-110")
    }, 200)
  }
}
