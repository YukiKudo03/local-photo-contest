import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "tooltip", "progress", "stepIndicator"]
  static values = {
    tutorialType: String,
    autoStart: { type: Boolean, default: false },
    reducedMotion: { type: Boolean, default: false }
  }

  // 桜井流制約
  static MAX_STEP_DURATION = 10000  // 10秒
  static ANIMATION_DURATION = 300    // 0.3秒

  connect() {
    this.steps = []
    this.currentStepIndex = 0
    this.stepStartTime = null
    this.isActive = false

    if (this.autoStartValue) {
      this.checkAndStart()
    }
  }

  disconnect() {
    this.cleanup()
  }

  async checkAndStart() {
    try {
      const response = await this.fetchWithCsrf('/tutorials/status')
      const data = await response.json()

      if (data.should_show_onboarding && data.onboarding_type === this.tutorialTypeValue) {
        this.start()
      }
    } catch (error) {
      console.error('Tutorial status check failed:', error)
    }
  }

  async start() {
    if (this.isActive) return

    try {
      await this.fetchWithCsrf(`/tutorials/${this.tutorialTypeValue}/start`, {
        method: 'POST'
      })
      await this.loadTutorial()
      this.isActive = true
    } catch (error) {
      console.error('Tutorial start failed:', error)
    }
  }

  async loadTutorial() {
    try {
      const response = await this.fetchWithCsrf(`/tutorials/${this.tutorialTypeValue}`)
      const data = await response.json()

      this.steps = data.steps || []

      if (data.progress && data.progress.current_step_id) {
        this.currentStepIndex = this.steps.findIndex(
          s => s.step_id === data.progress.current_step_id
        )
        if (this.currentStepIndex === -1) this.currentStepIndex = 0
      } else {
        this.currentStepIndex = 0
      }

      if (this.steps.length > 0) {
        this.showStep(this.currentStepIndex)
      }
    } catch (error) {
      console.error('Tutorial load failed:', error)
    }
  }

  showStep(index) {
    const step = this.steps[index]
    if (!step) {
      this.complete()
      return
    }

    this.currentStepIndex = index
    this.stepStartTime = Date.now()

    this.showOverlay()
    this.updateProgress(index)

    // ターゲット要素のハイライト
    if (step.target_selector) {
      const target = document.querySelector(step.target_selector)
      if (target) {
        this.highlightElement(target)
        this.showTooltip(target, step)
      } else {
        // ターゲットが見つからない場合は中央に表示
        this.showCenteredTooltip(step)
      }
    } else {
      // ターゲットセレクターがない場合は中央に表示
      this.showCenteredTooltip(step)
    }
  }

  highlightElement(element) {
    this.clearHighlight()
    element.classList.add('tutorial-highlight')
    element.scrollIntoView({ behavior: this.reducedMotionValue ? 'auto' : 'smooth', block: 'center' })
  }

  showTooltip(target, step) {
    if (!this.hasTooltipTarget) return

    const tooltip = this.tooltipTarget
    tooltip.innerHTML = this.buildMinimalTooltip(step)
    tooltip.classList.remove('hidden')
    tooltip.dataset.position = step.tooltip_position || 'bottom'

    this.positionTooltip(tooltip, target, step.tooltip_position || 'bottom')

    // アニメーション
    if (!this.reducedMotionValue) {
      tooltip.style.animation = `tooltip-appear ${this.constructor.ANIMATION_DURATION}ms ease-out`
    }
  }

  showCenteredTooltip(step) {
    if (!this.hasTooltipTarget) return

    const tooltip = this.tooltipTarget
    tooltip.innerHTML = this.buildMinimalTooltip(step)
    tooltip.classList.remove('hidden')
    tooltip.dataset.position = 'center'

    // 中央に配置
    tooltip.style.position = 'fixed'
    tooltip.style.top = '50%'
    tooltip.style.left = '50%'
    tooltip.style.transform = 'translate(-50%, -50%)'
  }

  buildMinimalTooltip(step) {
    // 桜井流：最小限のUI
    const hasVideo = step.video_url && step.video_url.trim() !== ''

    return `
      <div class="tutorial-minimal-tooltip">
        <p class="tutorial-title">${this.escapeHtml(step.title)}</p>
        ${step.description ? `<p class="tutorial-desc">${this.escapeHtml(step.description)}</p>` : ''}
        ${hasVideo ? `
          <div class="mb-3">
            <button data-controller="video-tutorial"
                    data-video-tutorial-url-value="${this.escapeHtml(step.video_url)}"
                    data-video-tutorial-title-value="${this.escapeHtml(step.video_title || step.title)}"
                    data-action="click->video-tutorial#open"
                    class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 bg-indigo-50 rounded-lg hover:bg-indigo-100 transition-colors">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
              </svg>
              動画で見る
            </button>
          </div>
        ` : ''}
        <div class="tutorial-actions">
          <button data-action="tutorial#skip" class="tutorial-skip">
            スキップ
          </button>
          <button data-action="tutorial#next" class="tutorial-next">
            ${step.is_last ? '完了' : '次へ'}
          </button>
        </div>
        <div class="tutorial-progress-dots">
          ${this.buildProgressDots()}
        </div>
      </div>
    `
  }

  buildProgressDots() {
    return this.steps.map((_, i) => {
      const state = i < this.currentStepIndex ? 'completed' :
                    i === this.currentStepIndex ? 'current' : 'pending'
      return `<span class="tutorial-dot tutorial-dot--${state}"></span>`
    }).join('')
  }

  positionTooltip(tooltip, target, position) {
    const targetRect = target.getBoundingClientRect()
    const tooltipRect = tooltip.getBoundingClientRect()
    const padding = 12

    tooltip.style.position = 'fixed'

    switch (position) {
      case 'top':
        tooltip.style.top = `${targetRect.top - tooltipRect.height - padding}px`
        tooltip.style.left = `${targetRect.left + (targetRect.width - tooltipRect.width) / 2}px`
        break
      case 'bottom':
        tooltip.style.top = `${targetRect.bottom + padding}px`
        tooltip.style.left = `${targetRect.left + (targetRect.width - tooltipRect.width) / 2}px`
        break
      case 'left':
        tooltip.style.top = `${targetRect.top + (targetRect.height - tooltipRect.height) / 2}px`
        tooltip.style.left = `${targetRect.left - tooltipRect.width - padding}px`
        break
      case 'right':
        tooltip.style.top = `${targetRect.top + (targetRect.height - tooltipRect.height) / 2}px`
        tooltip.style.left = `${targetRect.right + padding}px`
        break
      default:
        tooltip.style.top = `${targetRect.bottom + padding}px`
        tooltip.style.left = `${targetRect.left + (targetRect.width - tooltipRect.width) / 2}px`
    }

    // 画面内に収める
    this.constrainToViewport(tooltip)
  }

  constrainToViewport(tooltip) {
    const rect = tooltip.getBoundingClientRect()
    const padding = 16

    if (rect.left < padding) {
      tooltip.style.left = `${padding}px`
    }
    if (rect.right > window.innerWidth - padding) {
      tooltip.style.left = `${window.innerWidth - rect.width - padding}px`
    }
    if (rect.top < padding) {
      tooltip.style.top = `${padding}px`
    }
    if (rect.bottom > window.innerHeight - padding) {
      tooltip.style.top = `${window.innerHeight - rect.height - padding}px`
    }
  }

  async next() {
    clearTimeout(this.autoAdvanceTimer)

    const step = this.steps[this.currentStepIndex]
    if (!step) return

    const duration = Date.now() - this.stepStartTime

    try {
      const result = await this.completeStep(step.step_id, duration)

      // フィードバック表示
      if (result.feedback) {
        this.showFeedback(result.feedback)
      }

      // 次のステップへ
      this.clearHighlight()

      if (result.completed) {
        this.complete()
      } else {
        this.currentStepIndex++
        this.showStep(this.currentStepIndex)
      }
    } catch (error) {
      console.error('Tutorial advance failed:', error)
    }
  }

  async completeStep(stepId, durationMs) {
    const response = await this.fetchWithCsrf(`/tutorials/${this.tutorialTypeValue}`, {
      method: 'PATCH',
      body: JSON.stringify({ step_id: stepId, duration_ms: durationMs })
    })
    return response.json()
  }

  async skipStep(stepId) {
    const response = await this.fetchWithCsrf(`/tutorials/${this.tutorialTypeValue}/skip`, {
      method: 'POST',
      body: JSON.stringify({ step_id: stepId })
    })
    return response.json()
  }

  previous() {
    if (this.currentStepIndex > 0) {
      this.clearHighlight()
      this.currentStepIndex--
      this.showStep(this.currentStepIndex)
    }
  }

  async skip() {
    clearTimeout(this.autoAdvanceTimer)

    const step = this.steps[this.currentStepIndex]
    if (!step) return

    try {
      await this.skipStep(step.step_id)

      this.clearHighlight()

      if (this.currentStepIndex >= this.steps.length - 1) {
        this.cleanup()
      } else {
        this.currentStepIndex++
        this.showStep(this.currentStepIndex)
      }
    } catch (error) {
      console.error('Tutorial skip failed:', error)
    }
  }

  showFeedback(config) {
    // 即時フィードバック（0.2秒以内）
    const event = new CustomEvent('tutorial:feedback', {
      detail: {
        type: config.type,
        message: config.message,
        animation: config.animation
      }
    })
    document.dispatchEvent(event)
  }

  complete() {
    this.cleanup()
    this.showCompletionFeedback()
    this.dispatchEvent('completed')
  }

  showCompletionFeedback() {
    // 桜井流：シンプルで心地よい完了表現
    const toast = document.createElement('div')
    toast.className = 'tutorial-completion-toast'
    toast.innerHTML = `
      <svg class="completion-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      <span>準備完了！</span>
    `
    document.body.appendChild(toast)

    setTimeout(() => toast.remove(), 2000)
  }

  cleanup() {
    this.isActive = false
    clearTimeout(this.autoAdvanceTimer)
    this.hideOverlay()
    this.clearHighlight()
    if (this.hasTooltipTarget) {
      this.tooltipTarget.classList.add('hidden')
    }
  }

  showOverlay() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove('hidden')
    }
  }

  hideOverlay() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add('hidden')
    }
  }

  clearHighlight() {
    document.querySelectorAll('.tutorial-highlight').forEach(el => {
      el.classList.remove('tutorial-highlight')
    })
  }

  updateProgress(index) {
    if (this.hasProgressTarget) {
      const percentage = ((index + 1) / this.steps.length) * 100
      this.progressTarget.style.width = `${percentage}%`
    }
    if (this.hasStepIndicatorTarget) {
      this.stepIndicatorTarget.textContent = `${index + 1} / ${this.steps.length}`
    }
  }

  dispatchEvent(eventName) {
    this.element.dispatchEvent(new CustomEvent(`tutorial:${eventName}`, {
      bubbles: true,
      detail: { tutorialType: this.tutorialTypeValue }
    }))
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  async fetchWithCsrf(url, options = {}) {
    const csrfToken = document.querySelector('[name="csrf-token"]')?.content

    return fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        ...options.headers
      }
    })
  }
}
