module TileArtHelper
  STYLES = { "fur" => "Fur bands", "line" => "Line style" }.freeze
  GAP_WIDTHS = { "fur" => 28, "line" => 18 }.freeze

  PALETTE = {
    "orange" => %w[#d96f12 #8a3f00 #f6c48f],
    "blue" => %w[#2a62a8 #143a6b #a9c6ea],
    "green" => %w[#2e8b57 #145233 #a6dcbc],
    "purple" => %w[#7b4bb3 #45246e #cdb6ea],
    "red" => %w[#c23b3b #6e1717 #f0aaaa],
    "teal" => %w[#1f8a8a #0d4d4d #9fdcdc]
  }.freeze

  def tile_sprites
    groups = STYLES.keys.flat_map do |style|
      parts = Rules::SPECIES.product(Rules::KINDS).map do |species, kind|
        tag.g(TileArt.send(style, kind, species).html_safe, id: "#{style}-#{species}-#{kind}")
      end
      width = GAP_WIDTHS.fetch(style)
      parts << tag.g(tag.rect(x: 50 - width / 2 - 6, y: -1, width: width + 12, height: 102, fill: "var(--tile)"), id: "#{style}-gap")
    end
    tag.svg(tag.defs(safe_join(groups)), width: 0, height: 0, style: "position:absolute", "aria-hidden": true)
  end

  def tile_face(tile_set, tile_id, face, rotation: 0, **options)
    parts = tile_set.fetch(tile_id).face(face).parts
    straights = 0
    art = parts.flat_map do |part|
      straights += 1 if part.kind == "straight"
      transform = "rotate(#{part_rotation(part) * 90} 50 50)"
      STYLES.keys.flat_map do |style|
        uses = []
        uses << tag.use(href: "##{style}-gap", class: "art art-#{style}", transform:) if straights == 2 && part.kind == "straight"
        uses << tag.use(href: "##{style}-#{part.species}-#{part.kind}", class: "art art-#{style}", transform:)
      end
    end
    tag.svg(
      safe_join([ tag.rect(x: 1, y: 1, width: 98, height: 98, rx: 6, class: "face"), *art ]),
      viewBox: "0 0 100 100", class: [ "tile", options.delete(:class) ], style: "--rotation: #{rotation}deg", "aria-hidden": true, **options
    )
  end

  private

  def part_rotation(part)
    edges = part.edges.map { Rules::Direction::ALL.index(it) }
    case part.kind
    when "head", "tail" then (edges.first - 2) % 4
    when "straight" then edges.include?(0) ? 0 : 1
    else 4.times.find { |turn| edges.sort == [ (2 + turn) % 4, (1 + turn) % 4 ].sort }
    end
  end

  module TileArt
    module_function

    def arc_point(angle, radius)
      radians = angle * Math::PI / 180
      [ (100 + radius * Math.cos(radians)).round(1), (100 + radius * Math.sin(radians)).round(1) ]
    end

    def fur(kind, species)
      color = "var(--#{species})"
      dark = "var(--#{species}-dk)"
      case [ kind, species ]
      in [ "straight", "cat" ]
        %(<rect x="36" y="-1" width="28" height="102" fill="#{color}"/>) +
          [ 16, 50, 84 ].map { %(<path d="M36 #{it - 4} Q50 #{it + 3} 64 #{it - 4}" fill="none" stroke="#{dark}" stroke-width="4"/>) }.join
      in [ "straight", "dog" ]
        %(<rect x="36" y="-1" width="28" height="102" fill="#{color}"/><circle cx="44" cy="22" r="5" fill="#{dark}"/><circle cx="57" cy="50" r="6" fill="#{dark}"/><circle cx="45" cy="78" r="4.5" fill="#{dark}"/>)
      in [ "turn", "cat" ]
        %(<path d="M50 101 A50 50 0 0 1 101 50" fill="none" stroke="#{color}" stroke-width="28"/>) +
          [ 200, 225, 250 ].map do |angle|
            x1, y1 = arc_point(angle, 36)
            x2, y2 = arc_point(angle + 4, 50)
            x3, y3 = arc_point(angle, 64)
            %(<path d="M#{x1} #{y1} Q#{x2} #{y2} #{x3} #{y3}" fill="none" stroke="#{dark}" stroke-width="4"/>)
          end.join
      in [ "turn", "dog" ]
        %(<path d="M50 101 A50 50 0 0 1 101 50" fill="none" stroke="#{color}" stroke-width="28"/>) +
          [ [ 202, 44, 5 ], [ 228, 56, 6 ], [ 256, 46, 4.5 ] ].map do |angle, radius, size|
            x, y = arc_point(angle, radius)
            %(<circle cx="#{x}" cy="#{y}" r="#{size}" fill="#{dark}"/>)
          end.join
      in [ "head", "cat" ]
        %(<rect x="38" y="80" width="24" height="21" fill="#{color}"/>) +
          %(<polygon points="37 64 34 46 48 56" fill="#{color}"/><polygon points="63 64 66 46 52 56" fill="#{color}"/>) +
          %(<polygon points="38 60 37 51 44 56" fill="var(--nose)"/><polygon points="62 60 63 51 56 56" fill="var(--nose)"/>) +
          %(<circle cx="50" cy="70" r="17" fill="#{color}"/>) +
          %(<path d="M50 53.5 L50 61 M44.5 55 L46 61 M55.5 55 L54 61" stroke="#{dark}" stroke-width="2.6" stroke-linecap="round"/>) +
          %(<ellipse cx="44" cy="69" rx="2.4" ry="3.4" fill="var(--eye)"/><ellipse cx="56" cy="69" rx="2.4" ry="3.4" fill="var(--eye)"/>) +
          %(<polygon points="47.5 75 52.5 75 50 78" fill="var(--nose)"/>) +
          %(<path d="M42 77 L28 75 M42 80 L29 84 M58 77 L72 75 M58 80 L71 84" stroke="var(--eye)" stroke-width="1.2"/>)
      in [ "head", "dog" ]
        %(<rect x="38" y="80" width="24" height="21" fill="#{color}"/>) +
          %(<circle cx="50" cy="70" r="17" fill="#{color}"/><circle cx="57" cy="64" r="6" fill="#{dark}"/><circle cx="43" cy="58" r="3" fill="#{dark}"/><circle cx="60" cy="79" r="2.5" fill="#{dark}"/>) +
          %(<ellipse cx="33" cy="72" rx="6" ry="13" transform="rotate(18 33 72)" fill="#{dark}"/><ellipse cx="67" cy="72" rx="6" ry="13" transform="rotate(-18 67 72)" fill="#{dark}"/>) +
          %(<ellipse cx="50" cy="77" rx="9" ry="7" fill="var(--dog-lt)"/><ellipse cx="50" cy="74" rx="4" ry="3" fill="var(--eye)"/>) +
          %(<circle cx="44" cy="65" r="2.8" fill="var(--eye)"/><circle cx="56" cy="65" r="2.8" fill="var(--eye)"/>)
      in [ "tail", "cat" ]
        %(<polygon points="36 101 64 101 56 84 44 84" fill="#{color}"/>) +
          %(<path d="M50 86 C50 66 68 64 64 50 C61 40 50 44 54 51" fill="none" stroke="#{color}" stroke-width="8" stroke-linecap="round"/>) +
          %(<path d="M45 72 L55 74 M53 60 L63 58" stroke="#{dark}" stroke-width="3"/>)
      in [ "tail", "dog" ]
        %(<polygon points="36 101 64 101 60 84 40 84" fill="#{color}"/>) +
          %(<path d="M50 88 Q44 70 56 58" fill="none" stroke="#{color}" stroke-width="13" stroke-linecap="round"/>) +
          %(<circle cx="57" cy="57" r="6" fill="var(--dog-lt)"/><circle cx="45" cy="94" r="3.5" fill="#{dark}"/><circle cx="55" cy="88" r="2.8" fill="#{dark}"/><circle cx="49" cy="74" r="3" fill="#{dark}"/>) +
          %(<path d="M66 50 Q70 56 66 62 M71 47 Q76 56 71 65" fill="none" stroke="#{dark}" stroke-width="2" stroke-linecap="round"/>)
      end
    end

    def line(kind, species)
      case [ kind, species ]
      in [ "straight", "cat" ]
        %(<line x1="50" y1="0" x2="50" y2="100" stroke="var(--cat)" stroke-width="14"/>)
      in [ "straight", "dog" ]
        %(<line x1="50" y1="0" x2="50" y2="100" stroke="var(--dog)" stroke-width="18"/><line x1="50" y1="0" x2="50" y2="100" stroke="var(--tile)" stroke-width="7"/>)
      in [ "turn", "cat" ]
        %(<path d="M50 101 A50 50 0 0 1 101 50" fill="none" stroke="var(--cat)" stroke-width="14"/>)
      in [ "turn", "dog" ]
        %(<path d="M50 101 A50 50 0 0 1 101 50" fill="none" stroke="var(--dog)" stroke-width="18"/><path d="M50 101 A50 50 0 0 1 101 50" fill="none" stroke="var(--tile)" stroke-width="7"/>)
      in [ "head", "cat" ]
        %(<line x1="50" y1="100" x2="50" y2="80" stroke="var(--cat)" stroke-width="14"/><polygon points="36 70 34 48 48 60" fill="var(--cat)"/><polygon points="64 70 66 48 52 60" fill="var(--cat)"/>) +
          %(<circle cx="50" cy="70" r="16" fill="var(--cat)"/><circle cx="44" cy="68" r="2.8" fill="var(--tile)"/><circle cx="56" cy="68" r="2.8" fill="var(--tile)"/>)
      in [ "head", "dog" ]
        %(<line x1="50" y1="100" x2="50" y2="84" stroke="var(--dog)" stroke-width="18"/><line x1="50" y1="100" x2="50" y2="84" stroke="var(--tile)" stroke-width="7"/>) +
          %(<ellipse cx="33" cy="72" rx="5" ry="11" transform="rotate(15 33 72)" fill="var(--dog)"/><ellipse cx="67" cy="72" rx="5" ry="11" transform="rotate(-15 67 72)" fill="var(--dog)"/>) +
          %(<circle cx="50" cy="70" r="15" fill="var(--tile)" stroke="var(--dog)" stroke-width="5.5"/><circle cx="44.5" cy="67" r="2.8" fill="var(--dog)"/><circle cx="55.5" cy="67" r="2.8" fill="var(--dog)"/>) +
          %(<ellipse cx="50" cy="75" rx="3.5" ry="2.5" fill="var(--dog)"/>)
      in [ "tail", "cat" ]
        %(<line x1="50" y1="100" x2="50" y2="84" stroke="var(--cat)" stroke-width="14"/><path d="M50 88 L50 70 Q50 56 62 58 Q70 60 66 68" fill="none" stroke="var(--cat)" stroke-width="6" stroke-linecap="round"/>)
      in [ "tail", "dog" ]
        %(<line x1="50" y1="100" x2="50" y2="66" stroke="var(--dog)" stroke-width="18"/><line x1="50" y1="101" x2="50" y2="66" stroke="var(--tile)" stroke-width="7"/>) +
          %(<circle cx="50" cy="60" r="11" fill="var(--tile)" stroke="var(--dog)" stroke-width="5.5"/>)
      end
    end
  end
end
