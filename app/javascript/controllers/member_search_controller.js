import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "results", "actorId", "role", "addBtn"]

  connect() {
    this.selectedActor = null
  }

  search() {
    const q = this.queryTarget.value.trim()
    if (q.length < 2) {
      this.resultsTarget.classList.add("hidden")
      return
    }

    fetch(`/actors.json?q=${encodeURIComponent(q)}`)
      .then(r => r.json())
      .then(actors => {
        if (actors.length === 0) {
          this.resultsTarget.innerHTML = '<p class="px-3 py-2 text-sm text-gray-400">No results</p>'
        } else {
          this.resultsTarget.innerHTML = actors.map(a => `
            <button type="button"
                    data-action="click->member-search#select"
                    data-actor-id="${a.id}"
                    data-actor-name="${a.name}"
                    class="w-full text-left px-3 py-2 text-sm hover:bg-blue-50 flex items-center gap-2">
              <span class="w-6 h-6 bg-gray-200 rounded-full flex items-center justify-center text-xs font-bold text-gray-500">${a.name[0] || "?"}</span>
              <span>${a.name}</span>
              <span class="text-xs text-gray-400 ml-auto">${a.type}</span>
            </button>
          `).join("")
        }
        this.resultsTarget.classList.remove("hidden")
      })
  }

  select(event) {
    const btn = event.currentTarget
    this.selectedActor = { id: btn.dataset.actorId, name: btn.dataset.actorName }
    this.queryTarget.value = btn.dataset.actorName
    this.actorIdTarget.value = btn.dataset.actorId
    this.addBtnTarget.disabled = false
    this.resultsTarget.classList.add("hidden")
  }

  add() {
    if (!this.selectedActor) return

    const form = document.createElement("form")
    form.method = "POST"
    form.action = `/groups/${this.addBtnTarget.dataset.groupId}/memberships`

    const csrfToken = document.querySelector("[name='csrf-token']")?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    ;[
      ["actor_id", this.selectedActor.id],
      ["role", this.roleTarget.value]
    ].forEach(([name, value]) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = name
      input.value = value
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.submit()
  }

  hideResults(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.resultsTarget.classList.add("hidden")
    }
  }
}
