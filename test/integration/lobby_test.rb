require "test_helper"

class LobbyTest < ActionDispatch::IntegrationTest
  def create_game(browser)
    browser.post games_path
    Game.order(:id).last
  end

  def join(game)
    open_session.tap { it.post game_join_path(game) }
  end

  def seat_link(browser)
    browser.css_select("#seat-link").sole["value"]
  end

  test "the home page has a New game button" do
    get root_path

    assert_select "form[action=?] button", games_path, text: "New game"
  end

  test "creating a game takes seat 1 and shows the invite link" do
    host = open_session
    game = create_game(host)

    host.assert_redirected_to game_path(game)
    host.follow_redirect!
    host.assert_select "#invite-link[value=?]", game_url(game)
    host.assert_select "#status", "Waiting for your opponent."
    assert_equal [ 1 ], game.seats.map(&:position)
    assert game.lobby?
  end

  test "a visitor sees a Join button and a GET never takes a seat" do
    game = create_game(open_session)
    guest = open_session
    guest.get game_path(game)

    guest.assert_select "form[action=?] button", game_join_path(game), text: "Join game"
    guest.assert_select "#invite-link", false
    assert_equal 1, game.seats.count
  end

  test "joining takes seat 2 and starts the game with a random first player" do
    host = open_session
    game = create_game(host)
    guest = join(game)

    guest.assert_redirected_to game_path(game)
    game.reload
    assert game.playing?
    assert_includes Rules::SEATS, game.first_seat
    assert_equal [ 1, 2 ], game.seats.map(&:position)

    guest.follow_redirect!
    host.get game_path(game)
    statuses = [ host, guest ].map { it.css_select("#status").text.strip }
    assert_equal [ "Opponent's turn.", "Your turn. Draw from the bag." ], statuses.sort
  end

  test "a seat holder who posts join keeps the seat and takes no other" do
    host = open_session
    game = create_game(host)
    host.post game_join_path(game)

    assert_equal 1, game.seats.count
    assert game.reload.lobby?
  end

  test "a third visitor sees a full page with no game information" do
    game = create_game(open_session)
    join(game)
    third = open_session
    third.get game_path(game)

    third.assert_response :forbidden
    third.assert_select "#status", "This game is full."
    third.assert_select "#invite-link, #seat-link", false

    third.post game_join_path(game)
    third.assert_response :forbidden
    assert_equal 2, game.seats.count
  end

  test "the seat link opens the seat on another device and redirects to the clean URL" do
    host = open_session
    game = create_game(host)
    host.follow_redirect!
    link = seat_link(host)

    phone = open_session
    phone.get link
    phone.assert_redirected_to game_path(game)
    phone.follow_redirect!
    phone.assert_select "#status", "Waiting for your opponent."
    assert_equal 1, game.seats.count
  end

  test "a seat link with a wrong token opens no seat" do
    game = create_game(open_session)
    phone = open_session
    phone.get game_seat_link_path(game, token: "wrong")
    phone.follow_redirect!

    phone.assert_select "form[action=?]", game_join_path(game)
  end

  test "a seat token works only for its own game" do
    host = open_session
    game = create_game(host)
    host.follow_redirect!
    token = Rack::Utils.parse_query(URI(seat_link(host)).query).fetch("token")
    other = create_game(open_session)

    phone = open_session
    phone.get game_seat_link_path(other, token:)
    phone.follow_redirect!
    phone.assert_select "form[action=?]", game_join_path(other)
  end

  test "a rematch is offered, withdrawn, offered again and accepted" do
    host = open_session
    game = create_game(host)
    guest = join(game)
    game.reload.play!(seat_position: 2, kind: "resign", seq: 0)

    host.get game_path(game)
    host.assert_select "#status", "You won. Opponent resigned."
    host.post game_rematch_path(game)
    assert_equal 1, game.reload.rematch_offered_by

    host.delete game_rematch_path(game)
    assert_nil game.reload.rematch_offered_by

    host.post game_rematch_path(game)
    guest.get game_path(game)
    guest.assert_select "#rematch", /Opponent offers a rematch/

    host.post game_rematch_acceptance_path(game)
    assert_nil game.reload.rematch_game

    guest.post game_rematch_acceptance_path(game)
    rematch = game.reload.rematch_game
    guest.assert_redirected_to game_path(rematch)
    assert rematch.playing?
    assert_equal game.seats.map(&:token_digest), rematch.seats.map(&:token_digest)

    host.get game_rematch_path(game)
    host.assert_redirected_to game_path(rematch)
    host.follow_redirect!
    host.assert_response :success
    host.assert_select "#status", /turn/
  end

  test "only seat holders can use the rematch link" do
    game = create_game(open_session)
    join(game)
    game.reload.play!(seat_position: 1, kind: "resign", seq: 0)

    outsider = open_session
    outsider.post game_rematch_path(game)
    outsider.assert_response :forbidden
    outsider.get game_rematch_path(game)
    outsider.assert_redirected_to game_path(game)
  end

  test "a rematch cannot be offered while the game is being played" do
    host = open_session
    game = create_game(host)
    join(game)
    host.post game_rematch_path(game)

    host.assert_redirected_to game_path(game)
    assert_nil game.reload.rematch_offered_by
  end

  test "ended games drop out of the cookie first when it grows" do
    host = open_session
    80.times do
      create_game(host)
      Game.order(:id).last.update_columns(status: "ended")
    end
    current = create_game(host)

    assert_operator host.cookies["seats"].bytesize, :<, 4_096
    host.get game_path(current)
    host.assert_select "#invite-link"
  end

  test "active games drop out oldest first when only active games are left" do
    host = open_session
    games = 80.times.map { create_game(host) }

    assert_operator host.cookies["seats"].bytesize, :<, 4_096
    host.get game_path(games.last)
    host.assert_select "#invite-link"
    host.get game_path(games.first)
    host.assert_select "form[action=?]", game_join_path(games.first)
  end
end
