require "yaml"
require "optparse"

EDGES = %w[n e s w].freeze
OPP = [2, 3, 0, 1].freeze
DIRS = [[-1, 0], [0, 1], [1, 0], [0, -1]].freeze
SIZE = 7
SPECIES = %i[cat dog].freeze

Part = Struct.new(:species, :kind, :edges)
Tile = Struct.new(:id, :faces, :orientations)
Orientation = Struct.new(:face, :rot, :parts, :edge_map)
Placed = Struct.new(:tile, :parts, :edge_map)
Move = Struct.new(:tile, :orientation, :r, :c, :completed, :connections)

def validate!(id, face)
  raise "#{id}: a face needs 1 or 2 parts" unless (1..2).cover?(face.size)
  face.each do |p|
    raise "#{id}: bad species #{p.species}" unless SPECIES.include?(p.species)
    raise "#{id}: bad edges" if p.edges.any?(&:nil?) || p.edges.uniq.size != p.edges.size
    ok = case p.kind
         when :head, :tail then p.edges.size == 1
         when :straight then p.edges.size == 2 && (p.edges[0] - p.edges[1]).abs == 2
         when :turn then p.edges.size == 2 && (p.edges[0] - p.edges[1]).abs.odd?
         else false
         end
    raise "#{id}: bad #{p.kind} #{p.edges.inspect}" unless ok
  end
  all = face.flat_map(&:edges)
  raise "#{id}: parts share an edge" if all.uniq.size != all.size
end

def orientations(faces)
  seen = {}
  faces.each_with_index.flat_map do |face, fi|
    4.times.filter_map do |rot|
      parts = face.map { |p| Part.new(p.species, p.kind, p.edges.map { |e| (e + rot) % 4 }) }
      edge_map = Array.new(4)
      parts.each_with_index { |p, pi| p.edges.each { |e| edge_map[e] = [pi, p.species] } }
      key = parts.map { |p| [p.species, p.kind, p.edges.sort] }.sort
      next if seen[key]
      seen[key] = true
      Orientation.new(fi, rot, parts, edge_map)
    end
  end
end

def load_tiles(paths)
  paths.flat_map do |path|
    YAML.load_file(path).fetch("tiles").map do |t|
      faces = %w[front back].map do |side|
        t.fetch(side).map { |p| Part.new(p["species"].to_sym, p["kind"].to_sym, p["edges"].map { |e| EDGES.index(e) }) }
      end
      faces.each { |f| validate!(t["id"], f) }
      Tile.new(t["id"], faces, orientations(faces))
    end
  end
end

def face_key(face, swap: false)
  4.times.map do |rot|
    face.map do |p|
      sp = swap ? (SPECIES - [p.species]).first : p.species
      [sp, p.kind, p.edges.map { |e| (e + rot) % 4 }.sort]
    end.sort
  end.min
end

def tile_key(tile, swap: false)
  tile.faces.map { |f| face_key(f, swap: swap) }.sort
end

def face_type(face)
  kinds = face.map(&:kind).sort.join("+")
  species = face.map(&:species).uniq.size == 2 ? "mixed" : face.first.species.to_s
  [kinds, species]
end

def static_report(name, tiles)
  puts "== Static checks: #{name} (#{tiles.size} tiles)"
  faces = tiles.flat_map(&:faces)
  SPECIES.each do |sp|
    parts = faces.flatten.select { |p| p.species == sp }
    counts = %i[head tail straight turn].map { |k| "#{k} #{parts.count { |p| p.kind == k }}" }
    puts "  #{sp}: #{counts.join(', ')}"
  end
  types = Hash.new { |h, k| h[k] = Hash.new(0) }
  faces.each { |f| kinds, sp = face_type(f); types[kinds][sp] += 1 }
  puts "  face type                cat  dog  mixed"
  types.sort.each do |kinds, h|
    puts format("  %-22s %4d %4d %6d", kinds, h["cat"], h["dog"], h["mixed"])
  end
  pool = tiles.map { |t| tile_key(t) }.tally
  unmatched = tiles.count do |t|
    mirror = tile_key(t, swap: true)
    pool[mirror].to_i.zero?
  end
  puts "  tiles with no cat<->dog mirror tile: #{unmatched}"
  puts
end

class Game
  attr_reader :log, :end_reason, :placements, :completed, :species, :reserve_plays, :grid

  def initialize(tiles, policies, rng)
    @rng = rng
    @bag = tiles.shuffle(random: rng)
    @discard = []
    @reserve = [nil, nil]
    @species = [nil, nil]
    @completed = [[], []]
    @policies = policies
    @grid = Array.new(SIZE) { Array.new(SIZE) }
    @frontier = {}
    @player = 0
    @placements = 0
    @reserve_plays = 0
    @end_reason = nil
    @log = []
  end

  def play
    take_turn until @end_reason
    self
  end

  def empty_board? = @placements.zero?

  def cells
    return SIZE.times.flat_map { |r| SIZE.times.map { |c| [r, c] } } if empty_board?

    @frontier.keys
  end

  def in_board?(r, c) = r.between?(0, SIZE - 1) && c.between?(0, SIZE - 1)

  def legal_moves(tile)
    cells.flat_map do |r, c|
      tile.orientations.filter_map { |o| check(tile, o, r, c) }
    end
  end

  def check(tile, o, r, c)
    neighbour = false
    connections = 0
    4.times do |d|
      nr = r + DIRS[d][0]
      nc = c + DIRS[d][1]
      mine = o.edge_map[d]
      unless in_board?(nr, nc)
        return nil if mine
        next
      end
      other = @grid[nr][nc]
      next unless other

      neighbour = true
      theirs = other.edge_map[OPP[d]]
      next if mine.nil? && theirs.nil?
      return nil if mine.nil? || theirs.nil? || mine[1] != theirs[1]

      connections += 1
    end
    return nil unless neighbour || empty_board?

    @grid[r][c] = Placed.new(tile, o.parts, o.edge_map)
    completed = []
    ok = true
    seen = {}
    o.parts.each_index do |pi|
      next if seen[[r, c, pi]]

      comp = component(r, c, pi)
      comp[:nodes].each { |n| seen[n] = true }
      if comp[:heads] > 1 || comp[:tails] > 1 || (comp[:heads].zero? && comp[:tails].zero? && comp[:open].zero?)
        ok = false
        break
      end
      completed << [comp[:species], comp[:nodes].size] if comp[:heads] == 1 && comp[:tails] == 1
    end
    @grid[r][c] = nil
    ok ? Move.new(tile, o, r, c, completed, connections) : nil
  end

  def component(r, c, pi)
    start = [r, c, pi]
    stack = [start]
    nodes = { start => true }
    heads = tails = open = 0
    species = @grid[r][c].parts[pi].species
    until stack.empty?
      cr, cc, cp = stack.pop
      part = @grid[cr][cc].parts[cp]
      heads += 1 if part.kind == :head
      tails += 1 if part.kind == :tail
      part.edges.each do |d|
        nr = cr + DIRS[d][0]
        nc = cc + DIRS[d][1]
        other = @grid[nr][nc]
        unless other
          open += 1
          next
        end
        node = [nr, nc, other.edge_map[OPP[d]][0]]
        next if nodes[node]

        nodes[node] = true
        stack << node
      end
    end
    { nodes: nodes.keys, heads: heads, tails: tails, open: open, species: species }
  end

  def place(move)
    @grid[move.r][move.c] = Placed.new(move.tile, move.orientation.parts, move.orientation.edge_map)
    @frontier.delete([move.r, move.c])
    4.times do |d|
      nr = move.r + DIRS[d][0]
      nc = move.c + DIRS[d][1]
      @frontier[[nr, nc]] = true if in_board?(nr, nc) && @grid[nr][nc].nil?
    end
    @placements += 1
  end

  def own?(player, sp) = @species[player] == sp

  def owner(sp) = @species.index(sp)

  def score_move(player, move)
    s = move.connections * 2.0
    move.completed.each do |sp, len|
      s += if @species[player].nil? then 10 + len
           elsif own?(player, sp) then 10 + len
           else -8
           end
    end
    s + @rng.rand
  end

  def points
    lengths = (@completed.flatten.uniq.sort)
    pts = [0, 0]
    lengths.each do |len|
      a = @completed[0].count(len)
      b = @completed[1].count(len)
      pts[0] += 1 if a > b
      pts[1] += 1 if b > a
    end
    pts
  end

  def winner
    pts = points
    return 0 if pts[0] > pts[1]
    return 1 if pts[1] > pts[0]

    @completed.flatten.uniq.sort.reverse_each do |len|
      a = @completed[0].count(len)
      b = @completed[1].count(len)
      return 0 if a > b
      return 1 if b > a
    end
    nil
  end

  def take_turn
    p = @player
    policy = @policies[p]
    reserve_moves = @reserve[p] ? legal_moves(@reserve[p]) : []
    if reserve_moves.any? && policy.use_reserve?(self, p, reserve_moves, @bag.size)
      @reserve[p] = nil
      @reserve_plays += 1
      move = policy.pick(self, p, reserve_moves)
    else
      if @bag.size < 2
        @end_reason = :bag
        return
      end
      drawn = @bag.pop(2)
      moves = drawn.map { |t| legal_moves(t) }
      if moves.all?(&:empty?)
        @end_reason = :stuck
        @discard.concat(drawn)
        return
      end
      choices = moves.flatten
      move = policy.pick(self, p, choices)
      drawn.delete_at(drawn.index { |t| t.equal?(move.tile) })
      @discard.concat(drawn)
    end
    place(move)
    @log << move
    resolve_completions(p, policy, move)
    @player = 1 - p
  end

  def resolve_completions(p, policy, move)
    return if move.completed.empty?

    if @species[p].nil?
      kinds = move.completed.map(&:first).uniq
      mine = kinds.size == 1 ? kinds.first : policy.choose_species(self, p, move)
      @species[p] = mine
      @species[1 - p] = (SPECIES - [mine]).first
    end
    move.completed.each { |sp, len| @completed[owner(sp)] << len }
    unless @discard.empty?
      pick = policy.reserve_action(self, p, @discard, @reserve[p])
      if pick
        @discard.delete_at(@discard.index(pick))
        @discard << @reserve[p] if @reserve[p]
        @reserve[p] = pick
      end
    end
    @bag.concat(@discard)
    @discard.clear
    @bag.shuffle!(random: @rng)
  end
end

class RandomPolicy
  def initialize(rng) = @rng = rng

  def use_reserve?(_game, _p, _moves, bag_size) = bag_size < 2 ? @rng.rand < 0.5 : @rng.rand < 0.3

  def pick(_game, _p, moves) = moves.sample(random: @rng)

  def choose_species(_game, _p, _move) = SPECIES.sample(random: @rng)

  def reserve_action(_game, _p, discard, _current) = @rng.rand < 0.33 ? nil : discard.sample(random: @rng)
end

class GreedyPolicy
  def initialize(rng) = @rng = rng

  def use_reserve?(game, p, moves, bag_size)
    if bag_size < 2
      game.winner != p
    else
      moves.any? { |m| m.completed.any? { |sp, _| game.species[p].nil? || game.species[p] == sp } }
    end
  end

  def pick(game, p, moves) = moves.max_by { |m| game.score_move(p, m) }

  def choose_species(_game, _p, move) = move.completed.max_by { |_, len| len }.first

  def reserve_action(game, _p, discard, current)
    best = discard.max_by { |t| game.legal_moves(t).size }
    return best if current.nil?

    game.legal_moves(best).size > game.legal_moves(current).size ? best : nil
  end
end

def percentile(values, q)
  sorted = values.sort
  sorted[((sorted.size - 1) * q).round]
end

def scale(tiles, size, rng)
  return tiles if size.nil? || size <= tiles.size

  extra = []
  extra.concat(tiles.shuffle(random: rng)) while extra.size < size - tiles.size
  tiles + extra.first(size - tiles.size)
end

def run(name, tiles, policy_class, games, seed, size)
  stats = Hash.new(0)
  placements = []
  completions = []
  lengths = Hash.new(0)
  points = []
  sample = nil
  games.times do |i|
    rng = Random.new(seed + i)
    bag = scale(tiles, size, rng)
    game = Game.new(bag, [policy_class.new(rng), policy_class.new(rng)], rng).play
    sample ||= game
    placements << game.placements
    stats[game.end_reason] += 1
    all = game.completed.flatten
    completions << all.size
    all.each { |l| lengths[[l, 8].min] += 1 }
    stats[:no_completion] += 1 if all.empty?
    w = game.winner
    if w.nil?
      stats[:draw] += 1
    else
      stats[:"p#{w + 1}"] += 1
      stats[game.species[w]] += 1
    end
    stats[:reserve_plays] += game.reserve_plays
    points << game.points.sum
  end
  avg = ->(a) { a.sum.to_f / a.size }
  pct = ->(k) { format("%3.0f%%", 100.0 * stats[k] / games) }
  total_len = lengths.values.sum.nonzero? || 1
  spread = (2..8).map { |l| format("%2.0f", 100.0 * lengths[l] / total_len) }.join(" ")
  puts format("%-30s %-6s %5.1f %3d-%-3d %4.0f%% | %s %s | %4.1f %s | %s %s %s | %s %s | %s",
              name, policy_class.name.sub("Policy", "").downcase[0, 6],
              avg.(placements), percentile(placements, 0.1), percentile(placements, 0.9),
              100.0 * avg.(placements) / (SIZE * SIZE),
              pct.(:bag), pct.(:stuck),
              avg.(completions), pct.(:no_completion),
              pct.(:p1), pct.(:p2), pct.(:draw),
              pct.(:cat), pct.(:dog),
              spread)
  sample
end

def glyph(part)
  ch = case part.kind
       when :head then "H"
       when :tail then "T"
       when :straight then part.edges.include?(0) ? "|" : "-"
       when :turn then "r"
       end
  color = part.species == :cat ? 33 : 35
  "\e[#{color}m#{ch}\e[0m"
end

def draw(game)
  puts "Sample game: #{game.placements} placements, end: #{game.end_reason}, species #{game.species.inspect}, " \
       "complete lengths #{game.completed.inspect}, points #{game.points.inspect}"
  puts "  yellow = cat, magenta = dog; H head, T tail, | - straight, r turn; + marks a crossing"
  game.grid.each do |row|
    lines = ["", "", ""]
    row.each do |cell|
      if cell.nil?
        lines[0] << "   "
        lines[1] << " . "
        lines[2] << "   "
        next
      end
      e = cell.edge_map.map { |m| m ? glyph(cell.parts[m[0]]) : "." }
      center = cell.parts.size == 2 && cell.parts.all? { |p| p.kind == :straight } ? "+" : "#"
      lines[0] << ".#{e[0]}."
      lines[1] << "#{e[3]}#{center}#{e[1]}"
      lines[2] << ".#{e[2]}."
    end
    lines.each { |l| puts "  #{l}" }
  end
  puts
end

CANDIDATES = {
  "catnap" => [%w[catnap], nil],
  "catnap+soft-crossing" => [%w[catnap crossing-soft], nil],
  "catnap+hard-crossing" => [%w[catnap crossing-hard], nil],
  "catnap+soft-crossing @48" => [%w[catnap crossing-soft], 48],
  "catnap+soft-crossing @56" => [%w[catnap crossing-soft], 56],
  "catnap+soft-crossing @64" => [%w[catnap crossing-soft], 64]
}.freeze

options = { games: 300, seed: 1, only: nil, sample: false }
OptionParser.new do |o|
  o.on("-n", "--games N", Integer) { |v| options[:games] = v }
  o.on("-s", "--seed N", Integer) { |v| options[:seed] = v }
  o.on("-o", "--only NAME") { |v| options[:only] = v }
  o.on("--sample") { options[:sample] = true }
end.parse!

dir = File.join(__dir__, "sets")
candidates = CANDIDATES.select { |name, _| options[:only].nil? || name.start_with?(options[:only]) }

candidates.each do |name, (sets, size)|
  next if size

  static_report(name, load_tiles(sets.map { |s| File.join(dir, "#{s}.yml") }))
end

puts "PROTOTYPE simulation, #{options[:games]} games per row"
puts format("%-30s %-6s %5s %-7s %5s | %-9s | %-9s | %-14s | %-9s | %s",
            "candidate", "policy", "place", "p10-p90", "fill", "end: bag stuck", "complete/game none",
            "win: p1 p2 draw", "cat dog", "length 2..8+ (% of complete animals)")
samples = []
candidates.each do |name, (sets, size)|
  tiles = load_tiles(sets.map { |s| File.join(dir, "#{s}.yml") })
  [RandomPolicy, GreedyPolicy].each do |pc|
    samples << [name, pc, run(name, tiles, pc, options[:games], options[:seed], size)]
  end
end
puts

samples.select { |_, pc, _| pc == GreedyPolicy }.each do |name, _, game|
  puts "#{name}, greedy:"
  draw(game)
end if options[:sample]
