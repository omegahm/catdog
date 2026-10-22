require "securerandom"

module Rules
  class Game
    attr_reader :tile_set, :state

    def self.start(tile_set, first_seat:) = new(tile_set, State.initial(tile_set, first_seat))

    def self.replay(tile_set, first_seat:, moves:)
      moves.reduce(start(tile_set, first_seat:)) { |game, move| game.apply(move) }
    end

    def initialize(tile_set, state)
      @tile_set = tile_set
      @state = state
    end

    def board = @board ||= Board.new(tile_set, state.board)

    def phase = state.phase

    def turn = state.turn

    def ended? = phase == "ended"

    def animals = board.animals

    def score = Score.new(animals, state.species)

    def winner
      return unless ended?
      return Rules.opponent(state.ending.fetch("seat")) if state.ending.fetch("reason") == "resign"

      score.winner
    end

    def placeable_tiles
      case phase
      when "awaiting_draw" then [ state.reserves[turn] ].compact
      when "awaiting_place" then state.drawn
      else []
      end
    end

    def legal_placements = placeable_tiles.to_h { [ it, board.legal_placements(it) ] }

    def can_play_reserve?
      reserve = state.reserves[turn]
      phase == "awaiting_draw" && !reserve.nil? && board.placeable?(reserve)
    end

    def draw_tiles(random: SecureRandom)
      state.bag.size < 2 ? [] : state.bag.sample(2, random:)
    end

    def apply(move)
      raise IllegalMove, "the game has ended" if ended?
      raise IllegalMove, "unknown seat #{move.seat.inspect}" unless SEATS.include?(move.seat)

      next_state =
        if move.kind == "resign"
          resign(move)
        else
          raise IllegalMove, "it is the turn of seat #{turn}" unless move.seat == turn

          case move.kind
          when "draw" then draw(move.data)
          when "play_reserve" then play_reserve
          when "place" then place(move.data)
          when "choose_species" then choose_species(move.data)
          when "reserve_action" then reserve_action(move.data)
          else raise IllegalMove, "unknown move #{move.kind.inspect}"
          end
        end
      Game.new(tile_set, next_state)
    end

    private

    def expect_phase(expected)
      raise IllegalMove, "the game is in #{phase}, not #{expected}" unless phase == expected
    end

    def resign(move)
      state.with(phase: "ended", ending: { "reason" => "resign", "seat" => move.seat })
    end

    def draw(data)
      expect_phase "awaiting_draw"
      tiles = Array(data["tiles"])
      if state.bag.size < 2
        raise IllegalMove, "the bag holds fewer than two tiles" unless tiles.empty?

        return state.with(phase: "ended", ending: { "reason" => "bag_exhausted" })
      end
      raise IllegalMove, "draw two different tiles from the bag" unless tiles.size == 2 && tiles.uniq.size == 2 && (tiles - state.bag).empty?

      drawn = state.with(bag: state.bag - tiles, drawn: tiles)
      return drawn.with(phase: "ended", ending: { "reason" => "stuck" }) if tiles.none? { board.placeable?(it) }

      drawn.with(phase: "awaiting_place")
    end

    def play_reserve
      expect_phase "awaiting_draw"
      raise IllegalMove, "the reserve is empty" if state.reserves[turn].nil?
      raise IllegalMove, "the reserve tile has no legal placement" unless can_play_reserve?

      state.with(drawn: [ state.reserves[turn] ], reserves: state.reserves.merge(turn => nil), phase: "awaiting_place")
    end

    def place(data)
      expect_phase "awaiting_place"
      tile_id, face, rotation, cell = data.values_at("tile", "face", "rotation", "cell")
      raise IllegalMove, "#{tile_id.inspect} is not a tile you can place" unless state.drawn.include?(tile_id)
      raise IllegalMove, "unknown face #{face.inspect}" unless FACES.include?(face)
      raise IllegalMove, "unknown rotation #{rotation.inspect}" unless ROTATIONS.include?(rotation)
      raise IllegalMove, "bad cell #{cell.inspect}" unless cell.is_a?(Array) && cell.size == 2 && cell.all?(Integer)
      raise IllegalMove, "#{tile_id} cannot go on #{cell.inspect} with #{face} up at #{rotation}" unless board.legal?(tile_id, face, rotation, cell)

      placed = board.place(cell, tile_id, face, rotation)
      completed = placed.animals_at(cell).select(&:complete?).map(&:species).uniq
      after_completion(
        state.with(board: placed.placements, discard: state.discard + (state.drawn - [ tile_id ]), drawn: []),
        completed
      )
    end

    def after_completion(next_state, completed)
      return end_turn(next_state) if completed.empty?
      return offer_reserve_action(next_state) if next_state.species[turn]
      return next_state.with(phase: "awaiting_species") if completed.size > 1

      offer_reserve_action(assign_species(next_state, completed.first))
    end

    def choose_species(data)
      expect_phase "awaiting_species"
      species = data["species"]
      raise IllegalMove, "unknown species #{species.inspect}" unless SPECIES.include?(species)

      offer_reserve_action(assign_species(state, species))
    end

    def reserve_action(data)
      expect_phase "awaiting_reserve_action"
      take = data["take"]
      discard = state.discard
      reserves = state.reserves
      if take
        raise IllegalMove, "#{take.inspect} is not in the discard pile" unless discard.include?(take)

        discard = discard - [ take ] + [ reserves[turn] ].compact
        reserves = reserves.merge(turn => take)
      end
      end_turn(state.with(bag: (state.bag + discard).sort, discard: [], reserves:))
    end

    def assign_species(next_state, species)
      next_state.with(species: { turn => species, Rules.opponent(turn) => Rules.other_species(species) })
    end

    def offer_reserve_action(next_state)
      return end_turn(next_state) if next_state.discard.empty?

      next_state.with(phase: "awaiting_reserve_action")
    end

    def end_turn(next_state) = next_state.with(phase: "awaiting_draw", turn: Rules.opponent(turn))
  end
end
