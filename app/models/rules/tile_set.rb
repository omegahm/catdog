require "yaml"

module Rules
  class TileSet
    DIRECTORY = File.expand_path("../../../config/tiles", __dir__)

    attr_reader :names

    def self.load(*names, directory: DIRECTORY)
      names = [ "base" ] if names.empty?
      tiles = names.flat_map { |name| parse(name, YAML.safe_load_file(File.join(directory, "#{name}.yml"))) }
      new(names, tiles)
    end

    def self.cached(*names)
      @cached ||= {}
      @cached[names] ||= load(*names)
    end

    def self.parse(name, data)
      raise InvalidTileSet, "#{name}: the file names set #{data["set"].inspect}" unless data["set"] == name

      data.fetch("tiles").map do |hash|
        tile = Tile.from_h(hash)
        errors = tile.anatomy_errors
        raise InvalidTileSet, "#{tile.id}: #{errors.join(", ")}" if errors.any?

        tile
      rescue KeyError, NoMethodError => e
        raise InvalidTileSet, "#{name}: #{e.message}"
      end
    end

    def initialize(names, tiles)
      @names = names
      @tiles = tiles.to_h { [ it.id, it ] }
      raise InvalidTileSet, "two tiles share an id" if @tiles.size != tiles.size
    end

    def ids = @tiles.keys

    def tiles = @tiles.values

    def include?(id) = @tiles.key?(id)

    def fetch(id) = @tiles.fetch(id)
  end
end
