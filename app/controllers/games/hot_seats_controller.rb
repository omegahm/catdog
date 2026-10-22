class Games::HotSeatsController < ApplicationController
  include Seating

  before_action :set_game
  before_action :require_seat

  def create
    @game.play_here!
    redirect_to @game, status: :see_other
  end
end
