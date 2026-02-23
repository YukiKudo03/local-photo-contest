import { Controller } from "@hotwired/stimulus"

/**
 * Video Tutorial Controller
 *
 * Handles embedded video tutorials with modal display.
 *
 * Usage:
 * <button data-controller="video-tutorial"
 *         data-video-tutorial-url-value="https://youtube.com/embed/xxx"
 *         data-video-tutorial-title-value="チュートリアル動画">
 *   動画を見る
 * </button>
 */
export default class extends Controller {
  static values = {
    url: String,
    title: { type: String, default: "チュートリアル動画" },
    provider: { type: String, default: "youtube" }
  }

  connect() {
    this.modal = null
  }

  disconnect() {
    this.close()
  }

  open(event) {
    event.preventDefault()
    this.createModal()
    this.showModal()
  }

  close() {
    if (this.modal) {
      this.modal.classList.add('opacity-0')
      setTimeout(() => {
        if (this.modal) {
          this.modal.remove()
          this.modal = null
        }
        document.body.style.overflow = ''
      }, 200)
    }
  }

  createModal() {
    if (this.modal) return

    const embedUrl = this.getEmbedUrl()

    this.modal = document.createElement('div')
    this.modal.className = 'video-tutorial-modal fixed inset-0 z-50 flex items-center justify-center p-4 opacity-0 transition-opacity duration-200'
    this.modal.innerHTML = `
      <div class="absolute inset-0 bg-black/80" data-action="click->video-tutorial#close"></div>
      <div class="relative bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden">
        <div class="flex items-center justify-between px-4 py-3 border-b border-gray-200 bg-gray-50">
          <h3 class="text-lg font-semibold text-gray-900">${this.escapeHtml(this.titleValue)}</h3>
          <button type="button"
                  class="text-gray-400 hover:text-gray-600 transition-colors"
                  data-action="click->video-tutorial#close"
                  aria-label="閉じる">
            <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div class="relative aspect-video bg-black">
          <iframe
            src="${embedUrl}"
            class="absolute inset-0 w-full h-full"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowfullscreen>
          </iframe>
        </div>
        <div class="px-4 py-3 bg-gray-50 border-t border-gray-200 text-sm text-gray-500">
          <p>動画を全画面で見るには、動画プレーヤーの全画面ボタンをクリックしてください。</p>
        </div>
      </div>
    `

    document.body.appendChild(this.modal)

    // Attach event listeners to modal buttons
    this.modal.querySelectorAll('[data-action]').forEach(el => {
      const action = el.dataset.action
      if (action.includes('close')) {
        el.addEventListener('click', () => this.close())
      }
    })

    // ESC key to close
    this.escHandler = (e) => {
      if (e.key === 'Escape') this.close()
    }
    document.addEventListener('keydown', this.escHandler)
  }

  showModal() {
    document.body.style.overflow = 'hidden'
    requestAnimationFrame(() => {
      this.modal.classList.remove('opacity-0')
    })
  }

  getEmbedUrl() {
    const url = this.urlValue

    // YouTube
    if (this.providerValue === 'youtube' || url.includes('youtube.com') || url.includes('youtu.be')) {
      return this.getYouTubeEmbedUrl(url)
    }

    // Vimeo
    if (this.providerValue === 'vimeo' || url.includes('vimeo.com')) {
      return this.getVimeoEmbedUrl(url)
    }

    // Direct embed URL
    return url
  }

  getYouTubeEmbedUrl(url) {
    let videoId = ''

    // Already embed URL
    if (url.includes('/embed/')) {
      return url
    }

    // Standard watch URL
    const watchMatch = url.match(/[?&]v=([^&]+)/)
    if (watchMatch) {
      videoId = watchMatch[1]
    }

    // Short URL
    const shortMatch = url.match(/youtu\.be\/([^?]+)/)
    if (shortMatch) {
      videoId = shortMatch[1]
    }

    if (videoId) {
      return `https://www.youtube.com/embed/${videoId}?rel=0&modestbranding=1`
    }

    return url
  }

  getVimeoEmbedUrl(url) {
    // Already embed URL
    if (url.includes('player.vimeo.com')) {
      return url
    }

    const match = url.match(/vimeo\.com\/(\d+)/)
    if (match) {
      return `https://player.vimeo.com/video/${match[1]}`
    }

    return url
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
