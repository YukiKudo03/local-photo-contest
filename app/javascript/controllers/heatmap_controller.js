import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, days: String }
  static targets = ["container"]

  connect() {
    this.fetchData()
  }

  async fetchData() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data = await response.json()
      this.render(data.heatmap)
    } catch (error) {
      this.containerTarget.innerHTML = `<p class="text-sm text-red-500">${error.message}</p>`
    }
  }

  render(heatmap) {
    const days = this.daysValue.split(",")
    const maxCount = Math.max(1, ...Object.values(heatmap).flatMap(h => Object.values(h)))

    let html = '<div class="overflow-x-auto"><table class="w-full text-xs">'
    html += "<thead><tr><th></th>"
    for (let h = 0; h < 24; h++) {
      html += `<th class="px-1 py-1 text-center text-gray-500">${h}</th>`
    }
    html += "</tr></thead><tbody>"

    for (let d = 0; d < 7; d++) {
      html += `<tr><td class="pr-2 py-1 text-right text-gray-600 font-medium whitespace-nowrap">${days[d]}</td>`
      for (let h = 0; h < 24; h++) {
        const count = (heatmap[d] && heatmap[d][h]) || 0
        const intensity = count / maxCount
        const bgClass = this.intensityClass(intensity)
        const title = `${days[d]} ${h}:00 - ${count}`
        html += `<td class="px-1 py-1"><div class="${bgClass} rounded-sm w-full aspect-square flex items-center justify-center" title="${title}">${count > 0 ? count : ""}</div></td>`
      }
      html += "</tr>"
    }

    html += "</tbody></table></div>"
    this.containerTarget.innerHTML = html
  }

  intensityClass(intensity) {
    if (intensity === 0) return "bg-gray-100"
    if (intensity < 0.2) return "bg-blue-100"
    if (intensity < 0.4) return "bg-blue-200"
    if (intensity < 0.6) return "bg-blue-400 text-white"
    if (intensity < 0.8) return "bg-blue-600 text-white"
    return "bg-blue-800 text-white"
  }
}
