module Rules
  class Score
    attr_reader :lengths

    def initialize(animals, species)
      complete = animals.select(&:complete?)
      @lengths = SEATS.to_h do |seat|
        [ seat, complete.select { it.species == species[seat] }.map(&:length).tally ]
      end
    end

    def count(seat, length) = lengths.fetch(seat).fetch(length, 0)

    def points
      @points ||= SEATS.to_h do |seat|
        [ seat, all_lengths.count { count(seat, it) > count(Rules.opponent(seat), it) } ]
      end
    end

    def winner
      return points.max_by(&:last).first unless tied?

      tiebreak_length && SEATS.max_by { count(it, tiebreak_length) }
    end

    def tied? = points.values.uniq.size == 1

    def tiebreak_length
      all_lengths.find { count(1, it) != count(2, it) } if tied?
    end

    def draw? = winner.nil?

    def all_lengths = lengths.values.flat_map(&:keys).uniq.sort.reverse
  end
end
