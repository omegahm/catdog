module HomeHelper
  DEMO_PLACEMENTS = [
    [ "base-14", "front", 270, [ 3, 3 ] ],
    [ "base-16", "front", 90, [ 2, 3 ] ],
    [ "base-19", "front", 90, [ 2, 4 ] ],
    [ "base-23", "back", 0, [ 3, 4 ] ],
    [ "base-18", "back", 0, [ 3, 2 ] ],
    [ "base-11", "back", 270, [ 3, 5 ] ],
    [ "base-26", "front", 270, [ 4, 2 ] ],
    [ "base-34", "back", 270, [ 4, 4 ] ],
    [ "base-33", "front", 180, [ 4, 5 ] ],
    [ "base-38", "back", 0, [ 2, 5 ] ]
  ].freeze
  DEMO_ROWS = (2..4).freeze
  DEMO_COLS = (2..5).freeze
  DEMO_CYCLE = 15.0
  DEMO_START = 0.6
  DEMO_STEP = 0.9
  DEMO_HOLD = 13.4
  DEMO_FADE = 14.2
  RULES_URL = "https://github.com/omegahm/catdog/blob/main/docs/rules.md".freeze
  SOURCE_URL = "https://github.com/omegahm/catdog".freeze

  DemoCell = Data.define(:placement, :step)

  def demo_cells(tile_set = Rules::TileSet.cached)
    board = Rules::Board.new(tile_set)
    DEMO_PLACEMENTS.each_with_index.to_h do |(tile_id, face, rotation, cell), step|
      board = board.place(cell, tile_id, face, rotation)
      [ cell, DemoCell.new(placement: board.placements.fetch(cell), step:) ]
    end
  end

  def demo_keyframes(cells)
    percent = ->(seconds) { (seconds / DEMO_CYCLE * 100).round(2) }
    frames = cells.values.map do |cell|
      appear = DEMO_START + cell.step * DEMO_STEP
      "@keyframes demo-tile-#{cell.step} { 0%, #{percent.(appear)}% { opacity: 0; translate: 0 -18%; scale: 1.12; } " \
        "#{percent.(appear + 0.45)}%, #{percent.(DEMO_HOLD)}% { opacity: 1; translate: none; scale: none; } " \
        "#{percent.(DEMO_FADE)}%, 100% { opacity: 0; translate: none; scale: none; } }"
    end
    tag.style(frames.join("\n").html_safe)
  end
end
