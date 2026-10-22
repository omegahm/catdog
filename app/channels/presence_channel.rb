class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @game = Game.find_by(public_id: params[:game])
    token = @game && seat_tokens[@game.id.to_s]
    @seat = token && @game.seats.find_by_token(token)
    return reject unless @seat

    @connection_id = SecureRandom.uuid
    @seat.presences.stale.delete_all
    @seat.presences.create!(connection_id: @connection_id, last_seen_at: Time.current)
    stream_for @game
    announce
  end

  def unsubscribed
    return unless @seat

    Presence.where(connection_id: @connection_id).delete_all
    announce
  end

  def heartbeat
    Presence.where(connection_id: @connection_id).update_all(last_seen_at: Time.current)
    announce
  end

  private

  def announce
    PresenceChannel.broadcast_to(@game, { seat: @seat.position, seen_ago: @seat.seen_ago })
  end
end
