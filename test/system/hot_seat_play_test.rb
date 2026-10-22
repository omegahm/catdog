require "application_system_test_case"

class HotSeatPlayTest < ApplicationSystemTestCase
  test "two players take turns on one screen" do
    visit root_path
    page.execute_script("localStorage.setItem('catdog-auto-draw', 'off')")
    click_on "New game"
    click_on "Play here instead"
    assert_selector "#board"
    game = Game.order(:id).last
    first = game.reload.first_seat
    second = Rules.opponent(first)

    assert_selector "#status", text: "Player #{first}'s turn."
    find("#bag").click
    first("#drawn .hand:not(.nofit)").click
    cell = first("#board .cell.legal")
    cell.click
    cell.click

    assert_selector "#status", text: "Player #{second}'s turn."
    assert_selector "#me-name", text: "Player #{second}"
    assert_selector "#board .cell.filled", count: 1
    find("#bag").click
    assert_selector "#drawn .hand", count: 4
    assert_equal [ first, second ], game.moves.where(kind: %w[place draw]).order(:seq).pluck(:seat_position).values_at(1, 2)
  end
end
