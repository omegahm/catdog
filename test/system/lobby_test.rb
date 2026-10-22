require "application_system_test_case"

class LobbyTest < ApplicationSystemTestCase
  test "create, share the invite link with the Copy button, and join" do
    page.driver.browser.execute_cdp("Browser.grantPermissions", origin: Capybara.current_session.server.base_url, permissions: %w[clipboardReadWrite clipboardSanitizedWrite])
    visit root_path
    click_on "New game"
    assert_selector "#status", text: "Waiting for your opponent."

    within(".copy-field", text: "Invite link") { click_on "Copy" }
    assert_selector "button", text: "Copied"
    invite = page.evaluate_async_script("navigator.clipboard.readText().then(arguments[0])")
    assert_equal find("#invite-link").value, invite

    Capybara.using_session(:guest) do
      visit invite
      click_on "Join game"
      assert_selector "#board"
    end
    assert_selector "#board"
    assert_selector "#presence", text: "● online"
  end
end
