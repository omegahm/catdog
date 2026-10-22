class PlaytestReport
  SIMULATION = {
    "random bots" => { placements: 35.0, bag: 28, stuck: 72, complete: 6.9, lengths: [ 57, 25, 10, 4, 2, 1, 0 ] },
    "greedy bots" => { placements: 36.9, bag: 64, stuck: 36, complete: 14.4, lengths: [ 49, 28, 13, 6, 2, 1, 1 ] }
  }.freeze
  LENGTH_BUCKETS = [ 2, 3, 4, 5, 6, 7, "8+" ].freeze

  GameStats = Data.define(
    :game, :engine, :placements, :draws, :reserve_plays, :takes, :swaps, :skips,
    :species_choices, :completing_placements, :duration
  ) do
    def ending = engine.state.ending&.fetch("reason")

    def complete_animals = engine.animals.select(&:complete?)

    def first_seat_result
      return "unfinished" unless engine.ended?
      return "draw" if engine.winner.nil?

      engine.winner == game.first_seat ? "first player" : "second player"
    end

    def tiebreak?
      engine.ended? && ending != "resign" && engine.winner && engine.score.points.values.uniq.size == 1
    end
  end

  def initialize(games = Game.where.not(status: "lobby").includes(:moves).order(:id))
    @stats = games.map { stats_for(it) }
  end

  def to_markdown
    return "# CatDog playtest report\n\nNo started games yet.\n" if @stats.empty?

    [
      "# CatDog playtest report",
      summary,
      endings,
      board,
      animals,
      reserve,
      results,
      comparison
    ].join("\n\n") + "\n"
  end

  private

  def stats_for(game)
    engine = Rules::Game.start(game.tile_set, first_seat: game.first_seat)
    counts = Hash.new(0)
    game.moves.each do |move|
      before = engine
      engine = engine.apply(move.to_rule)
      case move.kind
      when "place"
        counts[:placements] += 1
        counts[:completing_placements] += 1 if engine.animals.count(&:complete?) > before.animals.count(&:complete?)
      when "draw" then counts[:draws] += 1
      when "play_reserve" then counts[:reserve_plays] += 1
      when "choose_species" then counts[:species_choices] += 1
      when "reserve_action"
        if move.data["take"].nil? then counts[:skips] += 1
        elsif before.state.reserves[move.seat_position] then counts[:swaps] += 1
        else counts[:takes] += 1
        end
      end
    end
    times = game.moves.map(&:created_at)
    GameStats.new(
      game:, engine:,
      placements: counts[:placements], draws: counts[:draws], reserve_plays: counts[:reserve_plays],
      takes: counts[:takes], swaps: counts[:swaps], skips: counts[:skips],
      species_choices: counts[:species_choices], completing_placements: counts[:completing_placements],
      duration: times.any? ? times.max - times.min : 0
    )
  end

  def ended = @stats.select { it.engine.ended? }

  def scored = ended.reject { it.ending == "resign" }

  def percent(part, whole) = whole.zero? ? "–" : "#{(100.0 * part / whole).round}%"

  def average(values) = values.empty? ? "–" : (values.sum.to_f / values.size).round(1)

  def range(values)
    return "–" if values.empty?

    sorted = values.sort
    "#{sorted[(sorted.size * 0.1).floor]}–#{sorted[[ (sorted.size * 0.9).ceil - 1, 0 ].max]}"
  end

  def table(header, rows)
    lines = [ "| #{header.join(" | ")} |", "|#{header.map { "---" }.join("|")}|" ]
    lines + rows.map { "| #{it.join(" | ")} |" }
  end

  def summary
    minutes = ended.map { it.duration / 60.0 }
    <<~MD.strip
      ## Summary

      - Started games: #{@stats.size} (#{ended.size} ended, #{@stats.size - ended.size} still open)
      - Rematches: #{@stats.count { it.game.rematch_game_id }}
      - Average length of an ended game: #{average(minutes)} minutes (p10–p90: #{range(minutes.map(&:round))})
      - Scored games (not resigned): #{scored.size}.#{" Fewer than 30 scored games: treat the percentages as anecdotes." if scored.size < 30}
    MD
  end

  def endings
    reasons = { "bag_exhausted" => "Bag ran out", "stuck" => "Neither drawn tile fits", "resign" => "Resigned" }
    rows = reasons.map { |key, label| [ label, ended.count { it.ending == key }, percent(ended.count { it.ending == key }, ended.size) ] }
    ([ "## How games end", "" ] + table(%w[End Games Share], rows)).join("\n")
  end

  def board
    placements = scored.map(&:placements)
    rows = [
      [ "Placements per game", average(placements), range(placements) ],
      [ "Board filled (of 49 cells)", percent(placements.sum, scored.size * 49), "" ],
      [ "Placements that completed an animal", percent(scored.sum(&:completing_placements), placements.sum), "" ]
    ]
    ([ "## Board", "" ] + table([ "Measure", "Average", "p10–p90" ], rows)).join("\n")
  end

  def animals
    lengths = scored.flat_map { it.complete_animals.map(&:length) }
    per_game = scored.map { it.complete_animals.size }
    buckets = LENGTH_BUCKETS.map { |bucket| [ bucket, lengths.count { bucket == "8+" ? it >= 8 : it == bucket } ] }
    species = scored.flat_map(&:complete_animals).map(&:species).tally
    [
      "## Animals",
      "",
      "- Complete animals per game: #{average(per_game)} (p10–p90: #{range(per_game)})",
      "- Longest animal: #{lengths.max || "–"}",
      "- Cat / dog: #{species.fetch("cat", 0)} / #{species.fetch("dog", 0)}",
      "- Species chosen by the double-completion rule: #{@stats.sum(&:species_choices)} times",
      "",
      *table([ "Length", "Animals", "Share" ], buckets.map { |bucket, count| [ bucket, count, percent(count, lengths.size) ] })
    ].join("\n")
  end

  def reserve
    actions = @stats.sum { it.takes + it.swaps + it.skips }
    [
      "## Reserve",
      "",
      "- Reserve actions: #{actions} (take #{@stats.sum(&:takes)}, swap #{@stats.sum(&:swaps)}, skip #{@stats.sum(&:skips)})",
      "- Reserve tile played instead of a draw: #{@stats.sum(&:reserve_plays)} times, #{percent(@stats.sum(&:reserve_plays), @stats.sum { it.reserve_plays + it.draws })} of turns"
    ].join("\n")
  end

  def results
    outcomes = ended.map(&:first_seat_result).tally
    [
      "## Results",
      "",
      "- First player won #{outcomes.fetch("first player", 0)}, second player won #{outcomes.fetch("second player", 0)}, draws #{outcomes.fetch("draw", 0)}",
      "- Scored games decided by the tiebreak: #{scored.count(&:tiebreak?)}",
      "- Points per player in scored games: #{average(scored.flat_map { it.engine.score.points.values })}"
    ].join("\n")
  end

  def comparison
    lengths = scored.flat_map { it.complete_animals.map(&:length) }
    shares = LENGTH_BUCKETS.map { |bucket| lengths.count { bucket == "8+" ? it >= 8 : it == bucket } }
    no_resign = scored.size
    real = {
      placements: average(scored.map(&:placements)),
      bag: percent(scored.count { it.ending == "bag_exhausted" }, no_resign),
      stuck: percent(scored.count { it.ending == "stuck" }, no_resign),
      complete: average(scored.map { it.complete_animals.size }),
      lengths: shares.map { percent(it, lengths.size) }.join(" / ")
    }
    rows = SIMULATION.map do |name, sim|
      [ name, sim[:placements], "#{sim[:bag]}%", "#{sim[:stuck]}%", sim[:complete], sim[:lengths].map { "#{it}%" }.join(" / ") ]
    end
    rows << [ "**playtests**", real[:placements], real[:bag], real[:stuck], real[:complete], real[:lengths] ]
    [
      "## Playtests against the tile-set simulation",
      "",
      "Simulation: 1000 games per row, 44 tiles (ticket #7). Playtests: scored games only.",
      "",
      *table([ "Source", "Placements", "Bag ran out", "Stuck", "Complete / game", "Length 2 / 3 / 4 / 5 / 6 / 7 / 8+" ], rows)
    ].join("\n")
  end
end
