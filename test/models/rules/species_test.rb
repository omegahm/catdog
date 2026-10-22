require "test_helper"

module Rules
  class SpeciesTest < ActiveSupport::TestCase
    include RulesHelper

    test "the player who completes the first animal plays as its species" do
      game = play(
        game_with([ "dog tail w", "cat head n" ], board: { [ 3, 3 ] => "dog head e" }, first_seat: 2),
        draw(2, "dog tail w", "cat head n"),
        place(2, "dog tail w", [ 3, 4 ])
      )

      assert_equal({ 1 => "cat", 2 => "dog" }, game.state.species)
    end

    test "the species does not change after the first animal" do
      game = play(
        game_with([ "cat tail w", "dog head n" ], board: { [ 3, 3 ] => "cat head e" }, species: { 1 => "dog", 2 => "cat" }),
        draw(1, "cat tail w", "dog head n"),
        place(1, "cat tail w", [ 3, 4 ])
      )

      assert_equal({ 1 => "dog", 2 => "cat" }, game.state.species)
    end

    test "a complete animal belongs to the player of its species, no matter who completed it" do
      game = play(
        game_with([ "cat tail w", "dog head n" ], board: { [ 3, 3 ] => "cat head e" }, species: { 1 => "dog", 2 => "cat" }),
        draw(1, "cat tail w", "dog head n"),
        place(1, "cat tail w", [ 3, 4 ])
      )

      assert_equal({ 1 => {}, 2 => { 2 => 1 } }, game.score.lengths)
    end

    test "the placing player chooses a species when the first completion completes a cat and a dog" do
      game = play(
        game_with([ "dog tail n + cat head s", "cat head n" ], board: { [ 2, 3 ] => "dog head s", [ 4, 3 ] => "cat tail n" }),
        draw(1, "dog tail n + cat head s", "cat head n"),
        place(1, "dog tail n + cat head s", [ 3, 3 ])
      )

      assert_equal "awaiting_species", game.phase
      assert_raises(IllegalMove) { game.apply(move(1, :choose_species, species: "bird")) }
      assert_raises(IllegalMove) { game.apply(move(2, :choose_species, species: "cat")) }

      chosen = game.apply(move(1, :choose_species, species: "cat"))
      assert_equal({ 1 => "cat", 2 => "dog" }, chosen.state.species)
      assert_equal "awaiting_reserve_action", chosen.phase
    end

    test "there is no species choice when the species are already set" do
      game = play(
        game_with(
          [ "dog tail n + cat head s", "cat head n" ],
          board: { [ 2, 3 ] => "dog head s", [ 4, 3 ] => "cat tail n" },
          species: { 1 => "dog", 2 => "cat" }
        ),
        draw(1, "dog tail n + cat head s", "cat head n"),
        place(1, "dog tail n + cat head s", [ 3, 3 ])
      )

      assert_equal "awaiting_reserve_action", game.phase
    end

    test "two animals of one species do not give a choice" do
      game = play(
        game_with([ "dog tail n + dog head s", "cat head n" ], board: { [ 2, 3 ] => "dog head s", [ 4, 3 ] => "dog tail n" }),
        draw(1, "dog tail n + dog head s", "cat head n"),
        place(1, "dog tail n + dog head s", [ 3, 3 ])
      )

      assert_equal({ 1 => "dog", 2 => "cat" }, game.state.species)
      assert_equal "awaiting_reserve_action", game.phase
    end
  end
end
