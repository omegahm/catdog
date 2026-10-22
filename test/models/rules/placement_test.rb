require "test_helper"

module Rules
  class PlacementTest < ActiveSupport::TestCase
    include RulesHelper

    test "the first tile can go anywhere a part does not face the outer edge" do
      assert board.legal?("dog straight w e", "front", 0, [ 3, 3 ])
      assert board.legal?("dog straight w e", "front", 0, [ 0, 3 ])
      assert_not board.legal?("dog straight w e", "front", 0, [ 3, 0 ])
      assert_not board.legal?("dog straight w e", "front", 0, [ 3, 6 ])
    end

    test "a tile must share an edge with a placed tile" do
      start = board([ 3, 3 ] => "cat head n")

      assert start.legal?("dog head n", "front", 0, [ 3, 4 ])
      assert_not start.legal?("dog head n", "front", 0, [ 4, 4 ])
      assert_not start.legal?("dog head n", "front", 0, [ 5, 3 ])
    end

    test "a tile cannot go on an occupied cell or outside the board" do
      start = board([ 3, 3 ] => "cat head n")

      assert_not start.legal?("dog head n", "front", 0, [ 3, 3 ])
      assert_not start.legal?("dog head n", "front", 0, [ 3, 7 ])
    end

    test "background meets background" do
      assert board([ 3, 3 ] => "cat head n").legal?("dog head n", "front", 0, [ 3, 4 ])
    end

    test "a part meets a part of the same species" do
      start = board([ 3, 3 ] => "dog head e")

      assert start.legal?("dog tail w", "front", 0, [ 3, 4 ])
      assert_not start.legal?("cat tail w", "front", 0, [ 3, 4 ])
    end

    test "a part may never meet background" do
      assert_not board([ 3, 3 ] => "dog head n").legal?("dog tail w", "front", 0, [ 3, 4 ])
      assert_not board([ 3, 3 ] => "dog head e").legal?("dog head n", "front", 0, [ 3, 4 ])
    end

    test "every shared edge must match" do
      start = board([ 3, 3 ] => "dog head e", [ 2, 4 ] => "cat head n")

      assert start.legal?("dog tail w", "front", 0, [ 3, 4 ])
      assert_not start.legal?("dog tail w + cat tail n", "front", 0, [ 3, 4 ])
    end

    test "a part may face an empty cell" do
      assert board([ 3, 3 ] => "cat head n").legal?("dog straight n s", "front", 0, [ 3, 4 ])
    end

    test "a part may not face the outer edge next to a placed tile" do
      start = board([ 0, 3 ] => "dog head e")

      assert start.legal?("dog tail w", "front", 0, [ 0, 4 ])
      assert_not start.legal?("dog tail w + dog head n", "front", 0, [ 0, 4 ])
    end

    test "rotation turns the face clockwise" do
      start = board([ 3, 4 ] => "dog tail w")

      assert_not start.legal?("dog head n", "front", 0, [ 3, 3 ])
      assert start.legal?("dog head n", "front", 90, [ 3, 3 ])
      assert_not start.legal?("dog head n", "front", 180, [ 3, 3 ])
      assert_not start.legal?("dog head n", "front", 270, [ 3, 3 ])
    end

    test "the player chooses which face is up" do
      start = board([ 3, 4 ] => "dog tail w")

      assert_not start.legal?("dog tail e | dog head e", "front", 0, [ 3, 3 ])
      assert start.legal?("dog tail e | dog head e", "back", 0, [ 3, 3 ])
    end

    test "legal placements list the cells for each face and rotation" do
      placements = board([ 3, 4 ] => "dog tail w").legal_placements("dog head n")

      assert_equal FACES, placements.keys
      assert_equal ROTATIONS, placements["front"].keys
      assert_includes placements["front"][90], [ 3, 3 ]
      assert_not_includes placements["front"][0], [ 3, 3 ]
      assert_equal placements["front"], placements["back"]
    end

    test "a tile is placeable when any face and rotation has a legal cell" do
      corner = board([ 0, 0 ] => "dog turn e s")

      assert corner.placeable?("dog tail w")
      assert_not corner.placeable?("cat head n")
    end
  end
end
