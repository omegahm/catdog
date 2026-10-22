module Rules
  Animal = Data.define(:species, :parts, :segments, :closed) do
    def heads = parts.count(&:head?)

    def tails = parts.count(&:tail?)

    def length = parts.size

    def closed? = closed

    def complete? = heads == 1 && tails == 1

    def legal? = heads <= 1 && tails <= 1 && !closed?

    def cells = segments.map(&:first).uniq

    def segment_set = segments.to_set
  end
end
