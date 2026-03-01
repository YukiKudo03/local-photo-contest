import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["leftImage", "rightImage", "slider", "container", "leftTitle", "rightTitle", "leftPlaceholder", "rightPlaceholder"]
  static values = {
    mode: { type: String, default: "side-by-side" }
  }

  connect() {
    this.selectingSide = "left"
    this.dragging = false
    this.boundDrag = this.drag.bind(this)
    this.boundEndDrag = this.endDrag.bind(this)
  }

  selectEntry(event) {
    const entryData = JSON.parse(event.currentTarget.dataset.entryJson)

    if (this.selectingSide === "left") {
      this.setLeftEntry(entryData)
      this.selectingSide = "right"
    } else {
      this.setRightEntry(entryData)
      this.selectingSide = "left"
    }
  }

  setLeftEntry(entry) {
    if (this.hasLeftImageTarget) {
      this.leftImageTarget.src = entry.imageUrl
      this.leftImageTarget.alt = entry.title
      this.leftImageTarget.classList.remove("hidden")
    }
    if (this.hasLeftTitleTarget) {
      this.leftTitleTarget.textContent = entry.title
    }
    if (this.hasLeftPlaceholderTarget) {
      this.leftPlaceholderTarget.classList.add("hidden")
    }
  }

  setRightEntry(entry) {
    if (this.hasRightImageTarget) {
      this.rightImageTarget.src = entry.imageUrl
      this.rightImageTarget.alt = entry.title
      this.rightImageTarget.classList.remove("hidden")
    }
    if (this.hasRightTitleTarget) {
      this.rightTitleTarget.textContent = entry.title
    }
    if (this.hasRightPlaceholderTarget) {
      this.rightPlaceholderTarget.classList.add("hidden")
    }
  }

  setModeSideBySide() {
    this.modeValue = "side-by-side"
    if (this.hasSliderTarget) {
      this.sliderTarget.classList.add("hidden")
    }
    if (this.hasContainerTarget) {
      this.containerTarget.style.clipPath = ""
    }
  }

  setModeSlider() {
    this.modeValue = "slider"
    if (this.hasSliderTarget) {
      this.sliderTarget.classList.remove("hidden")
    }
  }

  startDrag(event) {
    event.preventDefault()
    this.dragging = true
    document.addEventListener("mousemove", this.boundDrag)
    document.addEventListener("mouseup", this.boundEndDrag)
    document.addEventListener("touchmove", this.boundDrag)
    document.addEventListener("touchend", this.boundEndDrag)
  }

  drag(event) {
    if (!this.dragging || !this.hasContainerTarget) return

    const rect = this.containerTarget.getBoundingClientRect()
    const clientX = event.touches ? event.touches[0].clientX : event.clientX
    const percentage = ((clientX - rect.left) / rect.width) * 100
    const clamped = Math.max(0, Math.min(100, percentage))

    this.updateSlider(clamped)
  }

  endDrag() {
    this.dragging = false
    document.removeEventListener("mousemove", this.boundDrag)
    document.removeEventListener("mouseup", this.boundEndDrag)
    document.removeEventListener("touchmove", this.boundDrag)
    document.removeEventListener("touchend", this.boundEndDrag)
  }

  updateSlider(percentage) {
    if (this.hasRightImageTarget) {
      this.rightImageTarget.style.clipPath = `inset(0 0 0 ${percentage}%)`
    }
    if (this.hasSliderTarget) {
      this.sliderTarget.style.left = `${percentage}%`
    }
  }
}
