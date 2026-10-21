module Rules
  Move = Data.define(:seat, :kind, :data) do
    def initialize(seat:, kind:, data: {})
      super(seat:, kind: kind.to_s, data: data.to_h.transform_keys(&:to_s))
    end
  end
end
