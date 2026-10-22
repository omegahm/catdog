class Games::JoinsController < ApplicationController
  include Seating

  before_action :set_game

  def create
    unless seat_for(@game)
      token = new_seat_token
      @game.join!(token)
      remember_seat(@game, token)
    end
    redirect_to @game, status: :see_other
  rescue Game::NotAllowed
    render "games/full", status: :forbidden
  end
end
