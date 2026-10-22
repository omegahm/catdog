module Rules
  class Tile
    attr_reader :id, :faces

    def self.from_h(hash)
      faces = FACES.to_h { |name| [ name, Face.new(parts: hash.fetch(name).map { Part.from_h(it) }) ] }
      new(hash.fetch("id"), faces)
    end

    def initialize(id, faces)
      @id = id
      @faces = faces
      @oriented = FACES.product(ROTATIONS).to_h { |name, rotation| [ [ name, rotation ], faces.fetch(name).rotate(rotation) ] }
    end

    def face(name, rotation = 0) = @oriented.fetch([ name, rotation ])

    def anatomy_errors = FACES.flat_map { |name| faces.fetch(name).anatomy_errors.map { "#{name}: #{it}" } }
  end
end
