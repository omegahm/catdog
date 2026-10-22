class StatsPrototypeController < ApplicationController
  VARIANTS = { "A" => "Scoreboard", "B" => "Profile", "C" => "History first" }.freeze
  OPPONENTS = [ "Mette", "bjørn_k", "Guest", "Sofie", "Guest", "TileTyrant", "Anders" ].freeze

  Row = Data.define(:id, :played_on, :opponent, :result, :ending, :mine, :theirs, :species, :longest)

  def show
    @variant = VARIANTS.key?(params[:variant]) ? params[:variant] : "A"
    @variants = VARIANTS
    @name = "Ohm"
    @games = params[:empty] ? [] : fake_games
    @games = @games.select { it.result.to_s == params[:result] } if params[:result].present? && @variant == "C"
    @stats = stats(@games)
    @page = (params[:page] || 1).to_i
  end

  private

  def fake_games
    rng = Random.new(39)
    day = Date.new(2026, 10, 21)
    Array.new(42) do |i|
      day -= rng.rand(0..4)
      species = rng.rand < 0.55 ? "cat" : "dog"
      roll = rng.rand
      ending, result =
        if roll < 0.06 then [ "resign_me", :loss ]
        elsif roll < 0.10 then [ "resign_them", :win ]
        else [ rng.rand < 0.8 ? "bag_exhausted" : "stuck", nil ]
        end
      mine = theirs = nil
      unless ending.start_with?("resign")
        mine, theirs = rng.rand(1..6), rng.rand(1..6)
        result = mine > theirs ? :win : mine < theirs ? :loss : (rng.rand < 0.3 ? :draw : %i[win loss].sample(random: rng))
      end
      species = nil if ending == "resign_me" && rng.rand < 0.5
      Row.new(id: 400 - i, played_on: day, opponent: OPPONENTS[rng.rand(OPPONENTS.size)], result:, ending:,
              mine:, theirs:, species:, longest: species && rng.rand(2..(i == 7 ? 14 : 9)))
    end
  end

  def stats(games)
    scored = games.reject { it.mine.nil? }
    longest = games.select(&:longest).max_by(&:longest)
    {
      played: games.size,
      wins: games.count { it.result == :win },
      losses: games.count { it.result == :loss },
      draws: games.count { it.result == :draw },
      resigned_me: games.count { it.ending == "resign_me" },
      resigned_them: games.count { it.ending == "resign_them" },
      avg_points: scored.any? ? (scored.sum(&:mine).to_f / scored.size).round(1) : nil,
      best: scored.max_by(&:mine),
      longest:,
      cat: games.count { it.species == "cat" },
      dog: games.count { it.species == "dog" },
      cat_wins: games.count { it.species == "cat" && it.result == :win },
      dog_wins: games.count { it.species == "dog" && it.result == :win }
    }
  end
end
