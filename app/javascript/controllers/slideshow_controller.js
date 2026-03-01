import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "image", "title", "author", "counter", "playButton"]
  static values = {
    entries: Array,
    interval: { type: Number, default: 5000 },
    autoplay: { type: Boolean, default: false }
  }

  connect() {
    this.currentIndex = 0
    this.playing = false
    this.timer = null
    this.boundKeyHandler = this.handleKeydown.bind(this)
    this.previouslyFocused = null
  }

  disconnect() {
    this.stop()
    document.removeEventListener("keydown", this.boundKeyHandler)
  }

  open(event) {
    if (event) event.preventDefault()
    if (this.entriesValue.length === 0) return

    this.previouslyFocused = document.activeElement
    this.currentIndex = 0
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.boundKeyHandler)
    this.showSlide()

    if (this.autoplayValue) this.play()
  }

  close() {
    this.stop()
    this.containerTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this.boundKeyHandler)

    if (this.previouslyFocused) {
      this.previouslyFocused.focus()
      this.previouslyFocused = null
    }
  }

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.entriesValue.length
    this.showSlide()
  }

  prev() {
    this.currentIndex = (this.currentIndex - 1 + this.entriesValue.length) % this.entriesValue.length
    this.showSlide()
  }

  play() {
    if (this.playing) return
    this.playing = true
    this.timer = setInterval(() => this.next(), this.intervalValue)
    this.updatePlayButton()
  }

  stop() {
    if (!this.playing) return
    this.playing = false
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
    this.updatePlayButton()
  }

  togglePlay() {
    if (this.playing) {
      this.stop()
    } else {
      this.play()
    }
  }

  handleKeydown(event) {
    switch (event.key) {
      case "Escape":
        this.close()
        break
      case "ArrowLeft":
        this.prev()
        break
      case "ArrowRight":
        this.next()
        break
      case " ":
        event.preventDefault()
        this.togglePlay()
        break
    }
  }

  showSlide() {
    const entry = this.entriesValue[this.currentIndex]
    if (!entry) return

    if (this.hasImageTarget) {
      this.imageTarget.src = entry.imageUrl
      this.imageTarget.alt = entry.title
    }
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = entry.title
    }
    if (this.hasAuthorTarget) {
      this.authorTarget.textContent = entry.author
    }
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.entriesValue.length}`
    }
  }

  updatePlayButton() {
    if (this.hasPlayButtonTarget) {
      this.playButtonTarget.textContent = this.playing ? "⏸" : "▶"
    }
  }

  backdropClick(event) {
    if (event.target === this.containerTarget) {
      this.close()
    }
  }
}
