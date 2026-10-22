require "test_helper"

class GamesHelperTest < ActionView::TestCase
  include RulesHelper

  test "the turn bar is green only on the seat's own turn" do
    engine = game_with([], first_seat: 1)

    assert_equal [ "turn-bar", "mine" ], turn_bar_class(engine, 1)
    assert_equal [ "turn-bar", nil ], turn_bar_class(engine, 2)
    assert_equal "you", turn_alert(engine, 1)
    assert_equal "", turn_alert(engine, 2)
    assert_equal "● Your turn – CatDog", page_title(engine, 1)
    assert_equal "CatDog", page_title(engine, 2)
  end

  test "in hot-seat play the turn bar takes the species of the acting seat" do
    engine = game_with([], first_seat: 2, species: { 1 => "cat", 2 => "dog" })

    assert_equal [ "turn-bar", "seat", "dog" ], turn_bar_class(engine, 2, hot_seat: true)
    assert_equal [ "turn-bar", "seat", nil ], turn_bar_class(game_with([], first_seat: 2), 2, hot_seat: true)
    assert_equal "player-2", turn_alert(engine, 2, hot_seat: true)
    assert_equal "CatDog", page_title(engine, 2, hot_seat: true)
  end

  test "the lobby and an ended game have a neutral turn bar" do
    ended = game_with([], phase: "ended", ending: { "reason" => "bag_exhausted" })

    assert_equal "turn-bar", turn_bar_class(nil, 1)
    assert_equal [ "turn-bar", nil ], turn_bar_class(ended, 1)
    assert_equal "", turn_alert(ended, 1)
  end

  test "the score rows count each length for both seats and name who scores it" do
    score = Rules::Score.new([ 5, 4, 3 ].map { animal("cat", it) } + [ 5, 5 ].map { animal("dog", it) }, { 1 => "cat", 2 => "dog" })
    engine = Struct.new(:score, :winner).new(score, 1)

    assert_equal [ [ 5, 1, 2, 2 ], [ 4, 1, 0, 1 ], [ 3, 1, 0, 1 ] ], score_rows(engine, 1)
    assert_equal [ [ 5, 2, 1, 2 ], [ 4, 0, 1, 1 ], [ 3, 0, 1, 1 ] ], score_rows(engine, 2)
    assert_nil tiebreak_line(engine, 1)
  end

  test "the tiebreak line names the longest length where the counts differ" do
    score = Rules::Score.new([ 2, 2, 5 ].map { animal("cat", it) } + [ 2, 5, 5 ].map { animal("dog", it) }, { 1 => "cat", 2 => "dog" })
    engine = Struct.new(:score, :winner).new(score, 2)

    assert_equal "Tied on points. You have more animals of length 5.", tiebreak_line(engine, 2)
    assert_equal "Tied on points. Opponent has more animals of length 5.", tiebreak_line(engine, 1)
    assert_equal "Tied on points. Player 2 has more animals of length 5.", tiebreak_line(engine, 1, hot_seat: true)

    drawn = Rules::Score.new([ animal("cat", 4), animal("dog", 4) ], { 1 => "cat", 2 => "dog" })
    assert_equal "Tied on points and on every length.", tiebreak_line(Struct.new(:score, :winner).new(drawn, nil), 1)
  end

  test "the result bar is gold for the winner, and in hot-seat play whenever someone won" do
    won = Struct.new(:winner) { def ended? = true }.new(1)

    assert_equal [ "turn-bar", "won" ], turn_bar_class(won, 1)
    assert_equal [ "turn-bar", nil ], turn_bar_class(won, 2)
    assert_equal [ "turn-bar", "won" ], turn_bar_class(won, 2, hot_seat: true)
  end
end
