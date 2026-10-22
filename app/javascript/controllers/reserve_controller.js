import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tile", "slot", "form", "take", "confirm"]

  initialize() {
    this.pick = null
  }

  connect() {
    this.onMorph = () => {
      this.submitting = false
      this.render()
    }
    document.addEventListener("turbo:morph", this.onMorph)
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.onMorph)
    this.stopListening()
    this.drag?.floater?.remove()
  }

  render() {
    if (this.pick && !this.tileTargets.some((tile) => tile.dataset.tile === this.pick)) this.pick = null
    for (const tile of this.tileTargets) tile.classList.toggle("on", tile.dataset.tile === this.pick)
    if (this.hasSlotTarget) this.slotTarget.classList.toggle("preview", !!this.pick)
    if (this.hasConfirmTarget) this.confirmTarget.hidden = !this.pick
  }

  toggle(tile) {
    this.pick = this.pick === tile ? null : tile
    this.render()
  }

  key(event) {
    if (event.key !== "Enter" && event.key !== " ") return

    event.preventDefault()
    this.toggle(event.currentTarget.dataset.tile)
  }

  slotTap() {
    if (this.pick) this.submit(this.pick)
  }

  confirm() {
    if (this.pick) this.submit(this.pick)
  }

  submit(tile) {
    if (this.submitting || !this.hasFormTarget) return

    this.submitting = true
    this.takeTarget.value = tile
    this.formTarget.requestSubmit()
  }

  down(event) {
    if (event.button > 0) return

    event.preventDefault()
    const tile = event.currentTarget.dataset.tile
    this.drag = { tile, source: event.currentTarget, x: event.clientX, y: event.clientY, touch: event.pointerType !== "mouse", moved: false, over: false }
    this.onMove = (moveEvent) => this.move(moveEvent)
    this.onUp = () => this.up()
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
  }

  move(event) {
    const drag = this.drag
    if (!drag) return
    if (!drag.moved && Math.hypot(event.clientX - drag.x, event.clientY - drag.y) < 8) return

    if (!drag.moved) {
      drag.moved = true
      drag.size = 64
      drag.floater = document.createElement("div")
      drag.floater.className = "floater"
      drag.floater.style.width = drag.floater.style.height = `${drag.size}px`
      drag.floater.append(drag.source.querySelector(".tile").cloneNode(true))
      document.body.append(drag.floater)
    }

    const x = event.clientX
    const y = event.clientY - (drag.touch ? drag.size : 0)
    drag.floater.style.transform = `translate(${x - drag.size / 2}px, ${y - drag.size / 2}px)`
    drag.over = this.hasSlotTarget && this.slotTarget.contains(document.elementFromPoint(x, y))
    if (this.hasSlotTarget) this.slotTarget.classList.toggle("drop", drag.over)
  }

  up() {
    this.stopListening()
    const drag = this.drag
    this.drag = null
    if (!drag) return
    if (!drag.moved) return this.toggle(drag.tile)

    drag.floater.remove()
    if (drag.over) this.submit(drag.tile)
    else this.render()
  }

  stopListening() {
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  }
}
