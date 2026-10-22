class Games::RematchesController < ApplicationController
  include Seating

  before_action :set_game
  before_action :require_seat, except: :show

  def show
    if seat_for(@game) && @game.rematch_game
      remember_seat(@game.rematch_game, seat_token_for(@game))
      redirect_to @game.rematch_game
    else
      redirect_to @game
    end
  end

  def create
    @game.offer_rematch!(@seat.position)
    redirect_to @game.hot_seat? ? game_rematch_path(@game) : @game, status: :see_other
  end

  def destroy
    @game.withdraw_rematch!(@seat.position)
    redirect_to @game, status: :see_other
  end
end
