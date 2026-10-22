require "test_helper"

module Rules
  class ScoreTest < ActiveSupport::TestCase
    include RulesHelper

    def score(cats, dogs, species: { 1 => "cat", 2 => "dog" })
      Score.new(cats.map { animal("cat", it) } + dogs.map { animal("dog", it) }, species)
    end

    test "the example from the rules: cats 3, 3, 5 beat dogs 3, 4 by 2 to 1" do
      result = score([ 3, 3, 5 ], [ 3, 4 ])

      assert_equal({ 1 => 2, 2 => 1 }, result.points)
      assert_equal 1, result.winner
    end

    test "a tied length scores for no one" do
      result = score([ 3, 4 ], [ 3 ])

      assert_equal({ 1 => 1, 2 => 0 }, result.points)
    end

    test "tied points go to the player with more animals at the longest length where the counts differ" do
      assert_equal 2, score([ 2, 2, 5 ], [ 2, 5, 5 ]).winner
      assert_equal 2, score([ 2, 2, 4, 6 ], [ 3, 3, 4, 6 ]).winner
      assert_equal 1, score([ 2, 3, 3, 7 ], [ 2, 2, 3, 7 ]).winner
    end

    test "the game is a draw when no length is different" do
      result = score([ 2, 4 ], [ 4, 2 ])

      assert_equal({ 1 => 0, 2 => 0 }, result.points)
      assert result.draw?
    end

    test "with no complete animal both players score 0 and the game is a draw" do
      result = score([], [], species: { 1 => nil, 2 => nil })

      assert_equal({ 1 => 0, 2 => 0 }, result.points)
      assert result.draw?
    end

    test "open animals score nothing" do
      open = Animal.new(species: "cat", parts: [ Part.new(species: "cat", kind: "head", edges: [ "n" ]) ], segments: [ [ [ 0, 0 ], 0 ] ], closed: false)

      assert_equal({ 1 => 0, 2 => 0 }, Score.new([ open ], { 1 => "cat", 2 => "dog" }).points)
    end

    test "animals score for the player who plays their species" do
      result = score([ 3 ], [], species: { 1 => "dog", 2 => "cat" })

      assert_equal({ 1 => 0, 2 => 1 }, result.points)
      assert_equal 2, result.winner
    end

    test "there is no maximum length" do
      assert_equal({ 1 => 1, 2 => 0 }, score([ 30 ], []).points)
    end
  end
end
