import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "password", "passwordConfirmation", "emailError", "passwordError", "passwordConfirmationError", "passwordStrength"]

  connect() {
    this.validateOnInput()
  }

  validateOnInput() {
    if (this.hasEmailTarget) {
      this.emailTarget.addEventListener("input", () => this.validateEmail())
    }
    if (this.hasPasswordTarget) {
      this.passwordTarget.addEventListener("input", () => {
        this.validatePassword()
        if (this.hasPasswordConfirmationTarget) {
          this.validatePasswordConfirmation()
        }
      })
    }
    if (this.hasPasswordConfirmationTarget) {
      this.passwordConfirmationTarget.addEventListener("input", () => this.validatePasswordConfirmation())
    }
  }

  validateEmail() {
    const email = this.emailTarget.value
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

    if (email.length === 0) {
      this.setError(this.emailTarget, this.emailErrorTarget, "")
      return true
    }

    if (!emailRegex.test(email)) {
      this.setError(this.emailTarget, this.emailErrorTarget, "有効なメールアドレスを入力してください")
      return false
    }

    this.setSuccess(this.emailTarget, this.emailErrorTarget)
    return true
  }

  validatePassword() {
    const password = this.passwordTarget.value
    const minLength = 8

    if (password.length === 0) {
      this.setError(this.passwordTarget, this.passwordErrorTarget, "")
      this.updatePasswordStrength(0)
      return true
    }

    if (password.length < minLength) {
      this.setError(this.passwordTarget, this.passwordErrorTarget, `パスワードは${minLength}文字以上で入力してください`)
      this.updatePasswordStrength(password.length / minLength * 50)
      return false
    }

    // Calculate password strength
    let strength = 50
    if (/[A-Z]/.test(password)) strength += 15
    if (/[a-z]/.test(password)) strength += 10
    if (/[0-9]/.test(password)) strength += 15
    if (/[^A-Za-z0-9]/.test(password)) strength += 10

    this.setSuccess(this.passwordTarget, this.passwordErrorTarget)
    this.updatePasswordStrength(strength)
    return true
  }

  validatePasswordConfirmation() {
    if (!this.hasPasswordTarget || !this.hasPasswordConfirmationTarget) return true

    const password = this.passwordTarget.value
    const confirmation = this.passwordConfirmationTarget.value

    if (confirmation.length === 0) {
      this.setError(this.passwordConfirmationTarget, this.passwordConfirmationErrorTarget, "")
      return true
    }

    if (password !== confirmation) {
      this.setError(this.passwordConfirmationTarget, this.passwordConfirmationErrorTarget, "パスワードが一致しません")
      return false
    }

    this.setSuccess(this.passwordConfirmationTarget, this.passwordConfirmationErrorTarget)
    return true
  }

  updatePasswordStrength(strength) {
    if (!this.hasPasswordStrengthTarget) return

    this.passwordStrengthTarget.style.width = `${Math.min(strength, 100)}%`

    if (strength < 50) {
      this.passwordStrengthTarget.className = "h-1 bg-red-500 transition-all duration-300"
    } else if (strength < 75) {
      this.passwordStrengthTarget.className = "h-1 bg-yellow-500 transition-all duration-300"
    } else {
      this.passwordStrengthTarget.className = "h-1 bg-green-500 transition-all duration-300"
    }
  }

  setError(input, errorTarget, message) {
    if (errorTarget) {
      errorTarget.textContent = message
      errorTarget.classList.remove("hidden")
    }
    if (message) {
      input.classList.add("border-red-500")
      input.classList.remove("border-green-500", "border-gray-300")
    } else {
      input.classList.remove("border-red-500", "border-green-500")
      input.classList.add("border-gray-300")
    }
  }

  setSuccess(input, errorTarget) {
    if (errorTarget) {
      errorTarget.textContent = ""
      errorTarget.classList.add("hidden")
    }
    input.classList.remove("border-red-500", "border-gray-300")
    input.classList.add("border-green-500")
  }
}
