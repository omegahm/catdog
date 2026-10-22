import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    this.lost = false
    this.onVisible = () => {
      if (document.visibilityState === "visible") this.refresh()
    }
    document.addEventListener("visibilitychange", this.onVisible)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.onVisible)
  }

  connectionLost() {
    this.lost = true
    this.bannerTarget.hidden = false
  }

  connectionBack() {
    this.bannerTarget.hidden = true
    if (!this.lost) return

    this.lost = false
    this.refresh()
  }

  refresh() {
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
