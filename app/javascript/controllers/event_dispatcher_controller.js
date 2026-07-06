import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String }

  connect() {
    const eventName = this.nameValue || "custom:event"
    window.dispatchEvent(new CustomEvent(eventName, { bubbles: true }))
    this.element.remove()
  }
}
