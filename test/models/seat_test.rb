require "test_helper"

class SeatTest < ActiveSupport::TestCase
  test "a seat stores only the digest of its token" do
    seat = Game.create!.seats.create!(position: 1, token: "secret")

    assert_equal Digest::SHA256.hexdigest("secret"), seat.token_digest
    assert_not_includes seat.attributes.values, "secret"
    assert_equal seat, Seat.find_by_token("secret")
    assert_nil Seat.find_by_token("other")
    assert_nil Seat.find_by_token(nil)
  end

  test "a game has at most one seat at each position" do
    game = Game.create!
    game.seats.create!(position: 1, token: "a")

    assert_not game.seats.build(position: 1, token: "b").valid?
    assert_not game.seats.build(position: 3, token: "c").valid?
  end
end
