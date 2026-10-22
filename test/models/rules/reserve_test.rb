require "test_helper"

module Rules
  class ReserveTest < ActiveSupport::TestCase
    include RulesHelper

    def completed(**changes)
      play(
        game_with([ "dog tail w", "cat head n", "cat head n#2" ], board: { [ 3, 3 ] => "dog head e" }, **changes),
        draw(1, "dog tail w", "cat head n"),
        place(1, "dog tail w", [ 3, 4 ])
      )
    end

    test "a placement that completes an animal gives a reserve action" do
      game = completed

      assert_equal "awaiting_reserve_action", game.phase
      assert_equal 1, game.turn
      assert_equal [ "cat head n" ], game.state.discard
    end

    test "completing the opponent's animal gives the opponent the reserve action" do
      game = completed(species: { 1 => "cat", 2 => "dog" })

      assert_equal [ "awaiting_reserve_action", 2 ], [ game.phase, game.acting_seat ]
      assert_raises(IllegalMove) { game.apply(move(1, :reserve_action)) }

      taken = game.apply(move(2, :reserve_action, take: "cat head n"))
      assert_equal({ 1 => nil, 2 => "cat head n" }, taken.state.reserves)
      assert_equal [ 2, "awaiting_draw" ], [ taken.turn, taken.phase ]
    end

    test "completing your own animal gives you the reserve action" do
      assert_equal 1, completed(species: { 1 => "dog", 2 => "cat" }).acting_seat
    end

    test "completing a cat and a dog at once gives only the placer the reserve action" do
      game = play(
        game_with(
          [ "dog tail n + cat head s", "cat head n" ],
          board: { [ 2, 3 ] => "dog head s", [ 4, 3 ] => "cat tail n" },
          species: { 1 => "cat", 2 => "dog" }
        ),
        draw(1, "dog tail n + cat head s", "cat head n"),
        place(1, "dog tail n + cat head s", [ 3, 3 ])
      )

      assert_equal [ "awaiting_reserve_action", 1 ], [ game.phase, game.acting_seat ]
    end

    test "rules version 1 gives the placer the reserve action for any species" do
      game = play(
        game_with([ "dog tail w", "cat head n", "cat head n#2" ], board: { [ 3, 3 ] => "dog head e" }, species: { 1 => "cat", 2 => "dog" }, rules_version: 1),
        draw(1, "dog tail w", "cat head n"),
        place(1, "dog tail w", [ 3, 4 ])
      )

      assert_equal 1, game.acting_seat
      assert_equal 1, game.apply(move(1, :reserve_action, take: "cat head n")).state.reserves.key("cat head n")
    end

    test "the reserve action takes a tile from the discard pile and the rest goes back to the bag" do
      game = completed(discard: [ "cat tail s" ]).apply(move(1, :reserve_action, take: "cat tail s"))

      assert_equal({ 1 => "cat tail s", 2 => nil }, game.state.reserves)
      assert_empty game.state.discard
      assert_equal [ "cat head n", "cat head n#2" ], game.state.bag
      assert_equal [ 2, "awaiting_draw" ], [ game.turn, game.phase ]
    end

    test "taking a tile into a full reserve swaps the old tile to the discard pile and so to the bag" do
      game = completed(reserves: { 1 => "cat tail s", 2 => nil }).apply(move(1, :reserve_action, take: "cat head n"))

      assert_equal({ 1 => "cat head n", 2 => nil }, game.state.reserves)
      assert_equal [ "cat head n#2", "cat tail s" ], game.state.bag
    end

    test "skipping the reserve action still sends the discard pile back to the bag" do
      game = completed(reserves: { 1 => "cat tail s", 2 => nil }).apply(move(1, :reserve_action))

      assert_equal({ 1 => "cat tail s", 2 => nil }, game.state.reserves)
      assert_equal [ "cat head n", "cat head n#2" ], game.state.bag
      assert_empty game.state.discard
    end

    test "the reserve action can only take a tile from the discard pile" do
      assert_raises(IllegalMove) { completed.apply(move(1, :reserve_action, take: "cat head n#2")) }
      assert_raises(IllegalMove) { completed.apply(move(2, :reserve_action)) }
    end

    test "a placement that completes nothing gives no reserve action and the discard pile stays" do
      game = play(
        game_with([ "dog head n", "cat head n#2" ], board: { [ 3, 3 ] => "cat head n" }, discard: [ "cat tail s" ]),
        draw(1, "dog head n", "cat head n#2"),
        place(1, "dog head n", [ 3, 4 ])
      )

      assert_equal [ 2, "awaiting_draw" ], [ game.turn, game.phase ]
      assert_equal [ "cat tail s", "cat head n#2" ], game.state.discard
    end

    test "playing the reserve tile replaces the draw and the discard" do
      game = game_with([ "cat head n", "cat head n#2" ], board: { [ 3, 3 ] => "dog head e" }, reserves: { 1 => "dog tail w", 2 => nil })

      assert game.can_play_reserve?
      assert_equal [ "dog tail w" ], game.legal_placements.keys

      playing = game.apply(move(1, :play_reserve))
      assert_equal [ "awaiting_place", [ "dog tail w" ] ], [ playing.phase, playing.state.drawn ]
      assert_equal({ 1 => nil, 2 => nil }, playing.state.reserves)

      placed = playing.apply(place(1, "dog tail w", [ 3, 4 ]))
      assert_equal [ "cat head n", "cat head n#2" ], placed.state.bag
      assert_empty placed.state.discard
      assert_equal [ 2, "awaiting_draw" ], [ placed.turn, placed.phase ]
    end

    test "a completion with the reserve tile gives a reserve action when the discard pile has tiles" do
      game = play(
        game_with([], board: { [ 3, 3 ] => "dog head e" }, reserves: { 1 => "dog tail w", 2 => nil }, discard: [ "cat tail s" ]),
        move(1, :play_reserve),
        place(1, "dog tail w", [ 3, 4 ])
      )

      assert_equal "awaiting_reserve_action", game.phase
    end

    test "the reserve tile can be played when the bag holds fewer than two tiles" do
      assert game_with([ "cat head n" ], board: { [ 3, 3 ] => "dog head e" }, reserves: { 1 => "dog tail w", 2 => nil }).can_play_reserve?
    end

    test "a reserve tile with no legal placement cannot be played" do
      game = game_with([ "dog tail w", "cat head n#2" ], board: { [ 0, 0 ] => "dog turn e s" }, reserves: { 1 => "cat head n", 2 => nil })

      assert_not game.can_play_reserve?
      assert_raises(IllegalMove) { game.apply(move(1, :play_reserve)) }
      assert_equal "awaiting_place", game.apply(draw(1, "dog tail w", "cat head n#2")).phase
    end

    test "an empty reserve cannot be played" do
      assert_raises(IllegalMove) { game_with([ "cat head n", "cat head n#2" ]).apply(move(1, :play_reserve)) }
    end
  end
end
