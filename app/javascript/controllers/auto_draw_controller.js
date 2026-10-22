import { Controller } from "@hotwired/stimulus"

const drawn = new Set()

export default class extends Controller {
  static values = { seq: Number, enabled: Boolean }

  connect() {
    this.draw()
  }

  seqValueChanged() {
    if (this.element.isConnected) this.draw()
  }

  draw() {
    const key = `${this.element.action}#${this.seqValue}`
    if (!this.enabledValue || drawn.has(key) || !autoDrawOn()) return

    drawn.add(key)
    setTimeout(() => {
      if (this.element.isConnected) this.element.requestSubmit()
    }, 400)
  }
}

function autoDrawOn() {
  try {
    return localStorage.getItem("catdog-auto-draw") !== "off"
  } catch {
    return true
  }
}
