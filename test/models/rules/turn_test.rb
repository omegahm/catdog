require "test_helper"

module Rules
  class TurnTest < ActiveSupport::TestCase
    include RulesHelper

    def opening = game_with([ "dog head e", "cat head n", "dog tail w" ])

    test "a turn draws two tiles, places one and discards the other" do
      game = play(opening, draw(1, "dog head e", "cat head n"), place(1, "dog head e", [ 3, 3 ]))

      assert_equal [ "dog tail w" ], game.state.bag
      assert_equal [ "cat head n" ], game.state.discard
      assert_empty game.state.drawn
      assert_equal({ [ 3, 3 ] => Board::Placement.new(tile_id: "dog head e", face: "front", rotation: 0) }, game.state.board)
      assert_equal [ 2, "awaiting_draw" ], [ game.turn, game.phase ]
    end

    test "only the seat on turn may move" do
      assert_raises(IllegalMove) { opening.apply(draw(2, "dog head e", "cat head n")) }
      assert_raises(IllegalMove) { opening.apply(draw(3, "dog head e", "cat head n")) }
    end

    test "a move must fit the phase" do
      assert_raises(IllegalMove) { opening.apply(place(1, "dog head e", [ 3, 3 ])) }
      assert_raises(IllegalMove) { opening.apply(move(1, :reserve_action)) }
      assert_raises(IllegalMove) { opening.apply(move(1, :choose_species, species: "cat")) }
      assert_raises(IllegalMove) { opening.apply(draw(1, "dog head e", "cat head n")).apply(draw(1, "dog tail w", "cat head n")) }
      assert_raises(IllegalMove) { opening.apply(move(1, :shuffle)) }
    end

    test "a draw takes two different tiles from the bag" do
      assert_raises(IllegalMove) { opening.apply(draw(1, "dog head e")) }
      assert_raises(IllegalMove) { opening.apply(draw(1, "dog head e", "dog head e")) }
      assert_raises(IllegalMove) { opening.apply(draw(1, "dog head e", "cat tail s")) }
    end

    test "draw_tiles picks two tiles from the bag" do
      tiles = opening.draw_tiles(random: Random.new(1))

      assert_equal 2, tiles.uniq.size
      assert_empty tiles - opening.state.bag
    end

    test "a placement must be a legal placement of a drawn tile" do
      drawn = opening.apply(draw(1, "dog head e", "cat head n"))

      assert_raises(IllegalMove) { drawn.apply(place(1, "dog tail w", [ 3, 3 ])) }
      assert_raises(IllegalMove) { drawn.apply(place(1, "dog head e", [ 3, 6 ])) }
      assert_raises(IllegalMove) { drawn.apply(place(1, "dog head e", [ 3, 3 ], face: "side")) }
      assert_raises(IllegalMove) { drawn.apply(place(1, "dog head e", [ 3, 3 ], rotation: 45)) }
      assert_raises(IllegalMove) { drawn.apply(place(1, "dog head e", "3,3")) }
    end

    test "legal placements cover the tiles the player can place" do
      assert_empty opening.legal_placements

      drawn = opening.apply(draw(1, "dog head e", "cat head n"))
      assert_equal [ "dog head e", "cat head n" ], drawn.legal_placements.keys
      assert_includes drawn.legal_placements.dig("dog head e", "front", 0), [ 3, 3 ]
    end

    test "the state survives a JSON round trip" do
      game = play(opening, draw(1, "dog head e", "cat head n"), place(1, "dog head e", [ 3, 3 ], rotation: 90))
      json = JSON.parse(game.state.to_json)

      assert_equal game.state, State.from_h(json)
      assert_equal({ "tile" => "dog head e", "face" => "front", "rotation" => 90 }, json.dig("board", "3,3"))
    end

    test "replaying the moves gives the same state" do
      moves = [ draw(1, "dog head e", "cat head n"), place(1, "dog head e", [ 3, 3 ]), move(2, :end_game, reason: "resign") ]

      assert_equal play(opening, *moves).state, Game.replay(opening.tile_set, first_seat: 1, moves:).state
    end
  end
end
