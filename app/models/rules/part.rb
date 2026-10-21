module Rules
  Part = Data.define(:species, :kind, :edges) do
    def self.from_h(hash)
      new(species: hash.fetch("species").to_s, kind: hash.fetch("kind").to_s, edges: Array(hash.fetch("edges")).map(&:to_s))
    end

    def rotate(rotation) = with(edges: edges.map { Direction.rotate(it, rotation) })

    def head? = kind == "head"

    def tail? = kind == "tail"

    def body? = !head? && !tail?

    def anatomy_errors
      errors = []
      errors << "unknown species #{species.inspect}" unless SPECIES.include?(species)
      errors << "unknown kind #{kind.inspect}" unless KINDS.include?(kind)
      errors << "bad edges #{edges.inspect}" unless edges.all? { Direction.valid?(it) } && edges.uniq.size == edges.size
      errors << "a #{kind} cannot touch #{edges.join(" and ")}" if errors.empty? && !edges_fit_kind?
      errors
    end

    private

    def edges_fit_kind?
      case kind
      when "head", "tail" then edges.size == 1
      when "straight" then edges.size == 2 && Direction.opposite(edges.first) == edges.last
      when "turn" then edges.size == 2 && Direction.opposite(edges.first) != edges.last
      end
    end
  end
end
