class Game < ApplicationRecord
  class StaleMove < StandardError; end
  class NotAllowed < StandardError; end

  has_secure_token :public_id
  has_many :seats, -> { order(:position) }, dependent: :destroy
  has_many :moves, -> { order(:seq) }, dependent: :delete_all
  belongs_to :rematch_game, class_name: "Game", optional: true

  broadcasts_refreshes

  enum :status, %w[lobby playing ended].index_by(&:itself), validate: true

  validates :first_seat, :turn_seat, inclusion: { in: Rules::SEATS }, allow_nil: true

  def self.create_with_seat!(token)
    transaction { create!.tap { it.seats.create!(position: 1, token:) } }
  end

  def to_param = public_id

  def tile_set = Rules::TileSet.cached(*tile_sets)

  def join!(token)
    transaction do
      reload
      raise NotAllowed, "the game is full" unless lobby? && seats.size < 2

      seats.create!(position: 2, token:)
      start!
    end
  rescue ActiveRecord::RecordNotUnique
    raise NotAllowed, "the game is full"
  end

  def offer_rematch!(position)
    raise NotAllowed, "a rematch is already offered" unless ended? && rematch_offered_by.nil? && rematch_game.nil?

    update!(rematch_offered_by: position)
  end

  def withdraw_rematch!(position)
    raise NotAllowed, "you have not offered a rematch" unless rematch_offered_by == position && rematch_game.nil?

    update!(rematch_offered_by: nil)
  end

  def accept_rematch!(position)
    transaction do
      reload
      raise NotAllowed, "there is no rematch offer to accept" unless rematch_offered_by == Rules.opponent(position) && rematch_game.nil?

      Game.create!(tile_sets:).tap do |rematch|
        seats.each { rematch.seats.create!(position: it.position, token_digest: it.token_digest) }
        rematch.start!
        update!(rematch_game: rematch)
      end
    end
  end

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
    play_moves!(seat_position:, seq:, steps: [ [ kind, data ] ])
  end

  def play_moves!(seat_position:, seq:, steps:)
    transaction do
      reload
      raise StaleMove, "the page is behind move #{state_seq}" unless seq == state_seq
      raise Rules::IllegalMove, "the game is not being played" unless playing?

      after = steps.each_with_index.reduce(engine) do |current, ((kind, data), index)|
        data = { tiles: current.draw_tiles } if kind.to_s == "draw"
        move = Rules::Move.new(seat: seat_position, kind:, data:)
        current.apply(move).tap do
          moves.create!(seq: seq + index + 1, seat_position:, kind: move.kind, data: move.data)
        end
      end
      update!(
        state: after.state.as_json,
        state_seq: seq + steps.size,
        status: after.ended? ? "ended" : "playing",
        turn_seat: after.turn,
        winner_seat: after.winner
      )
      after
    end
  rescue ActiveRecord::RecordNotUnique
    raise StaleMove, "another move took seq #{seq + 1}"
  end

  def last_placed_cell = moves.where(kind: "place").last&.data&.fetch("cell")
end
