class Games::RematchAcceptancesController < ApplicationController
  include Seating

  before_action :set_game
  before_action :require_seat

  def create
    rematch = @game.accept_rematch!(@seat.position)
    remember_seat(rematch, seat_token_for(@game))
    redirect_to rematch, status: :see_other
  end
end
