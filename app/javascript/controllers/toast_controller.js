import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    userId: Number
  }

  connect() {
    if (this.hasUserIdValue && this.userIdValue) {
      this.subscribeToNotifications()
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribeToNotifications() {
    this.subscription = consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        received: (data) => {
          this.showToast(data)
        }
      }
    )
  }

  showToast(data) {
    const toast = document.createElement("div")
    toast.className = `fixed bottom-4 right-4 max-w-sm bg-white rounded-lg shadow-lg border border-gray-200 p-4 transform transition-all duration-300 translate-y-full opacity-0 z-50`
    toast.innerHTML = `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          ${this.getIcon(data.type)}
        </div>
        <div class="ml-3 w-0 flex-1">
          <p class="text-sm font-medium text-gray-900">${this.escapeHtml(data.title)}</p>
          <p class="mt-1 text-sm text-gray-500">${this.escapeHtml(data.message)}</p>
          ${data.link ? `<a href="${data.link}" class="mt-2 inline-block text-sm text-indigo-600 hover:text-indigo-500">詳細を見る</a>` : ''}
        </div>
        <div class="ml-4 flex-shrink-0 flex">
          <button onclick="this.closest('.fixed').remove()" class="bg-white rounded-md inline-flex text-gray-400 hover:text-gray-500 focus:outline-none">
            <span class="sr-only">閉じる</span>
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </div>
    `

    document.body.appendChild(toast)

    // Animate in
    requestAnimationFrame(() => {
      toast.classList.remove("translate-y-full", "opacity-0")
    })

    // Auto-remove after 5 seconds
    setTimeout(() => {
      toast.classList.add("translate-y-full", "opacity-0")
      setTimeout(() => toast.remove(), 300)
    }, 5000)
  }

  getIcon(type) {
    const icons = {
      success: `<svg class="h-6 w-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      info: `<svg class="h-6 w-6 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      warning: `<svg class="h-6 w-6 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>`,
      error: `<svg class="h-6 w-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      entry: `<svg class="h-6 w-6 text-indigo-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
      </svg>`
    }
    return icons[type] || icons.info
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
