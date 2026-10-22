module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :seat_tokens

    def connect
      tokens = cookies.encrypted[:seats]
      self.seat_tokens = tokens.is_a?(Hash) ? tokens : {}
    end
  end
end
