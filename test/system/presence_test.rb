require "application_system_test_case"

class PresenceTest < ApplicationSystemTestCase
  setup do
    visit root_path
    click_on "New game"
    @invite = find("#invite-link").value
    @game = Game.order(:id).last
  end

  def join
    Capybara.using_session(:guest) do
      visit @invite
      click_on "Join game"
      assert_selector "#board"
    end
  end

  test "each player sees the opponent online, and offline after they leave" do
    join

    assert_selector "#presence", text: "● online"
    Capybara.using_session(:guest) do
      assert_selector "#presence", text: "● online"
      visit root_path
    end
    assert_selector "#presence", text: "○ offline"
  end

  test "resign asks for a confirm and ends the game for both players" do
    join

    accept_confirm { click_on "Resign" }
    assert_selector "#status", text: "Opponent won."
    assert_selector "#result-reason", text: "You resigned."
    assert_no_selector "#resign"
    Capybara.using_session(:guest) do
      assert_selector "#status.won", text: "You won."
    end
  end

  test "a dismissed confirm does not resign" do
    join

    dismiss_confirm { click_on "Resign" }
    assert_selector "#resign"
    assert @game.reload.playing?
  end

  test "the reconnecting banner stays hidden after moves and morphs" do
    join
    mover = @game.reload.first_seat == 1 ? :default : :guest

    Capybara.using_session(mover) do
      assert_selector "#drawn .hand", count: 4
      assert_no_selector "#reconnecting"
      visit current_url
      assert_selector "#drawn .hand", count: 4
      assert_no_selector "#reconnecting"
    end
  end

  test "the reconnecting banner shows when the connection drops and goes away when it comes back" do
    join
    assert_selector "#presence", text: "● online"

    page.execute_script("document.querySelector('main').dispatchEvent(new CustomEvent('presence:disconnected'))")
    assert_selector "#reconnecting", text: "Reconnecting…"
    page.execute_script("document.querySelector('main').dispatchEvent(new CustomEvent('presence:connected'))")
    assert_no_selector "#reconnecting"
    assert_selector "#board"
  end

  test "a real server disconnect ends with the banner hidden and the page live" do
    join

    ActionCable.server.connections.each { it.close(reason: "server_restart", reconnect: true) }
    assert_no_selector "#reconnecting", wait: 20
    assert_selector "#presence", text: "● online", wait: 10
  end
end
