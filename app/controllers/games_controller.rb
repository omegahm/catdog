class GamesController < ApplicationController
  include Seating

  before_action :set_game, only: :show

  def create
    token = new_seat_token
    game = Game.create_with_seat!(token)
    remember_seat(game, token)
    redirect_to game, status: :see_other
  end

  def show
    @seat = seat_for(@game)
    @engine = @game.engine if @seat && !@game.lobby?
    @me = @engine && @game.hot_seat? ? @engine.turn : @seat&.position
    return if @seat
    return render(:join) if @game.lobby?

    render :full, status: :forbidden
  end
end
