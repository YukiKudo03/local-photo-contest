import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["basic", "advanced", "toggle"]
  static values = {
    expanded: { type: Boolean, default: false },
    featureLevel: { type: String, default: 'beginner' }
  }

  connect() {
    this.updateVisibility()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.updateVisibility()
  }

  updateVisibility() {
    // 基本フィールドは常に表示
    this.basicTargets.forEach(el => el.classList.remove('hidden'))

    // 上級フィールドの表示制御
    if (this.expandedValue || this.featureLevelValue !== 'beginner') {
      this.advancedTargets.forEach(el => el.classList.remove('hidden'))
      this.updateToggleText('シンプル表示に戻す')
    } else {
      this.advancedTargets.forEach(el => el.classList.add('hidden'))
      this.updateToggleText('詳細設定を表示')
    }
  }

  updateToggleText(text) {
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = text
    }
  }

  // フィーチャーレベルを更新
  setFeatureLevel(level) {
    this.featureLevelValue = level
    this.updateVisibility()
  }

  // 展開状態を外部から設定
  expand() {
    this.expandedValue = true
    this.updateVisibility()
  }

  collapse() {
    this.expandedValue = false
    this.updateVisibility()
  }
}
