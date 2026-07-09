import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapseCheckbox", "score", "upvoteButton", "downvoteButton", "upvoteIcon", "downvoteIcon"]
  static values = {
    currentVote: Number,
    score: Number
  }

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
    if (!form) return

    const current = this.currentVoteValue
    const target = (current === 1) ? 0 : 1
    this.applyOptimisticVote(target)

    form.requestSubmit()
  }

  downvote(event) {
    event.preventDefault()
    const form = event.currentTarget.closest("form")
    if (!form) return

    const current = this.currentVoteValue
    const target = (current === -1) ? 0 : -1
    this.applyOptimisticVote(target)

    form.requestSubmit()
  }

  applyOptimisticVote(targetVote) {
    const diff = targetVote - this.currentVoteValue
    const newScore = this.scoreValue + diff

    // 1. Update score displays
    this.scoreTargets.forEach(el => el.textContent = newScore)

    // 2. Update upvote button style & classes
    if (this.hasUpvoteButtonTarget) {
      const upBtn = this.upvoteButtonTarget
      const upIcon = this.upvoteIconTarget
      if (targetVote === 1) {
        upBtn.className = "flex items-center gap-1 text-blue-500 hover:text-blue-600 bg-transparent border-0 cursor-pointer p-0 font-medium"
        upIcon.classList.add("fill-current")
      } else {
        upBtn.className = "flex items-center gap-1 text-gray-400 hover:text-blue-500 bg-transparent border-0 cursor-pointer p-0 font-medium"
        upIcon.classList.remove("fill-current")
      }
    }

    // 3. Update downvote button style & classes
    if (this.hasDownvoteButtonTarget) {
      const downBtn = this.downvoteButtonTarget
      const downIcon = this.downvoteIconTarget
      if (targetVote === -1) {
        downBtn.className = "flex items-center gap-1 text-red-500 hover:text-red-600 bg-transparent border-0 cursor-pointer p-0"
        downIcon.classList.add("fill-current")
      } else {
        downBtn.className = "flex items-center gap-1 text-gray-400 hover:text-red-500 bg-transparent border-0 cursor-pointer p-0"
        downIcon.classList.remove("fill-current")
      }
    }
  }
}
