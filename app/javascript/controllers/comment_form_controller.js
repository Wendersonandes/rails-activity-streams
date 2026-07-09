import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  reset() {
    if (this.hasTextareaTarget) {
      this.textareaTarget.value = ""
      this.textareaTarget.style.height = "auto"
    }
  }

  cancel(event) {
    event.preventDefault()
    const frame = this.element.closest("turbo-frame")
    if (frame) {
      if (frame.id.includes("reply_form")) {
        frame.innerHTML = ""
      } else {
        frame.remove()
      }
    }
  }
}
