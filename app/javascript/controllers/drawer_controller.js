import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  connect() {
    // Prevent body from scrolling behind the drawer
    document.body.classList.add("overflow-hidden")

    // Animate transition in
    requestAnimationFrame(() => {
      if (this.hasOverlayTarget) {
        this.overlayTarget.classList.remove("opacity-0")
        this.overlayTarget.classList.add("opacity-100")
      }
      if (this.hasPanelTarget) {
        this.panelTarget.classList.remove("translate-x-full")
        this.panelTarget.classList.add("translate-x-0")
      }
    })
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden")
  }

  close() {
    // Animate transition out
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("opacity-100")
      this.overlayTarget.classList.add("opacity-0")
    }
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("translate-x-0")
      this.panelTarget.classList.add("translate-x-full")
    }

    // Wait for the transition to finish before removing the element from the DOM
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
