module Rules
  class Board
    Placement = Data.define(:tile_id, :face, :rotation)

    attr_reader :tile_set, :placements

    def initialize(tile_set, placements = {})
      @tile_set = tile_set
      @placements = placements
      @parts = {}
    end

    def empty? = placements.empty?

    def occupied?(cell) = placements.key?(cell)

    def place(cell, tile_id, face, rotation)
      Board.new(tile_set, placements.merge(cell => Placement.new(tile_id:, face:, rotation:)))
    end

    def parts_at(cell)
      @parts[cell] ||= begin
        placement = placements.fetch(cell)
        tile_set.fetch(placement.tile_id).face(placement.face, placement.rotation).parts
      end
    end

    def part_at(cell, edge) = parts_at(cell).find { it.edges.include?(edge) }

    def legal?(tile_id, face, rotation, cell)
      return false if !Rules.inside?(cell) || occupied?(cell)

      oriented = tile_set.fetch(tile_id).face(face, rotation)
      touches = false
      Direction::ALL.each do |edge|
        mine = oriented.part_at(edge)
        neighbour = Direction.step(cell, edge)
        if !Rules.inside?(neighbour)
          return false if mine
        elsif occupied?(neighbour)
          touches = true
          return false unless mine&.species == part_at(neighbour, Direction.opposite(edge))&.species
        end
      end
      return false unless touches || empty?

      place(cell, tile_id, face, rotation).animals_at(cell).all?(&:legal?)
    end

    def legal_cells(tile_id, face, rotation) = candidate_cells.select { legal?(tile_id, face, rotation, it) }

    def legal_placements(tile_id)
      FACES.to_h do |face|
        [ face, ROTATIONS.to_h { |rotation| [ rotation, legal_cells(tile_id, face, rotation) ] } ]
      end
    end

    def placeable?(tile_id)
      FACES.product(ROTATIONS).any? do |face, rotation|
        candidate_cells.any? { legal?(tile_id, face, rotation, it) }
      end
    end

    def animals
      seen = Set.new
      placements.keys.flat_map do |cell|
        parts_at(cell).each_index.filter_map do |index|
          next if seen.include?([ cell, index ])

          trace(cell, index).tap { seen.merge(it.segments) }
        end
      end
    end

    def animals_at(cell)
      parts_at(cell).each_index.map { trace(cell, it) }.uniq(&:segment_set)
    end

    private

    def candidate_cells
      return Rules.cells if empty?

      Rules.cells.select do |cell|
        !occupied?(cell) && Direction::ALL.any? { occupied?(Direction.step(cell, it)) }
      end
    end

    def trace(cell, index)
      start = [ cell, index ]
      segments = [ start ]
      seen = Set[start]
      open_edges = 0
      queue = [ start ]
      until queue.empty?
        current_cell, current_index = queue.shift
        parts_at(current_cell)[current_index].edges.each do |edge|
          link = linked(current_cell, edge)
          next open_edges += 1 if link.nil?
          next if seen.include?(link)

          seen << link
          segments << link
          queue << link
        end
      end
      parts = segments.map { |segment_cell, segment_index| parts_at(segment_cell)[segment_index] }
      Animal.new(species: parts.first.species, parts:, segments:, closed: open_edges.zero? && parts.all?(&:body?))
    end

    def linked(cell, edge)
      neighbour = Direction.step(cell, edge)
      return unless occupied?(neighbour)

      opposite = Direction.opposite(edge)
      index = parts_at(neighbour).index { it.edges.include?(opposite) }
      index && [ neighbour, index ]
    end
  end
end
