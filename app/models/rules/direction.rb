module Rules
  module Direction
    ALL = %w[n e s w].freeze
    STEPS = { "n" => [ -1, 0 ], "e" => [ 0, 1 ], "s" => [ 1, 0 ], "w" => [ 0, -1 ] }.freeze

    def self.valid?(direction) = ALL.include?(direction)

    def self.rotate(direction, rotation) = ALL[(ALL.index(direction) + rotation / 90) % 4]

    def self.opposite(direction) = rotate(direction, 180)

    def self.step(cell, direction)
      row, col = cell
      row_step, col_step = STEPS.fetch(direction)
      [ row + row_step, col + col_step ]
    end
  end
end
