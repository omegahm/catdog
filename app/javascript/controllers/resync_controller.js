import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  connect() {
    this.wasConnected = false
    this.lost = false
    this.observer = new MutationObserver(() => this.check())
    this.observer.observe(this.element, { subtree: true, attributes: true, attributeFilter: ["connected"] })
    this.onVisible = () => {
      if (document.visibilityState === "visible") this.refresh()
    }
    document.addEventListener("visibilitychange", this.onVisible)
  }

  disconnect() {
    this.observer.disconnect()
    document.removeEventListener("visibilitychange", this.onVisible)
  }

  check() {
    const connected = !!this.element.querySelector("turbo-cable-stream-source[connected]")
    if (connected && this.lost) {
      this.lost = false
      this.refresh()
    }
    if (!connected && this.wasConnected) this.lost = true
    this.wasConnected = connected
  }

  refresh() {
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
