require "application_system_test_case"

class TurnTest < ApplicationSystemTestCase
  test "a full turn by tap updates the opponent's page through the broadcast" do
    visit root_path
    click_on "New game"
    invite = find("#invite-link").value
    game = Game.order(:id).last

    Capybara.using_session(:guest) do
      visit invite
      click_on "Join game"
      assert_selector "#board"
    end
    assert_selector "#board"

    game.reload
    mover, waiter = game.first_seat == 1 ? [ :default, :guest ] : [ :guest, :default ]

    Capybara.using_session(mover) do
      page.execute_script("localStorage.setItem('catdog-auto-draw', 'off')")
      visit current_url
      find("#bag").click
      assert_selector "#drawn .hand", count: 4
      hand = all("#drawn .hand:not(.nofit)").first
      hand.click
      assert_selector "#board .cell.legal"
      cell = first("#board .cell.legal")
      cell.click
      assert_selector "#board .cell .tile.ghost"
      cell.click
      assert_selector "#status", text: "Opponent's turn."
    end

    Capybara.using_session(waiter) do
      assert_selector "#board .cell.filled.last"
      assert_selector "#status", text: "Your turn."
    end
  end

  test "a POST with a stale seq is rejected and the page refreshes" do
    visit root_path
    click_on "New game"
    invite = find("#invite-link").value
    game = Game.order(:id).last
    Capybara.using_session(:guest) do
      visit invite
      click_on "Join game"
      assert_selector "#board"
    end
    mover = game.reload.first_seat == 1 ? :default : :guest

    Capybara.using_session(mover) do
      page.execute_script("localStorage.setItem('catdog-auto-draw', 'off')")
      visit current_url
      assert_selector "button#bag"
      Game.suppressing_turbo_broadcasts { game.play!(seat_position: game.first_seat, kind: "draw", seq: 0) }
      find("#bag").click
      assert_selector "#drawn .hand", count: 4
      assert_no_selector ".alert"
    end
    assert_equal %w[draw], game.moves.map(&:kind)
  end
end
