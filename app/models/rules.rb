module Rules
  RULES_VERSION = 2
  SIZE = 7
  SEATS = [ 1, 2 ].freeze
  SPECIES = %w[cat dog].freeze
  KINDS = %w[head tail straight turn].freeze
  FACES = %w[front back].freeze
  ROTATIONS = [ 0, 90, 180, 270 ].freeze

  class IllegalMove < StandardError; end
  class InvalidTileSet < StandardError; end

  def self.opponent(seat) = 3 - seat

  def self.other_species(species) = (SPECIES - [ species ]).first

  def self.cells = SIZE.times.flat_map { |row| SIZE.times.map { |col| [ row, col ] } }

  def self.inside?(cell) = cell.all? { it.between?(0, SIZE - 1) }
end
