import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  reload() {
    const frame = this.element.closest("turbo-frame") || this.element
    if (frame) {
      const url = this.urlValue || frame.src
      if (url) {
        frame.src = url
        if (typeof frame.reload === "function") {
          frame.reload()
        }
      }
    }
  }
}
