require "test_helper"

class HomeHelperTest < ActionView::TestCase
  include RulesHelper

  test "every demo placement is legal in order and uses a different tile" do
    tiles = Rules::TileSet.cached
    board = DEMO_PLACEMENTS.reduce(Rules::Board.new(tiles)) do |current, (tile_id, face, rotation, cell)|
      assert current.legal?(tile_id, face, rotation, cell), "#{tile_id} on #{cell} is not legal"
      current.place(cell, tile_id, face, rotation)
    end

    assert_empty board_problems(board)
    assert_equal DEMO_PLACEMENTS.size, DEMO_PLACEMENTS.map(&:first).uniq.size
    assert DEMO_PLACEMENTS.all? { |*, (row, col)| DEMO_ROWS.include?(row) && DEMO_COLS.include?(col) }
  end

  test "the demo ends with a complete dog of length 4, a complete cat of length 3 and open cats" do
    board = DEMO_PLACEMENTS.reduce(Rules::Board.new(Rules::TileSet.cached)) { |current, (*placement, cell)| current.place(cell, *placement) }
    complete, open = board.animals.partition(&:complete?)

    assert_equal [ [ "cat", 3 ], [ "dog", 4 ] ], complete.map { [ it.species, it.length ] }.sort
    assert_equal [ "cat", "cat" ], open.map(&:species)
  end

  test "demo cells glow from the step that completes their animal" do
    cells = demo_cells

    assert_equal 3, cells.fetch([ 2, 2 ]).completed_step
    assert_equal 6, cells.fetch([ 4, 4 ]).completed_step
    assert_nil cells.fetch([ 3, 5 ]).completed_step
  end
end
