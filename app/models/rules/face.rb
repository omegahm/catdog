module Rules
  Face = Data.define(:parts) do
    def rotate(rotation) = with(parts: parts.map { it.rotate(rotation) })

    def part_at(edge) = parts.find { it.edges.include?(edge) }

    def anatomy_errors
      errors = []
      errors << "a face holds 1 or 2 parts, not #{parts.size}" unless parts.size.between?(1, 2)
      parts.each { errors.concat(it.anatomy_errors) }
      edges = parts.flat_map(&:edges)
      errors << "two parts share an edge" if edges.uniq.size != edges.size
      errors
    end
  end
end
