module GamesHelper
  COLOURS = %w[orange blue green purple red teal].freeze

  END_REASONS = {
    "bag_exhausted" => "The bag holds fewer than two tiles.",
    "stuck" => "Neither drawn tile has a legal placement."
  }.freeze

  def status_line(engine, me)
    return result_line(engine, me) if engine.ended?
    return "Opponent's turn." unless engine.turn == me

    case engine.phase
    when "awaiting_draw"
      engine.can_play_reserve? ? "Your turn. Draw from the bag, or place your reserve tile." : "Your turn. Draw from the bag."
    when "awaiting_place" then "Place one of your tiles."
    when "awaiting_species" then "You completed a cat and a dog. Choose your species."
    when "awaiting_reserve_action" then "You completed an animal. Take a tile from the discard pile into your reserve, or skip."
    end
  end

  def result_line(engine, me)
    winner = engine.winner
    result = if winner.nil? then "The game is a draw."
    elsif winner == me then "You won."
    else "Opponent won."
    end
    ending = engine.state.ending
    reason = if ending.fetch("reason") != "resign" then END_REASONS.fetch(ending.fetch("reason"))
    elsif ending.fetch("seat") == me then "You resigned."
    else "Opponent resigned."
    end
    "#{result} #{reason}"
  end

  def species_label(engine, seat)
    species = engine.state.species[seat]
    species ? "plays #{species}" : "species not set"
  end

  def complete_lengths(engine, seat)
    engine.score.lengths.fetch(seat).flat_map { |length, count| [ length ] * count }.sort
  end

  def face_fits?(placements, tile_id, face)
    placements.dig(tile_id, face)&.values&.any?(&:any?)
  end

  def tile_pair(tile_set, tile_id, **options)
    tag.span(safe_join(Rules::FACES.map { tile_face(tile_set, tile_id, it) }), class: [ "mini", options[:class] ])
  end

  def reserve_slot(tile_set, tile_id, **options)
    content = tile_id ? tile_pair(tile_set, tile_id) : tag.span("empty", class: "empty")
    tag.div(content, **options.except(:class), class: [ "slot", ("full" if tile_id), options[:class] ])
  end
end
