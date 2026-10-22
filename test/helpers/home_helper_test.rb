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

  test "the demo ends with a complete dog of length 4, a complete cat of length 3 and open animals" do
    board = DEMO_PLACEMENTS.reduce(Rules::Board.new(Rules::TileSet.cached)) { |current, (*placement, cell)| current.place(cell, *placement) }
    complete, open = board.animals.partition(&:complete?)

    assert_equal [ [ "cat", 3 ], [ "dog", 4 ] ], complete.map { [ it.species, it.length ] }.sort
    assert_not_empty open
  end

  test "most demo tiles show two parts" do
    tiles = Rules::TileSet.cached

    assert DEMO_PLACEMENTS.count { |tile_id, face, *| tiles.fetch(tile_id).face(face).parts.size == 2 } >= DEMO_PLACEMENTS.size - 1
  end
end
