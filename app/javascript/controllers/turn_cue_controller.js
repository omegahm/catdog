import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { alert: String }

  alertValueChanged(value) {
    const previous = this.seen
    this.seen = value
    if (previous === undefined || !value || value === previous) return
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.element.animate(
      [{ transform: "scale(1)" }, { transform: "scale(1.04)" }, { transform: "scale(1)" }],
      { duration: 500, iterations: 3, easing: "ease-in-out" }
    )
  }
}
