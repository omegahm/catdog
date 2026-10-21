class Game < ApplicationRecord
  class StaleMove < StandardError; end

  has_many :seats, -> { order(:position) }, dependent: :destroy
  has_many :moves, -> { order(:seq) }, dependent: :delete_all

  enum :status, %w[lobby playing ended].index_by(&:itself), validate: true

  validates :first_seat, :turn_seat, inclusion: { in: Rules::SEATS }, allow_nil: true

  def tile_set = Rules::TileSet.cached(*tile_sets)

  def start!(first_seat: Rules::SEATS.sample(random: SecureRandom))
    raise Rules::IllegalMove, "the game has already started" unless lobby?

    engine = Rules::Game.start(tile_set, first_seat:)
    update!(status: "playing", first_seat:, turn_seat: first_seat, state: engine.state.as_json, state_seq: 0)
  end

  def engine
    last_seq = moves.maximum(:seq) || 0
    return replay if state.nil? || state_seq != last_seq

    Rules::Game.new(tile_set, Rules::State.from_h(state))
  end

  def replay
    Rules::Game.replay(tile_set, first_seat:, moves: moves.map(&:to_rule))
  end

  def play!(seat_position:, kind:, seq:, data: {})
    transaction do
      reload
      raise StaleMove, "the page is behind move #{state_seq}" unless seq == state_seq
      raise Rules::IllegalMove, "the game is not being played" unless playing?

      current = engine
      data = { tiles: current.draw_tiles } if kind.to_s == "draw"
      move = Rules::Move.new(seat: seat_position, kind:, data:)
      after = current.apply(move)

      moves.create!(seq: seq + 1, seat_position:, kind: move.kind, data: move.data)
      update!(
        state: after.state.as_json,
        state_seq: seq + 1,
        status: after.ended? ? "ended" : "playing",
        turn_seat: after.turn,
        winner_seat: after.winner
      )
      after
    end
  rescue ActiveRecord::RecordNotUnique
    raise StaleMove, "another move took seq #{seq + 1}"
  end
end
