module RulesHelper
  class SpecTiles < Rules::TileSet
    def self.parse_face(spec)
      parts = spec.split("+").map do |part|
        species, kind, *edges = part.split
        Rules::Part.new(species:, kind:, edges:)
      end
      Rules::Face.new(parts:)
    end

    def self.build(id)
      front, back = id.sub(/#.*/, "").split("|").map(&:strip)
      Rules::Tile.new(id, { "front" => parse_face(front), "back" => parse_face(back || front) })
    end

    def initialize(ids = [])
      super([ "spec" ], ids.map { self.class.build(it) })
      @built = {}
    end

    def fetch(id) = include?(id) ? super : (@built[id] ||= self.class.build(id))
  end

  def board(layout = {})
    layout.reduce(Rules::Board.new(SpecTiles.new)) { |board, (cell, spec)| board.place(cell, spec, "front", 0) }
  end

  def placements(layout)
    layout.transform_values { Rules::Board::Placement.new(tile_id: it, face: "front", rotation: 0) }
  end

  def game_with(bag, board: {}, first_seat: 1, **changes)
    tiles = SpecTiles.new(bag + board.values + changes.fetch(:discard, []) + changes.fetch(:reserves, {}).values.compact)
    state = Rules::State.initial(tiles, first_seat).with(bag: bag.sort, board: placements(board), **changes)
    Rules::Game.new(tiles, state)
  end

  def move(seat, kind, **data) = Rules::Move.new(seat:, kind:, data:)

  def draw(seat, *tiles) = move(seat, :draw, tiles:)

  def place(seat, tile, cell, face: "front", rotation: 0) = move(seat, :place, tile:, face:, rotation:, cell:)

  def play(game, *moves) = moves.reduce(game) { |current, next_move| current.apply(next_move) }

  def animal(species, length)
    parts = [ Rules::Part.new(species:, kind: "tail", edges: [ "e" ]) ] +
      Array.new(length - 2) { Rules::Part.new(species:, kind: "straight", edges: %w[w e]) } +
      [ Rules::Part.new(species:, kind: "head", edges: [ "w" ]) ]
    Rules::Animal.new(species:, parts:, segments: parts.each_index.map { [ [ 0, it ], 0 ] }, closed: false)
  end

  def board_problems(board)
    problems = []
    board.placements.each_key do |cell|
      Rules::Direction::ALL.each do |edge|
        mine = board.part_at(cell, edge)
        neighbour = Rules::Direction.step(cell, edge)
        if !Rules.inside?(neighbour)
          problems << "#{cell} has a part on the outer edge" if mine
        elsif board.occupied?(neighbour)
          theirs = board.part_at(neighbour, Rules::Direction.opposite(edge))
          problems << "#{cell} #{edge} does not match #{neighbour}" unless mine&.species == theirs&.species
        end
      end
    end
    board.animals.reject(&:legal?).each { problems << "illegal animal on #{it.cells}" }
    problems << "the board is not connected" unless connected?(board)
    problems
  end

  private

  def connected?(board)
    return true if board.empty?

    reached = Set[board.placements.keys.first]
    queue = reached.to_a
    until queue.empty?
      cell = queue.shift
      Rules::Direction::ALL.each do |edge|
        neighbour = Rules::Direction.step(cell, edge)
        next unless board.occupied?(neighbour) && !reached.include?(neighbour)

        reached << neighbour
        queue << neighbour
      end
    end
    reached.size == board.placements.size
  end
end
