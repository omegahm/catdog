import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["style", "cat", "dog", "autoDraw"]

  connect() {
    const root = document.documentElement
    this.styleTarget.value = root.dataset.style
    this.catTarget.value = root.dataset.cat
    this.dogTarget.value = root.dataset.dog
    this.autoDrawTarget.checked = read("catdog-auto-draw") !== "off"
  }

  save(event) {
    const root = document.documentElement
    if (this.catTarget.value === this.dogTarget.value) {
      if (event.target === this.catTarget) this.dogTarget.value = root.dataset.cat
      else this.catTarget.value = root.dataset.dog
    }

    root.dataset.style = this.styleTarget.value
    root.dataset.cat = this.catTarget.value
    root.dataset.dog = this.dogTarget.value
    write("catdog-style", root.dataset.style)
    write("catdog-cat", root.dataset.cat)
    write("catdog-dog", root.dataset.dog)
    write("catdog-auto-draw", this.autoDrawTarget.checked ? "on" : "off")
  }
}

function read(key) {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}

function write(key, value) {
  try {
    localStorage.setItem(key, value)
  } catch {
  }
}
