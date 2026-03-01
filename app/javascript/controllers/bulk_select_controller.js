import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "actions", "count", "form"]

  connect() {
    this.updateUI()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateUI()
  }

  toggle() {
    this.updateUI()
  }

  updateUI() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const count = checked.length

    if (this.hasActionsTarget) {
      this.actionsTarget.classList.toggle("hidden", count === 0)
    }
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
    }
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = count === this.checkboxTargets.length && count > 0
      this.selectAllTarget.indeterminate = count > 0 && count < this.checkboxTargets.length
    }
  }

  submitAction(event) {
    event.preventDefault()
    const action = event.currentTarget.dataset.bulkAction
    const ids = this.checkboxTargets.filter(cb => cb.checked).map(cb => cb.value)
    if (ids.length === 0) return

    const form = this.formTarget
    form.action = action

    // Clear existing hidden id fields
    form.querySelectorAll('input[name="entry_ids[]"], input[name="user_ids[]"]').forEach(el => el.remove())

    // Determine field name from action URL
    const fieldName = action.includes("users") ? "user_ids[]" : "entry_ids[]"

    ids.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = fieldName
      input.value = id
      form.appendChild(input)
    })

    form.submit()
  }
}
