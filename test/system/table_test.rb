require "application_system_test_case"

class TableTest < ApplicationSystemTestCase
  setup do
    visit root_path
    click_on "New game"
    invite = find("#invite-link").value
    @game = Game.order(:id).last
    Capybara.using_session(:guest) do
      visit invite
      click_on "Join game"
      assert_selector "#board"
    end
    @game.reload
    @mover = @game.first_seat == 1 ? :default : :guest
  end

  def set_state(**changes)
    tile_set = @game.tile_set
    state = Rules::State.initial(tile_set, @game.first_seat)
    changes[:board] = changes.fetch(:board, {}).transform_values { Rules::Board::Placement.new(tile_id: it[0], face: it[1], rotation: it[2]) }
    used = changes[:board].values.map(&:tile_id) + changes.fetch(:drawn, []) + changes.fetch(:discard, []) + changes.fetch(:reserves, {}).values.compact
    @game.update_columns(state: state.with(bag: state.bag - used, **changes).as_json)
  end

  def turn_to_180(id)
    3.times { find(id).click }
  end

  def as_mover(&)
    Capybara.using_session(@mover) do
      page.execute_script("localStorage.setItem('catdog-auto-draw', 'off')")
      visit current_url
      instance_eval(&)
    end
  end

  test "dragging a face onto a legal cell places it at once" do
    set_state(board: { [ 3, 3 ] => [ "base-35", "front", 0 ] }, drawn: %w[base-40 base-01], phase: "awaiting_place")

    as_mover do
      turn_to_180("#hand-base-40-back")
      find("#hand-base-40-back").drag_to(find("#cell-4-3"))
      assert_selector "#cell-4-3.filled.last"
    end
    assert_equal %w[place], @game.moves.map(&:kind)
    assert_equal [ "base-40", "back", 180 ], @game.moves.last.data.values_at("tile", "face", "rotation")
  end

  test "rotating a face by tapping it again changes the legal cells" do
    set_state(board: { [ 3, 3 ] => [ "base-35", "front", 0 ] }, drawn: %w[base-40 base-01], phase: "awaiting_place")

    as_mover do
      find("#hand-base-40-back").click
      assert_selector "#board .cell.legal"
      assert_no_selector "#cell-4-3.legal"
      2.times { find("#hand-base-40-back").click }
      assert_selector "#cell-4-3.legal"
      find("#cell-4-3").click
      find("#cell-4-3").click
      assert_selector "#cell-4-3.filled"
    end
    assert_equal 180, @game.moves.last.data["rotation"]
  end

  test "the reserve action swaps by tap and confirm" do
    seat = @game.first_seat
    set_state(
      board: { [ 3, 3 ] => [ "base-35", "front", 0 ] },
      drawn: %w[base-40 base-01],
      reserves: { seat => "base-36", Rules.opponent(seat) => nil },
      discard: %w[base-02],
      phase: "awaiting_place"
    )

    as_mover do
      turn_to_180("#hand-base-40-back")
      find("#hand-base-40-back").drag_to(find("#cell-4-3"))
      assert_selector "#status", text: "Take a tile from the discard pile"
      find("#discard [data-tile='base-02']").click
      click_on "Confirm swap"
      assert_selector "#status", text: "Opponent's turn."
    end

    @game.reload
    assert_equal "base-02", @game.state.dig("reserves", seat.to_s)
    assert_includes @game.state["bag"], "base-36"
  end

  test "dragging a discarded tile onto the reserve slot takes it at once" do
    set_state(board: { [ 3, 3 ] => [ "base-35", "front", 0 ] }, drawn: %w[base-40 base-01], phase: "awaiting_place")

    as_mover do
      turn_to_180("#hand-base-40-back")
      find("#hand-base-40-back").drag_to(find("#cell-4-3"))
      find("#discard [data-tile='base-01']").drag_to(find("#reserve-slot"))
      assert_selector "#status", text: "Opponent's turn."
    end
    assert_equal "base-01", @game.reload.state.dig("reserves", @game.first_seat.to_s)
  end

  test "auto-draw draws as soon as the turn starts" do
    Capybara.using_session(@mover) do
      visit current_url
      assert_selector "#drawn .hand", count: 4
    end
    assert_equal %w[draw], @game.moves.map(&:kind)
  end
end
