class Presence < ApplicationRecord
  TIMEOUT = 75.seconds

  belongs_to :seat

  scope :stale, -> { where(last_seen_at: ...TIMEOUT.ago) }
end
