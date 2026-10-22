class Move < ApplicationRecord
  belongs_to :game

  validates :seq, numericality: { only_integer: true, greater_than: 0 }
  validates :seat_position, inclusion: { in: Rules::SEATS }
  validates :kind, presence: true

  def readonly? = persisted?

  def to_rule = Rules::Move.new(seat: seat_position, kind:, data:)
end
