import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["count"]
  static values = {
    entryId: Number
  }

  connect() {
    if (this.hasEntryIdValue) {
      this.subscribeToEntry()
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribeToEntry() {
    this.subscription = consumer.subscriptions.create(
      { channel: "EntryChannel", entry_id: this.entryIdValue },
      {
        received: (data) => {
          if (data.type === "vote_update") {
            this.updateCount(data.vote_count)
          }
        }
      }
    )
  }

  updateCount(count) {
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
      // Add animation
      this.countTarget.classList.add("scale-110")
      setTimeout(() => {
        this.countTarget.classList.remove("scale-110")
      }, 200)
    }
  }
}
