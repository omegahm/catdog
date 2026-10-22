import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { alert: String, ended: Boolean }

  alertValueChanged(value) {
    const previous = this.seen
    this.seen = value
    if (previous === undefined || !value || value === previous) return
    if (reducedMotion()) return

    this.element.animate(
      [{ transform: "scale(1)" }, { transform: "scale(1.04)" }, { transform: "scale(1)" }],
      { duration: 500, iterations: 3, easing: "ease-in-out" }
    )
  }

  endedValueChanged(value) {
    const previous = this.wasEnded
    this.wasEnded = value
    if (previous === false && value) window.scrollTo({ top: 0, behavior: reducedMotion() ? "auto" : "smooth" })
  }
}

function reducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches
}
