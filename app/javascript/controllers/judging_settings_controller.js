import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["methodRadio", "hybridSettings", "weightSlider", "judgeWeight", "voteWeight"]

  connect() {
    this.updateHybridVisibility()
    this.updateWeightDisplay()
  }

  methodChanged() {
    this.updateHybridVisibility()
  }

  weightChanged() {
    this.updateWeightDisplay()
  }

  updateHybridVisibility() {
    const hybridRadio = this.methodRadioTargets.find(radio => radio.value === "hybrid")
    const isHybrid = hybridRadio && hybridRadio.checked

    if (this.hasHybridSettingsTarget) {
      this.hybridSettingsTarget.style.display = isHybrid ? "block" : "none"
    }
  }

  updateWeightDisplay() {
    if (!this.hasWeightSliderTarget) return

    const judgeWeight = parseInt(this.weightSliderTarget.value, 10)
    const voteWeight = 100 - judgeWeight

    if (this.hasJudgeWeightTarget) {
      this.judgeWeightTarget.textContent = judgeWeight
    }
    if (this.hasVoteWeightTarget) {
      this.voteWeightTarget.textContent = voteWeight
    }
  }
}
