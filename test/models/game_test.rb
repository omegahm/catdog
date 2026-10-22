require "test_helper"

class GameTest < ActiveSupport::TestCase
  def started(first_seat: 1)
    Game.create!.tap { it.start!(first_seat:) }
  end

  def first_placement(game)
    options = game.engine.legal_placements.flat_map do |tile, faces|
      faces.flat_map { |face, rotations| rotations.flat_map { |rotation, cells| cells.map { { tile:, face:, rotation:, cell: it } } } }
    end
    options.first
  end

  test "starting a game writes the initial state for the first seat" do
    game = started(first_seat: 2)

    assert game.playing?
    assert_equal [ 2, 2, 0 ], [ game.first_seat, game.turn_seat, game.state_seq ]
    assert_equal 44, game.state["bag"].size
    assert_raises(Rules::IllegalMove) { game.start! }
  end

  test "the first seat is random" do
    assert_equal [ 1, 2 ], 20.times.map { Game.create!.tap(&:start!).first_seat }.uniq.sort
  end

  test "a draw records the tile ids the server picked" do
    game = started
    after = game.play!(seat_position: 1, kind: "draw", seq: 0, data: { tiles: [ "base-01", "base-02" ] })
    move = game.moves.sole

    assert_equal [ 1, 1, "draw" ], [ move.seq, move.seat_position, move.kind ]
    assert_equal after.state.drawn, move.data["tiles"]
    assert_equal 2, move.data["tiles"].uniq.size
    assert_equal 1, game.state_seq
    assert_equal after.state.as_json, game.state
  end

  test "each move appends one row and keeps the cache equal to the replay" do
    game = started
    game.play!(seat_position: 1, kind: "draw", seq: 0)
    game.play!(seat_position: 1, kind: "place", seq: 1, data: first_placement(game))

    assert_equal [ 1, 2 ], game.moves.map(&:seq)
    assert_equal 2, game.turn_seat
    assert_equal game.replay.state.as_json, game.state
  end

  test "a move posted with a stale seq is rejected and writes nothing" do
    game = started
    game.play!(seat_position: 1, kind: "draw", seq: 0)

    assert_raises(Game::StaleMove) { game.play!(seat_position: 1, kind: "draw", seq: 0) }
    assert_equal 1, game.moves.count
  end

  test "a second tab with an old copy of the game cannot take the same seq" do
    game = started
    other_tab = Game.find(game.id)
    game.play!(seat_position: 1, kind: "draw", seq: 0)

    assert_raises(Game::StaleMove) { other_tab.play!(seat_position: 1, kind: "draw", seq: 0) }
    assert_equal 1, game.moves.count
  end

  test "the unique index guards seq" do
    game = started
    game.moves.create!(seq: 1, seat_position: 1, kind: "draw", data: { tiles: [] })

    assert_raises(ActiveRecord::RecordNotUnique) { game.moves.create!(seq: 1, seat_position: 1, kind: "draw", data: { tiles: [] }) }
  end

  test "an illegal move writes nothing" do
    game = started

    assert_raises(Rules::IllegalMove) { game.play!(seat_position: 2, kind: "draw", seq: 0) }
    assert_raises(Rules::IllegalMove) { game.play!(seat_position: 1, kind: "place", seq: 0, data: { tile: "base-01", face: "front", rotation: 0, cell: [ 3, 3 ] }) }
    assert_equal [ 0, 0 ], [ game.moves.count, game.reload.state_seq ]
  end

  test "moves cannot be played before the game starts" do
    assert_raises(Rules::IllegalMove) { Game.create!.play!(seat_position: 1, kind: "draw", seq: 0) }
  end

  test "a cache that does not match the log is rebuilt from the moves" do
    game = started
    game.play!(seat_position: 1, kind: "draw", seq: 0)
    drawn = game.state["drawn"]
    game.update_columns(state: Rules::State.initial(game.tile_set, 1).as_json, state_seq: 0)

    assert_equal drawn, game.engine.state.drawn
  end

  test "moves are append-only" do
    game = started
    game.play!(seat_position: 1, kind: "draw", seq: 0)
    move = game.moves.sole

    assert_raises(ActiveRecord::ReadOnlyRecord) { move.update!(kind: "place") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { move.destroy! }
  end

  test "resigning ends the game and records the winner" do
    game = started
    game.play!(seat_position: 2, kind: "resign", seq: 0)

    assert game.ended?
    assert_equal 1, game.winner_seat
    assert_raises(Rules::IllegalMove) { game.play!(seat_position: 1, kind: "draw", seq: 1) }
  end

  test "a full random game through the database replays to the cached state" do
    random = Random.new(7)
    game = started
    until game.ended?
      engine = game.engine
      kind, data =
        case engine.phase
        when "awaiting_draw" then [ "draw", {} ]
        when "awaiting_place" then [ "place", first_placement(game) ]
        when "awaiting_species" then [ "choose_species", { species: Rules::SPECIES.sample(random:) } ]
        when "awaiting_reserve_action" then [ "reserve_action", { take: engine.state.discard.sample(random:) } ]
        end
      game.play!(seat_position: engine.turn, kind:, seq: game.state_seq, data:)
    end

    assert_equal game.replay.state.as_json, game.state
    assert_equal game.state_seq, game.moves.last.seq
  end
end
