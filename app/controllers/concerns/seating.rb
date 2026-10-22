module Seating
  extend ActiveSupport::Concern

  COOKIE_LIMIT = 2_000

  included do
    helper_method :seat_token_for

    rescue_from Game::NotAllowed do |error|
      redirect_to @game, alert: error.message, status: :see_other
    end
  end

  private

  def set_game
    @game = Game.find_by!(public_id: params[:game_id] || params[:id])
  end

  def require_seat
    @seat = seat_for(@game) or head :forbidden
  end

  def new_seat_token = SecureRandom.base58(32)

  def seat_tokens
    tokens = cookies.encrypted[:seats]
    tokens.is_a?(Hash) ? tokens : {}
  end

  def seat_token_for(game) = seat_tokens[game.id.to_s]

  def seat_for(game)
    token = seat_token_for(game)
    token && game.seats.find_by_token(token)
  end

  def remember_seat(game, token)
    tokens = seat_tokens.merge(game.id.to_s => token)
    others = tokens.keys - [ game.id.to_s ]
    ended = Game.ended.where(id: others).order(:id).pluck(:id).map(&:to_s)
    droppable = ended + (others - ended).sort_by(&:to_i)
    tokens = tokens.except(droppable.shift) while tokens.to_json.bytesize > COOKIE_LIMIT && droppable.any?
    cookies.encrypted.permanent[:seats] = { value: tokens, httponly: true, same_site: :lax }
  end
end
