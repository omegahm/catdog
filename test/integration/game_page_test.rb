require "test_helper"
require "turbo/broadcastable/test_helper"

class GamePageTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    @host = open_session
    @host.post games_path
    @game = Game.order(:id).last
    @guest = open_session
    @guest.post game_join_path(@game)
    @game.reload
    @mover, @waiter = @game.first_seat == 1 ? [ @host, @guest ] : [ @guest, @host ]
  end

  def placement(state)
    Rules::Board::Placement.new(tile_id: state[0], face: state[1], rotation: state[2])
  end

  def set_state(**changes)
    tile_set = @game.tile_set
    state = Rules::State.initial(tile_set, @game.first_seat)
    changes[:board] = changes.fetch(:board, {}).transform_values { placement(it) }
    used = changes[:board].values.map(&:tile_id) + changes.fetch(:drawn, []) + changes.fetch(:discard, [])
    @game.update_columns(state: state.with(bag: state.bag - used, **changes).as_json)
  end

  def post_move(browser, **params)
    browser.post game_moves_path(@game), params: { seq: @game.reload.state_seq, **params }
  end

  def texts(browser, selector) = browser.css_select(selector).map { it.text.strip }

  def legal_value(browser)
    JSON.parse(browser.css_select("[data-controller~='board']").sole["data-board-legal-value"])
  end

  test "the game page shows the board and a turn line for each seat" do
    @mover.get game_path(@game)
    @waiter.get game_path(@game)

    @mover.assert_select "#board .cell", 49
    @mover.assert_select "#status", "Your turn. Draw from the bag."
    @mover.assert_select "button#bag", text: /44/
    @waiter.assert_select "#status", "Opponent's turn."
    @waiter.assert_select "button#bag", false
    @mover.assert_select "turbo-cable-stream-source", 1
  end

  test "the turn bar, the active strip and the page title show whose turn it is" do
    @mover.get game_path(@game)
    @waiter.get game_path(@game)

    @mover.assert_select ".sticky #status.turn-bar.mine[data-turn-cue-alert-value=you]"
    @mover.assert_select "#me.strip.active .turn-tag", "▶ Your turn"
    @mover.assert_select "#opponent.strip.active", false
    @mover.assert_select "title", "● Your turn – CatDog"
    @waiter.assert_select "#status.turn-bar:not(.mine)[data-turn-cue-alert-value='']"
    @waiter.assert_select "#opponent.strip.active"
    @waiter.assert_select ".turn-tag", false
    @waiter.assert_select "title", "CatDog"
  end

  test "drawing shows both faces of both drawn tiles to the mover and the tiles to the opponent" do
    post_move(@mover, kind: "draw")
    @mover.follow_redirect!
    drawn = @game.reload.state["drawn"]

    @mover.assert_select "#drawn .hand", 4
    assert_equal drawn, legal_value(@mover).keys
    @waiter.get game_path(@game)
    @waiter.assert_select "#opponent .dtile", 2
    assert_equal({}, legal_value(@waiter))
  end

  test "a move broadcasts a refresh to the game stream" do
    perform_enqueued_jobs { post_move(@mover, kind: "draw") }

    assert_turbo_stream_broadcasts @game
  end

  test "placing a drawn tile writes the move and passes the turn" do
    post_move(@mover, kind: "draw")
    tile, faces = @game.reload.engine.legal_placements.find { |_, faces| faces.values.flat_map(&:values).any?(&:any?) }
    face, rotations = faces.find { |_, rotations| rotations.values.any?(&:any?) }
    rotation, cells = rotations.find { |_, cells| cells.any? }
    post_move(@mover, kind: "place", tile:, face:, rotation:, row: cells.first[0], col: cells.first[1])

    assert_equal %w[draw place], @game.moves.map(&:kind)
    @waiter.get game_path(@game)
    @waiter.assert_select "#status", "Your turn. Draw from the bag."
    @waiter.assert_select "#cell-#{cells.first[0]}-#{cells.first[1]}.filled.last"
  end

  test "a stale seq refreshes the page without an error" do
    post_move(@mover, kind: "draw")
    @mover.post game_moves_path(@game), params: { seq: 0, kind: "draw" }
    @mover.follow_redirect!

    assert_equal 1, @game.moves.count
    @mover.assert_select ".alert", false
  end

  test "a move out of turn is refused with a message" do
    post_move(@waiter, kind: "draw")
    @waiter.follow_redirect!

    assert_equal 0, @game.moves.count
    @waiter.assert_select ".alert", /turn of seat/
  end

  test "a visitor without a seat cannot post moves" do
    open_session.tap { it.post game_moves_path(@game), params: { seq: 0, kind: "draw" } }.assert_response :forbidden
  end

  test "bad move parameters are refused" do
    post_move(@mover, kind: "dance")
    post_move(@mover, kind: "place", tile: "base-01", face: "front", rotation: "x", row: 3, col: 3)

    assert_equal 0, @game.moves.count
  end

  test "a completing placement offers the reserve action and taking a tile fills the reserve" do
    set_state(board: { [ 3, 3 ] => [ "base-35", "front", 0 ] }, drawn: %w[base-40 base-01], phase: "awaiting_place")
    post_move(@mover, kind: "place", tile: "base-40", face: "back", rotation: 180, row: 4, col: 3)
    @mover.follow_redirect!

    @mover.assert_select "#status", /Take a tile from the discard pile/
    @mover.assert_select "#discard .dtile.pick[data-tile=?]", "base-01"
    @mover.assert_select "#skip"

    post_move(@mover, kind: "reserve_action", take: "base-01")
    assert_equal "base-01", @game.reload.state.dig("reserves", @game.first_seat.to_s)
  end

  test "skipping the reserve action sends the discard pile back to the bag" do
    set_state(board: { [ 3, 3 ] => [ "base-35", "front", 0 ] }, drawn: %w[base-40 base-01], phase: "awaiting_place")
    post_move(@mover, kind: "place", tile: "base-40", face: "back", rotation: 180, row: 4, col: 3)
    post_move(@mover, kind: "reserve_action")

    assert_includes @game.reload.state["bag"], "base-01"
    assert_equal "awaiting_draw", @game.state["phase"]
  end

  test "completing a cat and a dog first offers the species choice" do
    set_state(
      board: { [ 2, 3 ] => [ "base-35", "front", 0 ], [ 4, 3 ] => [ "base-36", "back", 180 ] },
      drawn: %w[base-30 base-01],
      phase: "awaiting_place"
    )
    post_move(@mover, kind: "place", tile: "base-30", face: "front", rotation: 0, row: 3, col: 3)
    @mover.follow_redirect!
    @mover.assert_select "button", "Play as cat"

    post_move(@mover, kind: "choose_species", species: "cat")
    assert_equal "cat", @game.reload.state.dig("species", @game.first_seat.to_s)
  end

  test "placing the reserve tile from the draw phase plays the reserve and places in one step" do
    set_state(board: { [ 3, 3 ] => [ "base-35", "front", 0 ] }, reserves: { @game.first_seat => "base-40", Rules.opponent(@game.first_seat) => nil })
    @mover.get game_path(@game)
    @mover.assert_select "#reserve-slot .hand", 2
    @mover.assert_select "#draw-form[data-auto-draw-enabled-value=?]", "false"

    post_move(@mover, kind: "place", tile: "base-40", face: "back", rotation: 180, row: 4, col: 3)

    assert_equal %w[play_reserve place], @game.moves.map(&:kind)
    assert_nil @game.reload.state.dig("reserves", @game.first_seat.to_s)
  end

  test "the draw form asks for auto-draw when there is no playable reserve tile" do
    @mover.get game_path(@game)

    @mover.assert_select "#draw-form[data-controller=auto-draw][data-auto-draw-enabled-value=?]", "true"
  end

  test "tile faces are drawn from the sprite sheet in both art styles" do
    @mover.get game_path(@game)

    @mover.assert_select "svg defs g#fur-cat-head"
    @mover.assert_select "svg defs g#line-dog-turn"
    @mover.assert_select "svg defs g#fur-gap"
  end

  test "either player can resign, also on the opponent's turn, and the opponent wins" do
    @waiter.get game_path(@game)
    @waiter.assert_select "form button#resign"
    post_move(@waiter, kind: "resign")

    @game.reload
    assert @game.ended?
    assert_equal Rules.opponent(@game.moves.last.seat_position), @game.winner_seat
    assert_equal "resign", @game.moves.last.kind
    @waiter.follow_redirect!
    @waiter.assert_select "#status", "Opponent won."
    @waiter.assert_select "#status.mine", false
    @waiter.assert_select "#status.won", false
    @waiter.assert_select "#result-reason", "You resigned."
    @waiter.assert_select "#score", false
    @waiter.assert_select ".strip.active", false
    @waiter.assert_select "title", "CatDog"
    @waiter.assert_select "#resign", false
  end

  test "the result panel shows the reason and the points for each length" do
    seat = @game.first_seat
    set_state(
      board: { [ 3, 3 ] => [ "base-35", "front", 0 ], [ 4, 3 ] => [ "base-40", "back", 180 ] },
      species: { seat => "dog", Rules.opponent(seat) => "cat" },
      phase: "ended", ending: { "reason" => "bag_exhausted" }
    )
    @game.update_columns(status: "ended")
    @mover.get game_path(@game)
    @waiter.get game_path(@game)

    @mover.assert_select "#status.turn-bar.won[data-turn-cue-ended-value=true]", "You won."
    @mover.assert_select "#result-reason", "The bag holds fewer than two tiles."
    assert_equal [ "", "You", "Opponent", "Point" ], texts(@mover, "#score thead th")
    @mover.assert_select "#score tbody tr", 1
    @mover.assert_select "#score tbody tr th", "Length 2"
    assert_equal [ "1", "0", "● You" ], texts(@mover, "#score tbody tr td")
    assert_equal [ "1", "0", "" ], texts(@mover, "#score tfoot td")
    @mover.assert_select "#tiebreak", false
    @mover.assert_select "#result #rematch"
    @waiter.assert_select "#status.won", false
    @waiter.assert_select "#status", "Opponent won."
    assert_equal [ "0", "1", "● Opponent" ], texts(@waiter, "#score tbody tr td")
  end

  test "an ended game with no complete animals shows a draw" do
    set_state(phase: "ended", ending: { "reason" => "stuck" })
    @game.update_columns(status: "ended")
    @mover.get game_path(@game)

    @mover.assert_select "#status", "The game is a draw."
    @mover.assert_select "#result-reason", "Neither drawn tile has a legal placement."
    @mover.assert_select "#result", /No complete animals/
    @mover.assert_select "#score", false
  end

  test "the opponent indicator shows online or offline from the presence rows" do
    opponent_seat = @game.seats.find_by(position: @game.first_seat == 1 ? 2 : 1)
    @mover.get game_path(@game)
    @mover.assert_select "#presence", "○ offline"

    opponent_seat.presences.create!(connection_id: "x", last_seen_at: Time.current)
    @mover.get game_path(@game)
    @mover.assert_select "#presence.online", "● online"
  end

  test "completing the opponent's animal gives the opponent the reserve action" do
    first = @game.first_seat
    second = Rules.opponent(first)
    set_state(
      board: { [ 3, 3 ] => [ "base-35", "front", 0 ] },
      drawn: %w[base-40 base-01],
      phase: "awaiting_place",
      species: { first => "cat", second => "dog" }
    )
    post_move(@mover, kind: "place", tile: "base-40", face: "back", rotation: 180, row: 4, col: 3)

    @mover.follow_redirect!
    @mover.assert_select "#status", "Opponent takes a tile into their reserve, or skips."
    @mover.assert_select "#discard .dtile.pick", false
    @waiter.get game_path(@game)
    @waiter.assert_select "#status", "Opponent completed one of your animals. Take a tile from the discard pile into your reserve, or skip."
    @waiter.assert_select "#discard .dtile.pick[data-tile=?]", "base-01"

    post_move(@waiter, kind: "reserve_action", take: "base-01")
    @game.reload
    assert_equal "base-01", @game.state.dig("reserves", second.to_s)
    assert_equal second, @game.turn_seat
    assert_equal "awaiting_draw", @game.state["phase"]
  end

  test "games from before the rule change keep rules version 1" do
    @game.update_columns(rules_version: 1)
    first = @game.first_seat
    set_state(
      board: { [ 3, 3 ] => [ "base-35", "front", 0 ] },
      drawn: %w[base-40 base-01],
      phase: "awaiting_place",
      species: { first => "cat", Rules.opponent(first) => "dog" }
    )
    post_move(@mover, kind: "place", tile: "base-40", face: "back", rotation: 180, row: 4, col: 3)
    @mover.follow_redirect!

    @mover.assert_select "#status", /You completed an animal/
  end
end
