require "test_helper"

module Rules
  class PlayoutTest < ActiveSupport::TestCase
    include RulesHelper

    GAMES = 50
    BATCHES = 5
    SEED = Integer(ENV.fetch("PLAYOUT_SEED", Random.new_seed))

    def random_move(game, random)
      seat = game.turn
      return move(Rules.opponent(seat), :end_game, reason: "resign") if random.rand < 0.002

      case game.phase
      when "awaiting_draw"
        return move(seat, :play_reserve) if game.can_play_reserve? && random.rand < 0.4

        move(seat, :draw, tiles: game.draw_tiles(random:))
      when "awaiting_place"
        options = game.legal_placements.flat_map do |tile, faces|
          faces.flat_map { |face, rotations| rotations.flat_map { |rotation, cells| cells.map { [ tile, face, rotation, it ] } } }
        end
        tile, face, rotation, cell = options.sample(random:)
        place(seat, tile, cell, face:, rotation:)
      when "awaiting_species"
        move(seat, :choose_species, species: SPECIES.sample(random:))
      when "awaiting_reserve_action"
        take = (game.state.discard + [ nil ]).sample(random:)
        move(seat, :reserve_action, **(take ? { take: } : {}))
      end
    end

    def check_invariants(game, tile_set, first_seat, moves)
      all_tiles = game.state.board.values.map(&:tile_id) + game.state.bag + game.state.discard + game.state.reserves.values.compact + game.state.drawn

      assert_equal tile_set.ids.sort, all_tiles.sort, "every tile is in exactly one place"
      assert_equal [], board_problems(game.board)
      assert_equal game.state, Game.replay(tile_set, first_seat:, moves:).state, "replay gives the cached state"
      assert_equal game.state, State.from_h(JSON.parse(game.state.to_json))
    end

    BATCHES.times do |batch|
      test "random games #{batch * GAMES / BATCHES + 1} to #{(batch + 1) * GAMES / BATCHES} keep the invariants" do
        play_random_games(batch * GAMES / BATCHES, GAMES / BATCHES)
      end
    end

    def play_random_games(first, count)
      tile_set = TileSet.load
      count.times do |offset|
        seed = SEED + first + offset
        random = Random.new(seed)
        first_seat = SEATS.sample(random:)
        game = Game.start(tile_set, first_seat:)
        moves = []
        until game.ended?
          moves << random_move(game, random)
          game = game.apply(moves.last)
          check_invariants(game, tile_set, first_seat, moves)
        end
        assert_includes [ 1, 2, nil ], game.winner
      rescue Minitest::Assertion, StandardError => e
        raise e.class, "playout with PLAYOUT_SEED=#{seed} failed after #{moves.size} moves: #{e.message}", e.backtrace
      end
    end
  end
end
