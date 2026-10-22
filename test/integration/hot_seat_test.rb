require "test_helper"

class HotSeatTest < ActionDispatch::IntegrationTest
  setup do
    post games_path
    @game = Game.order(:id).last
    follow_redirect!
  end

  def play_first_placement
    post game_moves_path(@game), params: { seq: @game.reload.state_seq, kind: "draw" }
    options = @game.reload.engine.legal_placements.flat_map do |tile, faces|
      faces.flat_map { |face, rotations| rotations.flat_map { |rotation, cells| cells.map { [ tile, face, rotation, it ] } } }
    end
    tile, face, rotation, (row, col) = options.first
    post game_moves_path(@game), params: { seq: @game.reload.state_seq, kind: "place", tile:, face:, rotation:, row:, col: }
  end

  test "the lobby offers to play here instead" do
    assert_select "form[action=?] button#play-here", game_hot_seat_path(@game)
  end

  test "playing here starts the game with Player 1 and Player 2 on one screen" do
    post game_hot_seat_path(@game)
    follow_redirect!

    first = @game.reload.first_seat
    assert_select "#status", "Player #{first}'s turn. Draw from the bag."
    assert_select "#me-name", /Player #{first}/
    assert_select "#opponent .who", /Player #{Rules.opponent(first)}/
    assert_select "#presence", false
    assert_select "#status.turn-bar.seat[data-turn-cue-alert-value=?]", "player-#{first}"
    assert_select ".turn-tag", false
    assert_select "title", "CatDog"
  end

  test "after a turn the other player is at the bottom and can move" do
    post game_hot_seat_path(@game)
    first = @game.reload.first_seat
    play_first_placement
    get game_path(@game)

    second = Rules.opponent(first)
    assert_select "#status", "Player #{second}'s turn. Draw from the bag."
    assert_select "#me-name", /Player #{second}/
    assert_select "#status[data-turn-cue-alert-value=?]", "player-#{second}"
    post game_moves_path(@game), params: { seq: @game.reload.state_seq, kind: "draw" }
    assert_equal second, @game.moves.last.seat_position
  end

  test "resign resigns for the player on turn" do
    post game_hot_seat_path(@game)
    first = @game.reload.first_seat
    post game_moves_path(@game), params: { seq: 0, kind: "resign" }
    follow_redirect!

    assert_equal first, @game.moves.last.seat_position
    assert_select "#status", "Player #{Rules.opponent(first)} won. Player #{first} resigned."
  end

  test "rematch starts the next hot-seat game in one click" do
    post game_hot_seat_path(@game)
    post game_moves_path(@game), params: { seq: 0, kind: "resign" }
    follow_redirect!
    assert_select "form[action=?] button", game_rematch_path(@game), text: "Rematch"

    post game_rematch_path(@game)
    follow_redirect!
    rematch = @game.reload.rematch_game
    assert_redirected_to game_path(rematch)
    follow_redirect!
    assert_select "#status", /Player \d's turn/
  end

  test "a visitor sees the full page once the game is hot-seat" do
    post game_hot_seat_path(@game)
    visitor = open_session
    visitor.get game_path(@game)

    visitor.assert_response :forbidden
  end
end
