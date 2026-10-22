require "test_helper"

class PresenceChannelTest < ActionCable::Channel::TestCase
  setup do
    @game = Game.create_with_seat!("host-token")
    @game.join!("guest-token")
    @host = @game.seats.find_by(position: 1)
  end

  def subscribe_as(token)
    stub_connection seat_tokens: { @game.id.to_s => token }
    subscribe game: @game.public_id
  end

  test "a seat holder subscribes, gets a presence row and is announced online" do
    assert_broadcast_on(PresenceChannel.broadcasting_for(@game), { seat: 1, seen_ago: 0 }) do
      subscribe_as "host-token"
    end

    assert subscription.confirmed?
    assert_has_stream_for @game
    assert_equal 1, @host.presences.count
    assert @host.online?
  end

  test "a visitor without a seat is rejected" do
    subscribe_as "wrong-token"

    assert subscription.rejected?
    assert_equal 0, Presence.count
  end

  test "unsubscribing deletes the row and announces the seat offline" do
    subscribe_as "host-token"

    assert_broadcast_on(PresenceChannel.broadcasting_for(@game), { seat: 1, seen_ago: nil }) { unsubscribe }
    assert_equal 0, @host.presences.count
    assert_not @host.online?
  end

  test "a heartbeat refreshes last seen" do
    subscribe_as "host-token"
    @host.presences.update_all(last_seen_at: 60.seconds.ago)

    perform :heartbeat
    assert_operator @host.seen_ago, :<, 5
  end

  test "a seat is offline when its newest row is older than 75 seconds" do
    @host.presences.create!(connection_id: "old", last_seen_at: 80.seconds.ago)

    assert_not @host.online?
  end

  test "stale rows of the seat are removed on subscribe" do
    @host.presences.create!(connection_id: "old", last_seen_at: 80.seconds.ago)
    subscribe_as "host-token"

    assert_equal 1, @host.presences.count
  end

  test "two devices on one seat keep the seat online until both leave" do
    @host.presences.create!(connection_id: "phone", last_seen_at: Time.current)
    subscribe_as "host-token"
    unsubscribe

    assert @host.online?
  end
end
