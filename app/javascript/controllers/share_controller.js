import { Controller } from "@hotwired/stimulus"

// Share buttons controller
export default class extends Controller {
  // Track share click (for analytics if needed)
  trackShare(event) {
    const platform = event.params.platform
    console.log(`Share clicked: ${platform}`)

    // Open share popup for better UX
    event.preventDefault()
    const url = event.currentTarget.href
    const width = 600
    const height = 400
    const left = (window.innerWidth - width) / 2
    const top = (window.innerHeight - height) / 2

    window.open(
      url,
      'share',
      `width=${width},height=${height},left=${left},top=${top},toolbar=no,menubar=no,scrollbars=no,resizable=yes`
    )
  }

  // Copy link to clipboard
  async copyLink(event) {
    const url = event.params.url
    const button = event.currentTarget

    try {
      await navigator.clipboard.writeText(url)

      // Show success state
      button.classList.add('copied')
      const copyIcon = button.querySelector('.copy-icon')
      const checkIcon = button.querySelector('.check-icon')

      if (copyIcon && checkIcon) {
        copyIcon.classList.add('hidden')
        checkIcon.classList.remove('hidden')
      }

      // Reset after 2 seconds
      setTimeout(() => {
        button.classList.remove('copied')
        if (copyIcon && checkIcon) {
          copyIcon.classList.remove('hidden')
          checkIcon.classList.add('hidden')
        }
      }, 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
      // Fallback for older browsers
      this.fallbackCopy(url)
    }
  }

  fallbackCopy(text) {
    const textArea = document.createElement('textarea')
    textArea.value = text
    textArea.style.position = 'fixed'
    textArea.style.left = '-999999px'
    document.body.appendChild(textArea)
    textArea.select()

    try {
      document.execCommand('copy')
      alert('リンクをコピーしました')
    } catch (err) {
      alert('コピーに失敗しました')
    }

    document.body.removeChild(textArea)
  }
}
