import { Controller } from "@hotwired/stimulus"

/**
 * Context Help Controller
 *
 * Provides hover-based tooltip help for UI elements.
 *
 * Usage:
 * <div data-controller="context-help"
 *      data-context-help-title-value="タイトル"
 *      data-context-help-content-value="説明文"
 *      data-context-help-position-value="top">
 *   要素
 * </div>
 *
 * Or use the help icon trigger:
 * <div data-controller="context-help"
 *      data-context-help-title-value="タイトル"
 *      data-context-help-content-value="説明文">
 *   <span data-context-help-target="trigger">?</span>
 * </div>
 */
export default class extends Controller {
  static targets = ["trigger"]
  static values = {
    title: String,
    content: String,
    position: { type: String, default: "top" },
    delay: { type: Number, default: 300 },
    persistent: { type: Boolean, default: false }
  }

  connect() {
    this.tooltip = null
    this.showTimeout = null
    this.hideTimeout = null

    // Check user preference for context help
    this.enabled = this.checkEnabled()

    if (!this.enabled) return

    this.bindEvents()
  }

  disconnect() {
    this.hideTooltip()
    this.unbindEvents()
  }

  checkEnabled() {
    // Check tutorial settings from meta tag or default to true
    const settingsMeta = document.querySelector('meta[name="tutorial-settings"]')
    if (settingsMeta) {
      try {
        const settings = JSON.parse(settingsMeta.content)
        return settings.show_context_help !== false
      } catch (e) {
        return true
      }
    }
    return true
  }

  bindEvents() {
    const target = this.hasTriggerTarget ? this.triggerTarget : this.element

    target.addEventListener('mouseenter', this.handleMouseEnter.bind(this))
    target.addEventListener('mouseleave', this.handleMouseLeave.bind(this))
    target.addEventListener('focus', this.handleFocus.bind(this))
    target.addEventListener('blur', this.handleBlur.bind(this))

    // For touch devices
    target.addEventListener('touchstart', this.handleTouch.bind(this))
  }

  unbindEvents() {
    const target = this.hasTriggerTarget ? this.triggerTarget : this.element

    target.removeEventListener('mouseenter', this.handleMouseEnter.bind(this))
    target.removeEventListener('mouseleave', this.handleMouseLeave.bind(this))
    target.removeEventListener('focus', this.handleFocus.bind(this))
    target.removeEventListener('blur', this.handleBlur.bind(this))
    target.removeEventListener('touchstart', this.handleTouch.bind(this))
  }

  handleMouseEnter() {
    this.clearTimeouts()
    this.showTimeout = setTimeout(() => {
      this.showTooltip()
    }, this.delayValue)
  }

  handleMouseLeave() {
    this.clearTimeouts()
    if (!this.persistentValue) {
      this.hideTimeout = setTimeout(() => {
        this.hideTooltip()
      }, 100)
    }
  }

  handleFocus() {
    this.showTooltip()
  }

  handleBlur() {
    if (!this.persistentValue) {
      this.hideTooltip()
    }
  }

  handleTouch(event) {
    if (this.tooltip) {
      this.hideTooltip()
    } else {
      event.preventDefault()
      this.showTooltip()
    }
  }

  clearTimeouts() {
    if (this.showTimeout) {
      clearTimeout(this.showTimeout)
      this.showTimeout = null
    }
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
      this.hideTimeout = null
    }
  }

  showTooltip() {
    if (this.tooltip) return

    this.tooltip = document.createElement('div')
    this.tooltip.className = 'context-help-tooltip'
    this.tooltip.setAttribute('role', 'tooltip')
    this.tooltip.innerHTML = this.buildContent()

    document.body.appendChild(this.tooltip)

    // Position the tooltip
    this.positionTooltip()

    // Add close button event
    const closeBtn = this.tooltip.querySelector('[data-action="close"]')
    if (closeBtn) {
      closeBtn.addEventListener('click', () => this.hideTooltip())
    }

    // Keep tooltip visible on hover
    this.tooltip.addEventListener('mouseenter', () => {
      this.clearTimeouts()
    })
    this.tooltip.addEventListener('mouseleave', () => {
      if (!this.persistentValue) {
        this.hideTooltip()
      }
    })

    // Animate in
    requestAnimationFrame(() => {
      this.tooltip.classList.add('visible')
    })
  }

  hideTooltip() {
    if (!this.tooltip) return

    this.tooltip.classList.remove('visible')

    setTimeout(() => {
      if (this.tooltip) {
        this.tooltip.remove()
        this.tooltip = null
      }
    }, 150)
  }

  buildContent() {
    const hasTitle = this.titleValue && this.titleValue.trim()
    const hasContent = this.contentValue && this.contentValue.trim()

    return `
      <div class="context-help-content">
        ${hasTitle ? `<div class="context-help-title">${this.escapeHtml(this.titleValue)}</div>` : ''}
        ${hasContent ? `<div class="context-help-text">${this.escapeHtml(this.contentValue)}</div>` : ''}
        ${this.persistentValue ? `
          <button type="button" data-action="close" class="context-help-close" aria-label="閉じる">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        ` : ''}
      </div>
      <div class="context-help-arrow" data-position="${this.positionValue}"></div>
    `
  }

  positionTooltip() {
    const target = this.hasTriggerTarget ? this.triggerTarget : this.element
    const targetRect = target.getBoundingClientRect()
    const tooltipRect = this.tooltip.getBoundingClientRect()
    const padding = 8

    let top, left

    switch (this.positionValue) {
      case 'top':
        top = targetRect.top - tooltipRect.height - padding
        left = targetRect.left + (targetRect.width - tooltipRect.width) / 2
        break
      case 'bottom':
        top = targetRect.bottom + padding
        left = targetRect.left + (targetRect.width - tooltipRect.width) / 2
        break
      case 'left':
        top = targetRect.top + (targetRect.height - tooltipRect.height) / 2
        left = targetRect.left - tooltipRect.width - padding
        break
      case 'right':
        top = targetRect.top + (targetRect.height - tooltipRect.height) / 2
        left = targetRect.right + padding
        break
      default:
        top = targetRect.top - tooltipRect.height - padding
        left = targetRect.left + (targetRect.width - tooltipRect.width) / 2
    }

    // Constrain to viewport
    const viewportPadding = 12

    if (left < viewportPadding) {
      left = viewportPadding
    } else if (left + tooltipRect.width > window.innerWidth - viewportPadding) {
      left = window.innerWidth - tooltipRect.width - viewportPadding
    }

    if (top < viewportPadding) {
      // Flip to bottom if not enough space on top
      if (this.positionValue === 'top') {
        top = targetRect.bottom + padding
        this.tooltip.querySelector('.context-help-arrow').dataset.position = 'bottom'
      } else {
        top = viewportPadding
      }
    } else if (top + tooltipRect.height > window.innerHeight - viewportPadding) {
      // Flip to top if not enough space on bottom
      if (this.positionValue === 'bottom') {
        top = targetRect.top - tooltipRect.height - padding
        this.tooltip.querySelector('.context-help-arrow').dataset.position = 'top'
      } else {
        top = window.innerHeight - tooltipRect.height - viewportPadding
      }
    }

    this.tooltip.style.top = `${top}px`
    this.tooltip.style.left = `${left}px`
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
