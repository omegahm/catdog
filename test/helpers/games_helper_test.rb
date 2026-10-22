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
    assert_equal "turn-bar", turn_bar_class(ended, 1)
    assert_equal "", turn_alert(ended, 1)
  end
end
