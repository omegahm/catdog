class Seat < ApplicationRecord
  belongs_to :game

  validates :position, inclusion: { in: Rules::SEATS }, uniqueness: { scope: :game_id }
  validates :token_digest, presence: true, uniqueness: { scope: :game_id }

  def self.digest(token) = Digest::SHA256.hexdigest(token)

  def self.find_by_token(token) = token.present? ? find_by(token_digest: digest(token)) : nil

  def token=(token)
    self.token_digest = self.class.digest(token)
  end
end
