import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["state", "city"]

  countryChanged(event) {
    fetch(`/locations/states?country=${event.target.value}`)
      .then((r) => r.text())
      .then((html) => {
        this.stateTarget.innerHTML = html
        this.reloadCities()
      })
  }

  stateChanged() {
    this.reloadCities()
  }

  reloadCities() {
    const country =
      this.element.querySelector("[data-location-target='country']")?.value
    const state = this.stateTarget.value
    if (state) {
      fetch(`/locations/cities?state=${state}&country=${country || "BR"}`)
        .then((r) => r.text())
        .then((html) => {
          this.cityTarget.innerHTML = html
        })
    }
  }
}
