import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    action: String,
    successMessage: { type: String, default: '完了！' }
  }

  // 即時フィードバック（桜井流：0.2秒以内）
  static FEEDBACK_DELAY = 200

  connect() {
    this.boundHandleFeedback = this.handleFeedback.bind(this)
    document.addEventListener('tutorial:feedback', this.boundHandleFeedback)
  }

  disconnect() {
    document.removeEventListener('tutorial:feedback', this.boundHandleFeedback)
  }

  // アクション完了時のフィードバック
  success(event) {
    event?.preventDefault()

    // 視覚フィードバック
    this.showVisualFeedback('success')

    // サーバーに通知（非同期）
    this.notifyServer()
  }

  showVisualFeedback(type) {
    // ポップアニメーション
    this.element.classList.add('feedback-pop')

    // 成功インジケーター
    this.showIndicator(type)

    // クリーンアップ
    setTimeout(() => {
      this.element.classList.remove('feedback-pop')
    }, 300)
  }

  showIndicator(type) {
    const indicator = document.createElement('div')
    indicator.className = `feedback-indicator feedback-indicator--${type}`
    indicator.innerHTML = this.getIndicatorContent(type)

    this.element.appendChild(indicator)

    setTimeout(() => {
      indicator.classList.add('feedback-indicator--visible')
    }, 10)

    setTimeout(() => {
      indicator.classList.remove('feedback-indicator--visible')
      setTimeout(() => indicator.remove(), 150)
    }, 1500)
  }

  getIndicatorContent(type) {
    switch (type) {
      case 'success':
        return `
          <svg class="indicator-icon" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
          </svg>
          <span>${this.successMessageValue}</span>
        `
      case 'milestone':
        return `
          <svg class="indicator-icon" viewBox="0 0 20 20" fill="currentColor">
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
          </svg>
          <span>バッジ獲得！</span>
        `
      default:
        return ''
    }
  }

  handleFeedback(event) {
    const { type, message } = event.detail
    if (message) {
      this.successMessageValue = message
    }
    this.showVisualFeedback(type || 'success')
  }

  async notifyServer() {
    if (!this.actionValue) return

    try {
      const csrfToken = document.querySelector('[name="csrf-token"]')?.content

      await fetch('/feedback/action', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          action_type: this.actionValue
        })
      })
    } catch (error) {
      console.error('Feedback notification failed:', error)
    }
  }
}
