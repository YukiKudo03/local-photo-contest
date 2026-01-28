import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    type: { type: String, default: "line" },
    data: Object
  }

  connect() {
    this.loadChart()
  }

  async loadChart() {
    // Simple fallback chart rendering using canvas
    if (!this.hasCanvasTarget || !this.hasDataValue) return

    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    const data = this.dataValue

    // Get dimensions
    const width = canvas.parentElement.offsetWidth
    const height = canvas.parentElement.offsetHeight
    canvas.width = width
    canvas.height = height

    // Convert data object to arrays
    const labels = Object.keys(data).sort()
    const values = labels.map(label => data[label] || 0)

    if (values.length === 0) {
      this.renderEmptyState(ctx, width, height)
      return
    }

    this.renderLineChart(ctx, labels, values, width, height)
  }

  renderLineChart(ctx, labels, values, width, height) {
    const padding = { top: 20, right: 20, bottom: 40, left: 50 }
    const chartWidth = width - padding.left - padding.right
    const chartHeight = height - padding.top - padding.bottom

    const maxValue = Math.max(...values, 1)
    const xStep = chartWidth / (labels.length - 1 || 1)
    const yScale = chartHeight / maxValue

    // Clear canvas
    ctx.clearRect(0, 0, width, height)

    // Draw grid lines
    ctx.strokeStyle = "#e5e7eb"
    ctx.lineWidth = 1
    for (let i = 0; i <= 5; i++) {
      const y = padding.top + (chartHeight / 5) * i
      ctx.beginPath()
      ctx.moveTo(padding.left, y)
      ctx.lineTo(width - padding.right, y)
      ctx.stroke()
    }

    // Draw line
    ctx.strokeStyle = "#6366f1"
    ctx.lineWidth = 2
    ctx.beginPath()

    values.forEach((value, index) => {
      const x = padding.left + index * xStep
      const y = padding.top + chartHeight - value * yScale

      if (index === 0) {
        ctx.moveTo(x, y)
      } else {
        ctx.lineTo(x, y)
      }
    })
    ctx.stroke()

    // Draw area fill
    ctx.fillStyle = "rgba(99, 102, 241, 0.1)"
    ctx.beginPath()
    values.forEach((value, index) => {
      const x = padding.left + index * xStep
      const y = padding.top + chartHeight - value * yScale

      if (index === 0) {
        ctx.moveTo(x, y)
      } else {
        ctx.lineTo(x, y)
      }
    })
    ctx.lineTo(padding.left + (values.length - 1) * xStep, padding.top + chartHeight)
    ctx.lineTo(padding.left, padding.top + chartHeight)
    ctx.closePath()
    ctx.fill()

    // Draw points
    ctx.fillStyle = "#6366f1"
    values.forEach((value, index) => {
      const x = padding.left + index * xStep
      const y = padding.top + chartHeight - value * yScale

      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fill()
    })

    // Draw x-axis labels (show only first, middle, and last)
    ctx.fillStyle = "#6b7280"
    ctx.font = "11px sans-serif"
    ctx.textAlign = "center"

    const labelIndices = [0, Math.floor(labels.length / 2), labels.length - 1]
    labelIndices.forEach(index => {
      if (labels[index]) {
        const x = padding.left + index * xStep
        const label = labels[index].substring(5) // Remove year part
        ctx.fillText(label, x, height - 10)
      }
    })

    // Draw y-axis labels
    ctx.textAlign = "right"
    for (let i = 0; i <= 5; i++) {
      const value = Math.round(maxValue * (5 - i) / 5)
      const y = padding.top + (chartHeight / 5) * i
      ctx.fillText(value.toString(), padding.left - 10, y + 4)
    }
  }

  renderEmptyState(ctx, width, height) {
    ctx.fillStyle = "#9ca3af"
    ctx.font = "14px sans-serif"
    ctx.textAlign = "center"
    ctx.fillText("データがありません", width / 2, height / 2)
  }
}
