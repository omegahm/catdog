require "test_helper"

module Rules
  class TileSetTest < ActiveSupport::TestCase
    def tile_hash(tile)
      Digest::SHA256.hexdigest(JSON.generate(FACES.to_h { |name| [ name, tile.faces.fetch(name).parts.map(&:to_h) ] }))
    end

    def parse(*parts, back: [ { "species" => "cat", "kind" => "head", "edges" => [ "s" ] } ])
      TileSet.parse("test", { "set" => "test", "tiles" => [ { "id" => "test-01", "front" => parts, "back" => back } ] })
    end

    def part(species, kind, *edges) = { "species" => species, "kind" => kind, "edges" => edges }

    test "every tile set file loads" do
      Dir[File.join(TileSet::DIRECTORY, "*.yml")].each do |path|
        assert TileSet.load(File.basename(path, ".yml")).tiles.any?
      end
    end

    test "the base set has 44 tiles with unique ids" do
      tile_set = TileSet.load

      assert_equal 44, tile_set.ids.size
      assert_equal 44, tile_set.ids.uniq.size
      assert tile_set.tiles.all? { it.anatomy_errors.empty? }
    end

    test "the crossing tiles have a crossing face and a single straight back" do
      tile_set = TileSet.load
      crossings = tile_set.tiles.select { |tile| tile.faces.values.any? { it.parts.size == 2 && it.parts.all? { it.kind == "straight" } } }

      assert_equal %w[base-41 base-42 base-43 base-44], crossings.map(&:id)
      crossings.each do |tile|
        assert_equal [ %w[w e], %w[n s] ], tile.faces["front"].parts.map(&:edges)
        assert_equal [ "straight" ], tile.faces["back"].parts.map(&:kind)
      end
    end

    test "published tiles do not change" do
      published = YAML.safe_load_file(file_fixture("tile_hashes.yml"))
      tiles = TileSet.load(*published.keys).tiles.to_h { [ it.id, tile_hash(it) ] }

      assert_equal published.values.reduce(:merge), tiles, "a published tile changed or a new tile has no hash in test/fixtures/files/tile_hashes.yml"
    end

    test "the loader accepts every legal part shape" do
      assert parse(part("cat", "straight", "w", "e"), part("dog", "straight", "n", "s"))
      assert parse(part("cat", "turn", "n", "e"), part("dog", "turn", "s", "w"))
      assert parse(part("dog", "head", "w"), part("dog", "tail", "e"))
    end

    test "the loader rejects faces with bad anatomy" do
      assert_raises(InvalidTileSet) { parse }
      assert_raises(InvalidTileSet) { parse(part("cat", "head", "n"), part("cat", "head", "e"), part("cat", "head", "s")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "head", "n"), part("dog", "tail", "n")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "straight", "n", "e")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "turn", "n", "s")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "head", "n", "s")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "turn", "n", "n")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "head", "x")) }
      assert_raises(InvalidTileSet) { parse(part("bird", "head", "n")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "paw", "n")) }
      assert_raises(InvalidTileSet) { parse(part("cat", "head", "n"), back: []) }
    end

    test "the loader rejects a file whose set name does not match" do
      assert_raises(InvalidTileSet) { TileSet.parse("base", { "set" => "other", "tiles" => [] }) }
    end

    test "the loader rejects a tile without a back" do
      assert_raises(InvalidTileSet) { TileSet.parse("test", { "set" => "test", "tiles" => [ { "id" => "test-01", "front" => [ part("cat", "head", "n") ] } ] }) }
    end

    test "tile ids are unique" do
      tile = TileSet.load.fetch("base-01")

      assert_raises(InvalidTileSet) { TileSet.new([ "test" ], [ tile, tile ]) }
    end
  end
end
