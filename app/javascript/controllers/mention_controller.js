import { Controller } from "@hotwired/stimulus"
import Tribute from "tributejs"

// Connects to data-controller="mention"
export default class extends Controller {
  static targets = [ "editor", "hiddenInput" ]

  connect() {
    if (!this.hasEditorTarget) return

    this.tribute = new Tribute({
      trigger: "@",
      values: (text, cb) => {
        if (!text || text.length < 3) {
          cb([])
          return
        }

        fetch(`/actors.json?q=${encodeURIComponent(text)}`, {
          headers: {
            "Accept": "application/json"
          }
        })
          .then(response => {
            if (!response.ok) throw new Error("Search failed")
            return response.json()
          })
          .then(results => {
            cb(results.map(u => ({
              key: u.name,
              value: `@[${u.name}](${u.slug})`,
              avatar: u.avatar_url,
              slug: u.slug
            })))
          })
          .catch(error => {
            console.error("Autocomplete fetch error:", error)
            cb([])
          })
      },
      lookup: "key",
      fillAttr: "value",
      selectTemplate: (item) => {
        return `<span class="mention-pill bg-blue-50 text-blue-700 px-1.5 py-0.5 rounded-md font-medium text-xs inline-block mx-0.5" data-slug="${item.original.slug}" contenteditable="false">@${item.original.key}</span>&nbsp;`
      },
      requireLeadingSpace: true,
      allowSpaces: true,
      menuShowMinLength: 3,
      replaceTextSuffix: "", // Leave suffix empty since we append &nbsp; in selectTemplate
      
      menuItemTemplate: (item) => {
        const initials = (item.original.key || "?").charAt(0).toUpperCase();
        
        const avatarElement = item.original.avatar
          ? `<img src="${item.original.avatar}" class="w-6 h-6 rounded-full object-cover border border-gray-100 flex-shrink-0" />`
          : `<div class="w-6 h-6 rounded-full bg-blue-50 text-blue-600 border border-blue-100 flex items-center justify-center text-[10px] font-bold flex-shrink-0">${initials}</div>`;

        return `<div class="flex items-center gap-2 p-1">
          ${avatarElement}
          <div class="flex flex-col min-w-0">
            <span class="text-xs font-semibold text-gray-900 truncate">${item.original.key}</span>
            <span class="text-[9px] text-gray-400 font-medium truncate">@${item.original.slug}</span>
          </div>
        </div>`;
      }
    })
    
    this.tribute.attach(this.editorTarget)

    // Trigger sync on tribute replacement (de-raced with setTimeout)
    this.editorTarget.addEventListener("tribute-replaced", () => {
      setTimeout(() => this.sync(), 0)
    })
  }

  disconnect() {
    if (this.tribute && this.hasEditorTarget) {
      this.tribute.detach(this.editorTarget)
    }
  }

  // Translates the editor's visual HTML elements back to raw Markdown syntax
  sync() {
    if (!this.hasEditorTarget || !this.hasHiddenInputTarget) return

    let html = this.editorTarget.innerHTML

    // If editor has only empty elements or spaces, clear it
    if (this.editorTarget.textContent.trim() === "" && !this.editorTarget.querySelector('.mention-pill')) {
      this.hiddenInputTarget.value = ""
      return
    }

    const parser = new DOMParser()
    const doc = parser.parseFromString(html, 'text/html')

    // Find all pills and replace them with Markdown syntax: @[Name](slug)
    doc.querySelectorAll('.mention-pill').forEach(pill => {
      const name = pill.textContent.replace(/^@/, '')
      const slug = pill.getAttribute('data-slug')
      pill.replaceWith(`@[${name}](${slug})`)
    })

    // Handle block tags and line breaks to preserve newlines
    doc.querySelectorAll('div, p').forEach(block => {
      block.prepend('\n')
    })
    doc.querySelectorAll('br').forEach(br => {
      br.replaceWith('\n')
    })

    let markdown = doc.body.textContent || ""
    
    // Normalize newlines and trim leading/trailing spaces
    markdown = markdown.replace(/^\n/, '')

    this.hiddenInputTarget.value = markdown
  }

  // Clears both the visual editor and the hidden markdown field (used during comment reset)
  clear() {
    if (this.hasEditorTarget) {
      this.editorTarget.innerHTML = ""
    }
    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = ""
    }
  }
}
