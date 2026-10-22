class Seat < ApplicationRecord
  belongs_to :game
  has_many :presences, dependent: :delete_all

  validates :position, inclusion: { in: Rules::SEATS }, uniqueness: { scope: :game_id }
  validates :token_digest, presence: true, uniqueness: { scope: :game_id }

  def self.digest(token) = Digest::SHA256.hexdigest(token)

  def self.find_by_token(token) = token.present? ? find_by(token_digest: digest(token)) : nil

  def seen_ago
    last_seen_at = presences.maximum(:last_seen_at)
    last_seen_at && (Time.current - last_seen_at).round
  end

  def online? = seen_ago.present? && seen_ago < Presence::TIMEOUT

  def token=(token)
    self.token_digest = self.class.digest(token)
  end
end
