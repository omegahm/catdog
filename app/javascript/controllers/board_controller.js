import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["board", "hand", "hint", "form", "tile", "face", "rotation", "row", "col"]
  static values = { legal: Object, seq: Number }

  initialize() {
    this.reset()
  }

  connect() {
    this.onMorph = () => {
      this.submitting = false
      this.render()
    }
    this.onKey = (event) => this.key(event)
    document.addEventListener("turbo:morph", this.onMorph)
    document.addEventListener("keydown", this.onKey)
    this.render()
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.onMorph)
    document.removeEventListener("keydown", this.onKey)
    this.stopListening()
    this.drag?.floater?.remove()
  }

  seqValueChanged() {
    this.reset()
    if (this.hasBoardTarget) this.render()
  }

  reset() {
    this.rotations = {}
    this.selected = null
    this.target = null
    this.drag = null
    this.submitting = false
  }

  rotation(tile, face) {
    return this.rotations[`${tile}:${face}`] || 0
  }

  rotate(tile, face) {
    this.rotations[`${tile}:${face}`] = (this.rotation(tile, face) + 1) % 4
  }

  legalCells({ tile, face }) {
    const cells = this.legalValue[tile]?.[face]?.[this.rotation(tile, face) * 90] || []
    return new Set(cells.map(([row, col]) => `${row},${col}`))
  }

  isSelected(tile, face) {
    return this.selected?.tile === tile && this.selected?.face === face
  }

  handFor({ tile, face }) {
    return this.handTargets.find((hand) => hand.dataset.tile === tile && hand.dataset.face === face)
  }

  cellAt(key) {
    const [row, col] = key.split(",")
    return this.boardTarget.querySelector(`[data-row="${row}"][data-col="${col}"]`)
  }

  render() {
    for (const hand of this.handTargets) {
      const { tile, face } = hand.dataset
      const on = this.isSelected(tile, face)
      hand.classList.toggle("on", on)
      hand.classList.toggle("dim", !!this.selected && !on)
      hand.querySelector(".tile").style.setProperty("--rotation", `${this.rotation(tile, face) * 90}deg`)
    }

    if (this.selected && !this.handFor(this.selected)) this.reset()
    const source = this.drag?.moved ? this.drag : this.selected
    const legal = source ? this.legalCells(source) : new Set()
    for (const cell of this.boardTarget.querySelectorAll(".cell")) {
      const key = `${cell.dataset.row},${cell.dataset.col}`
      cell.classList.toggle("legal", legal.has(key))
      cell.classList.toggle("sel", !this.drag && this.target === key)
      cell.querySelector(".ghost")?.remove()
    }

    if (!this.drag && this.selected && this.target) {
      const ghost = this.handFor(this.selected).querySelector(".tile").cloneNode(true)
      ghost.classList.add("ghost")
      ghost.classList.toggle("bad", !legal.has(this.target))
      this.cellAt(this.target).append(ghost)
    }

    if (this.hasHintTarget) this.hintTarget.textContent = this.hint(legal)
  }

  hint(legal) {
    if (this.handTargets.length === 0) return ""
    if (!this.selected) return "Tap a face to see where it fits, or drag it onto the board. Tap a face again to rotate it."
    if (!this.target) return `${legal.size} green cells fit this way. Tap the face to rotate, tap a cell to preview, or drag.`
    if (!legal.has(this.target)) return "This way does not fit here. Rotate the face, or tap another cell."
    return "Tap the cell again, or press Enter."
  }

  tap(tile, face) {
    if (this.isSelected(tile, face)) {
      this.rotate(tile, face)
    } else {
      this.selected = { tile, face }
      this.target = null
    }
    this.render()
  }

  cell(event) {
    const cell = event.currentTarget
    if (!this.selected || cell.classList.contains("filled")) return

    const key = `${cell.dataset.row},${cell.dataset.col}`
    const legal = this.legalCells(this.selected).has(key)
    if (this.target === key && legal) return this.place()

    this.target = legal ? key : null
    this.render()
  }

  key(event) {
    if (event.target.closest("input, select, textarea, [contenteditable]")) return

    const hand = event.target.closest?.("[data-board-target~='hand']")
    if (hand && (event.key === "Enter" || event.key === " ")) {
      event.preventDefault()
      return this.tap(hand.dataset.tile, hand.dataset.face)
    }
    if ((event.key === "r" || event.key === "R") && this.selected) {
      this.rotate(this.selected.tile, this.selected.face)
      this.render()
    } else if (event.key === "Enter" && this.target) {
      event.preventDefault()
      this.place()
    }
  }

  place() {
    if (!this.selected || !this.target || !this.legalCells(this.selected).has(this.target)) return

    this.submit(this.selected.tile, this.selected.face, this.target)
  }

  submit(tile, face, key) {
    if (this.submitting) return

    this.submitting = true
    const [row, col] = key.split(",")
    this.tileTarget.value = tile
    this.faceTarget.value = face
    this.rotationTarget.value = this.rotation(tile, face) * 90
    this.rowTarget.value = row
    this.colTarget.value = col
    this.formTarget.requestSubmit()
  }

  down(event) {
    if (event.button > 0) return

    event.preventDefault()
    const { tile, face } = event.currentTarget.dataset
    this.drag = { tile, face, x: event.clientX, y: event.clientY, touch: event.pointerType !== "mouse", moved: false, hover: null }
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
      drag.legal = this.legalCells(drag)
      this.render()
      drag.size = this.boardTarget.querySelector(".cell").getBoundingClientRect().width
      drag.floater = document.createElement("div")
      drag.floater.className = "floater"
      drag.floater.style.width = drag.floater.style.height = `${drag.size}px`
      drag.floater.append(this.handFor(drag).querySelector(".tile").cloneNode(true))
      document.body.append(drag.floater)
    }

    const x = event.clientX
    const y = event.clientY - (drag.touch ? drag.size * 1.1 : 0)
    drag.floater.style.transform = `translate(${x - drag.size / 2}px, ${y - drag.size / 2}px)`
    const cell = document.elementFromPoint(x, y)?.closest(".cell")
    const key = cell && this.boardTarget.contains(cell) ? `${cell.dataset.row},${cell.dataset.col}` : null
    if (key !== drag.hover) {
      this.boardTarget.querySelectorAll(".hover, .hover-bad").forEach((element) => element.classList.remove("hover", "hover-bad"))
      if (cell && key && !cell.classList.contains("filled")) cell.classList.add(drag.legal.has(key) ? "hover" : "hover-bad")
      drag.hover = key
    }
  }

  up() {
    this.stopListening()
    const drag = this.drag
    this.drag = null
    if (!drag) return
    if (!drag.moved) return this.tap(drag.tile, drag.face)

    drag.floater.remove()
    this.boardTarget.querySelectorAll(".hover, .hover-bad").forEach((element) => element.classList.remove("hover", "hover-bad"))
    if (drag.hover && drag.legal.has(drag.hover)) this.submit(drag.tile, drag.face, drag.hover)
    else this.render()
  }

  stopListening() {
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  }
}
