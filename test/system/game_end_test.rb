require "application_system_test_case"

class GameEndTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ]

  setup do
    visit root_path
    click_on "New game"
    invite = find("#invite-link").value
    Capybara.using_session(:guest) do
      visit invite
      click_on "Join game"
      assert_selector "#board"
    end
    assert_selector "#board"
  end

  def scroll_down
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    assert_operator page.evaluate_script("window.scrollY"), :>, 0
  end

  def assert_scrolled_to_top
    Timeout.timeout(Capybara.default_max_wait_time) { sleep 0.05 until page.evaluate_script("window.scrollY").zero? }
  end

  test "both players scroll to the result panel when the game ends, and a later refresh keeps the scroll" do
    Capybara.using_session(:guest) { scroll_down }
    scroll_down

    accept_confirm { click_on "Resign" }
    assert_selector "#result-reason", text: "You resigned."
    assert_scrolled_to_top

    Capybara.using_session(:guest) do
      assert_selector "#status.won", text: "You won."
      assert_scrolled_to_top
      scroll_down
    end

    click_on "Offer rematch"
    assert_selector "#rematch", text: "You offered a rematch."
    Capybara.using_session(:guest) do
      assert_selector "#status #offer-cue", text: "Opponent offers a rematch ↑"
      assert_operator page.evaluate_script("window.scrollY"), :>, 0
      find("#offer-cue").click
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep 0.05 until page.evaluate_script("document.getElementById('rematch').getBoundingClientRect().bottom <= window.innerHeight")
      end
    end
  end
end
