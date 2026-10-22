require "test_helper"

class PlaytestReportTest < ActiveSupport::TestCase
  def play_random_game(random)
    game = Game.create_with_seat!(SecureRandom.hex)
    game.join!(SecureRandom.hex)
    game.reload
    until game.ended?
      engine = game.engine
      kind, data =
        case engine.phase
        when "awaiting_draw" then [ "draw", {} ]
        when "awaiting_place"
          options = engine.legal_placements.flat_map do |tile, faces|
            faces.flat_map { |face, rotations| rotations.flat_map { |rotation, cells| cells.map { { tile:, face:, rotation:, cell: it } } } }
          end
          [ "place", options.sample(random:) ]
        when "awaiting_species" then [ "choose_species", { species: Rules::SPECIES.sample(random:) } ]
        when "awaiting_reserve_action" then [ "reserve_action", { take: (engine.state.discard + [ nil ]).sample(random:) } ]
        end
      game.play!(seat_position: engine.acting_seat, kind:, seq: game.state_seq, data:)
    end
    game
  end

  test "the report says so when no game has started" do
    Game.create_with_seat!("lonely")

    assert_includes PlaytestReport.new.to_markdown, "No started games yet."
  end

  test "the report counts endings, animals and the reserve from the move log" do
    random = Random.new(11)
    games = 3.times.map { play_random_game(random) }
    resigned = Game.create_with_seat!(SecureRandom.hex).tap { it.join!(SecureRandom.hex) }.reload
    resigned.play!(seat_position: 2, kind: "resign", seq: 0)
    open = Game.create_with_seat!(SecureRandom.hex).tap { it.join!(SecureRandom.hex) }
    report = PlaytestReport.new.to_markdown

    endings = games.map { it.engine.state.ending["reason"] }.tally
    lengths = games.flat_map { it.engine.animals.select(&:complete?).map(&:length) }
    actions = games.flat_map { it.moves.where(kind: "reserve_action").to_a }
    assert_includes report, "Started games: 5 (4 ended, 1 still open)"
    assert_includes report, "| Bag ran out | #{endings.fetch("bag_exhausted", 0)} |"
    assert_includes report, "| Neither drawn tile fits | #{endings.fetch("stuck", 0)} |"
    assert_includes report, "| Resigned | 1 |"
    assert_includes report, "| 2 | #{lengths.count(2)} |"
    assert_includes report, "Reserve actions: #{actions.size} ("
    assert_includes report, "skip #{actions.count { it.data["take"].nil? }})"
    assert_includes report, "Scored games (not resigned): 3."
    assert open.reload.playing?
  end

  test "the comparison table includes both simulation rows" do
    play_random_game(Random.new(5))
    report = PlaytestReport.new.to_markdown

    assert_includes report, "| random bots | 35.0 | 28% | 72% | 6.9 |"
    assert_includes report, "| greedy bots | 36.9 | 64% | 36% | 14.4 |"
  end
end
