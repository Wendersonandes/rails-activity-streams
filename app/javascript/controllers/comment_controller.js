import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapseCheckbox", "score"]

  persistCollapse(event) {
    const tree = this.element.closest("[data-comments-tree-commentable-id]")
    if (!tree) return

    const commentableType = tree.dataset.commentsTreeCommentableType
    const commentableId   = tree.dataset.commentsTreeCommentableId
    const key = `collapse_${commentableType}_${commentableId}`
    
    const state = JSON.parse(localStorage.getItem(key) || "{}")
    if (event.target.checked) {
      state[this.element.id] = true
    } else {
      delete state[this.element.id]
    }
    localStorage.setItem(key, JSON.stringify(state))
  }

  upvote(event) {
    event.preventDefault()
    const form = event.currentTarget.closest("form")
    if (form) form.requestSubmit()
  }

  downvote(event) {
    event.preventDefault()
    const form = event.currentTarget.closest("form")
    if (form) form.requestSubmit()
  }
}
