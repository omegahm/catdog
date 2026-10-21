require "test_helper"

module Rules
  class GameEndTest < ActiveSupport::TestCase
    include RulesHelper

    test "drawing from a bag with fewer than two tiles ends the game" do
      game = game_with([ "cat head n" ], board: { [ 3, 3 ] => "dog head e" })

      assert_equal [], game.draw_tiles
      assert_raises(IllegalMove) { game.apply(draw(1, "cat head n")) }

      ended = game.apply(draw(1))
      assert ended.ended?
      assert_equal({ "reason" => "bag_exhausted" }, ended.state.ending)
      assert_equal [ "cat head n" ], ended.state.bag
    end

    test "a player with a reserve tile may still draw and end the game" do
      game = game_with([], board: { [ 3, 3 ] => "dog head e" }, reserves: { 1 => "dog tail w", 2 => nil })

      assert game.can_play_reserve?
      assert game.apply(draw(1)).ended?
    end

    test "the game ends when neither drawn tile has a legal placement" do
      game = game_with([ "cat head n", "cat head n#2" ], board: { [ 0, 0 ] => "dog turn e s" }).apply(draw(1, "cat head n", "cat head n#2"))

      assert game.ended?
      assert_equal({ "reason" => "stuck" }, game.state.ending)
      assert_equal [ "cat head n", "cat head n#2" ], game.state.drawn
    end

    test "when only one drawn tile has a legal placement, the player must place that tile" do
      game = game_with([ "cat head n", "dog tail w" ], board: { [ 0, 0 ] => "dog turn e s" }).apply(draw(1, "cat head n", "dog tail w"))

      assert_equal [ "cat head n", "dog tail w" ], game.legal_placements.keys
      assert game.legal_placements["cat head n"].values.flat_map(&:values).all?(&:empty?)
      assert_raises(IllegalMove) { game.apply(place(1, "cat head n", [ 0, 1 ])) }
      assert_equal 2, game.apply(place(1, "dog tail w", [ 0, 1 ])).turn
    end

    test "after the draw, the player cannot switch to the reserve tile" do
      game = game_with([ "cat head n", "cat head n#2" ], board: { [ 3, 3 ] => "dog head e" }, reserves: { 1 => "dog tail w", 2 => nil })
        .apply(draw(1, "cat head n", "cat head n#2"))

      assert_raises(IllegalMove) { game.apply(move(1, :play_reserve)) }
      assert_not game.can_play_reserve?
    end

    test "the opponent gets no last turn" do
      game = game_with([]).apply(draw(1))

      assert_raises(IllegalMove) { game.apply(draw(2)) }
      assert_raises(IllegalMove) { game.apply(move(2, :end_game, reason: "resign")) }
    end

    test "a player may resign at any time, also on the opponent's turn, and the opponent wins" do
      game = game_with([ "cat head n", "cat head n#2" ]).apply(move(2, :end_game, reason: "resign"))

      assert game.ended?
      assert_equal({ "reason" => "resign", "seat" => 2 }, game.state.ending)
      assert_equal 1, game.winner
    end

    test "resigning ignores the board" do
      game = game_with([], board: { [ 3, 3 ] => "dog head e", [ 3, 4 ] => "dog tail w" }, species: { 1 => "dog", 2 => "cat" })

      assert_equal 1, game.apply(draw(1)).winner
      assert_equal 2, game.apply(move(1, :end_game, reason: "resign")).winner
    end

    test "end_game needs a known reason" do
      assert_raises(IllegalMove) { game_with([]).apply(move(1, :end_game)) }
    end

    test "a game with no complete animals is a draw" do
      game = game_with([], board: { [ 3, 3 ] => "dog head e" }).apply(draw(1))

      assert_nil game.winner
      assert_equal({ 1 => 0, 2 => 0 }, game.score.points)
    end
  end
end
