class Games::MovesController < ApplicationController
  include Seating

  before_action :set_game
  before_action :require_seat

  def create
    @game.play_moves!(seat_position: @seat.position, seq: Integer(params.require(:seq)), steps:)
    redirect_to @game, status: :see_other
  rescue Game::StaleMove
    redirect_to @game, status: :see_other
  rescue Rules::IllegalMove, ArgumentError, ActionController::ParameterMissing => error
    redirect_to @game, alert: error.message, status: :see_other
  end

  private

  def steps
    case params.require(:kind)
    when "draw" then [ [ "draw", {} ] ]
    when "resign" then [ [ "resign", {} ] ]
    when "place" then placement
    when "choose_species" then [ [ "choose_species", { species: params.require(:species) } ] ]
    when "reserve_action" then [ [ "reserve_action", params[:take].present? ? { take: params[:take] } : {} ] ]
    else raise Rules::IllegalMove, "unknown move #{params[:kind].inspect}"
    end
  end

  def placement
    place = [
      "place",
      {
        tile: params.require(:tile),
        face: params.require(:face),
        rotation: Integer(params.require(:rotation)),
        cell: [ Integer(params.require(:row)), Integer(params.require(:col)) ]
      }
    ]
    @game.engine.phase == "awaiting_draw" ? [ [ "play_reserve", {} ], place ] : [ place ]
  end
end
