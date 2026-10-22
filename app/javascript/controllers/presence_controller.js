import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

const TIMEOUT = 75_000
const HEARTBEAT = 30_000

export default class extends Controller {
  static targets = ["indicator"]
  static values = { game: String, opponent: Number, seenAgo: { type: Number, default: -1 } }

  initialize() {
    window.addEventListener("pageshow", (event) => {
      if (event.persisted && !this.connected && this.element.isConnected) this.connect()
    })
  }

  async connect() {
    this.connected = true
    this.onPageHide = () => this.disconnect()
    window.addEventListener("pagehide", this.onPageHide)
    this.ticker = setInterval(() => this.render(), 5_000)
    const subscription = await cable.subscribeTo(
      { channel: "PresenceChannel", game: this.gameValue },
      {
        received: (data) => this.received(data),
        connected: () => this.dispatch("connected"),
        disconnected: () => this.dispatch("disconnected")
      }
    )
    if (!this.connected) return subscription.unsubscribe()

    this.subscription = subscription
    this.heartbeat = setInterval(() => this.subscription.perform("heartbeat"), HEARTBEAT)
  }

  disconnect() {
    window.removeEventListener("pagehide", this.onPageHide)
    this.connected = false
    clearInterval(this.ticker)
    clearInterval(this.heartbeat)
    this.subscription?.unsubscribe()
    this.subscription = null
  }

  seenAgoValueChanged() {
    this.seenAt = this.seenAgoValue < 0 ? null : Date.now() - this.seenAgoValue * 1000
    this.render()
  }

  indicatorTargetConnected() {
    this.render()
  }

  received({ seat, seen_ago: seenAgo }) {
    if (seat !== this.opponentValue) return

    this.seenAt = seenAgo === null ? null : Date.now() - seenAgo * 1000
    this.render()
  }

  render() {
    const online = this.seenAt != null && Date.now() - this.seenAt < TIMEOUT
    for (const indicator of this.indicatorTargets) {
      indicator.textContent = online ? "● online" : "○ offline"
      indicator.classList.toggle("online", online)
    }
  }
}
