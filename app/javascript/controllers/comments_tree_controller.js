import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const type = this.element.dataset.commentsTreeCommentableType
    const id   = this.element.dataset.commentsTreeCommentableId
    const key  = `collapse_${type}_${id}`
    const state = JSON.parse(localStorage.getItem(key) || "{}")

    Object.keys(state).forEach(commentId => {
      const checkbox = this.element.querySelector(`#${commentId} .comment_folder_button`)
      if (checkbox) {
        checkbox.checked = true
      }
    })
  }
}
