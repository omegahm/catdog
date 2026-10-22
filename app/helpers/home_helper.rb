module HomeHelper
  DEMO_PLACEMENTS = [
    [ "base-01", "front", 0, [ 2, 3 ] ],
    [ "base-35", "back", 270, [ 2, 2 ] ],
    [ "base-02", "back", 90, [ 2, 4 ] ],
    [ "base-40", "front", 180, [ 3, 4 ] ],
    [ "base-39", "front", 90, [ 4, 4 ] ],
    [ "base-06", "front", 0, [ 4, 3 ] ],
    [ "base-36", "back", 270, [ 4, 2 ] ],
    [ "base-18", "front", 0, [ 2, 5 ] ],
    [ "base-07", "back", 270, [ 3, 5 ] ]
  ].freeze
  DEMO_ROWS = (2..4).freeze
  DEMO_COLS = (2..5).freeze
  DEMO_CYCLE = 15.0
  DEMO_START = 0.6
  DEMO_STEP = 1.0
  DEMO_HOLD = 13.4
  DEMO_FADE = 14.2
  RULES_URL = "https://github.com/omegahm/catdog/blob/main/docs/rules.md".freeze
  SOURCE_URL = "https://github.com/omegahm/catdog".freeze

  DemoCell = Data.define(:placement, :step, :completed_step)

  def demo_cells(tile_set = Rules::TileSet.cached)
    board = Rules::Board.new(tile_set)
    cells = {}
    DEMO_PLACEMENTS.each_with_index do |(tile_id, face, rotation, cell), step|
      board = board.place(cell, tile_id, face, rotation)
      cells[cell] = DemoCell.new(placement: board.placements.fetch(cell), step:, completed_step: nil)
      board.animals_at(cell).select(&:complete?).flat_map(&:cells).each do |done|
        cells[done] = cells.fetch(done).with(completed_step: step) if cells.fetch(done).completed_step.nil?
      end
    end
    cells
  end

  def demo_keyframes(cells)
    percent = ->(seconds) { (seconds / DEMO_CYCLE * 100).round(2) }
    hold = percent.(DEMO_HOLD)
    fade = percent.(DEMO_FADE)
    frames = cells.values.map do |cell|
      appear = DEMO_START + cell.step * DEMO_STEP
      css = "@keyframes demo-tile-#{cell.step} { 0%, #{percent.(appear)}% { opacity: 0; translate: 0 -18%; scale: 1.12; } " \
        "#{percent.(appear + 0.45)}%, #{hold}% { opacity: 1; translate: none; scale: none; } #{fade}%, 100% { opacity: 0; translate: none; scale: none; } }"
      next css unless cell.completed_step

      glow = DEMO_START + cell.completed_step * DEMO_STEP + 0.45
      css + " @keyframes demo-glow-#{cell.step} { 0%, #{percent.(glow)}% { opacity: 0; } #{percent.(glow + 0.4)}%, #{hold}% { opacity: 1; } #{fade}%, 100% { opacity: 0; } }"
    end
    tag.style(frames.join("\n").html_safe)
  end
end
