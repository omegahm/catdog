class Games::SeatLinksController < ApplicationController
  include Seating

  before_action :set_game

  def show
    remember_seat(@game, params[:token]) if @game.seats.find_by_token(params[:token])
    redirect_to @game
  end
end
