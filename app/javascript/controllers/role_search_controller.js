import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "results", "actorSlug", "actorName", "currentRole", "currentRoleLabel", "newRole", "detail", "saveBtn"]

  connect() {
    this.selectedActor = null
  }

  search() {
    const q = this.queryTarget.value.trim()
    if (q.length < 2) {
      this.resultsTarget.classList.add("hidden")
      this.detailTarget.classList.add("hidden")
      return
    }

    fetch(`/actors.json?q=${encodeURIComponent(q)}&include_site_roles=true`)
      .then(r => r.json())
      .then(actors => {
        if (actors.length === 0) {
          this.resultsTarget.innerHTML = '<p class="px-3 py-2 text-sm text-gray-400">No results</p>'
        } else {
          this.resultsTarget.innerHTML = actors.map(a => {
            const roleLabel = a.role === "none" ? "No role" : a.role.charAt(0).toUpperCase() + a.role.slice(1)
            return `
              <button type="button"
                      data-action="click->role-search#select"
                      data-slug="${a.slug}"
                      data-name="${a.name}"
                      data-role="${a.role}"
                      class="w-full text-left px-3 py-2 text-sm hover:bg-blue-50 flex items-center gap-2">
                <span class="w-6 h-6 bg-gray-200 rounded-full flex items-center justify-center text-xs font-bold text-gray-500">${a.name[0] || "?"}</span>
                <span>${a.name}</span>
                <span class="text-xs text-gray-400 ml-auto">${roleLabel}</span>
              </button>
            `
          }).join("")
        }
        this.resultsTarget.classList.remove("hidden")
      })
  }

  select(event) {
    const btn = event.currentTarget
    this.selectedActor = btn.dataset.slug
    this.queryTarget.value = btn.dataset.name
    this.actorNameTarget.textContent = btn.dataset.name
    this.actorSlugTarget.value = btn.dataset.slug
    this.currentRoleTarget.value = btn.dataset.role

    const roleLabel = btn.dataset.role === "none" ? "None (not assigned)" : btn.dataset.role.charAt(0).toUpperCase() + btn.dataset.role.slice(1)
    this.currentRoleLabelTarget.textContent = roleLabel

    if (btn.dataset.role !== "none") {
      this.newRoleTarget.value = btn.dataset.role
    } else {
      this.newRoleTarget.value = "member"
    }

    this.resultsTarget.classList.add("hidden")
    this.detailTarget.classList.remove("hidden")
  }

  save() {
    if (!this.selectedActor) return

    const hasRole = this.currentRoleTarget.value !== "none"
    const form = document.createElement("form")
    form.method = "POST"
    form.style.display = "none"

    const csrfToken = document.querySelector("[name='csrf-token']")?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    if (hasRole) {
      form.action = this.saveBtnTarget.dataset.submitUrl + this.selectedActor
      ;[
        ["_method", "patch"],
        ["from_role", this.currentRoleTarget.value],
        ["to_role", this.newRoleTarget.value]
      ].forEach(pair => appendInput(form, pair))
    } else {
      form.action = this.saveBtnTarget.dataset.submitUrl.replace(/\/$/, "")
      ;[
        ["actor_id", this.selectedActor],
        ["to_role", this.newRoleTarget.value]
      ].forEach(pair => appendInput(form, pair))
    }

    document.body.appendChild(form)
    form.submit()
  }
}

function appendInput(form, [name, value]) {
  const input = document.createElement("input")
  input.type = "hidden"
  input.name = name
  input.value = value
  form.appendChild(input)
}
