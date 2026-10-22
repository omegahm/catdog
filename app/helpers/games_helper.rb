module GamesHelper
  COLOURS = %w[orange blue magenta teal olive].freeze

  END_REASONS = {
    "bag_exhausted" => "The bag holds fewer than two tiles.",
    "stuck" => "Neither drawn tile has a legal placement."
  }.freeze

  def player_name(seat, me, hot_seat: false)
    return "Player #{seat}" if hot_seat

    seat == me ? "You" : "Opponent"
  end

  def status_line(engine, me, hot_seat: false)
    return result_line(engine, me, hot_seat:) if engine.ended?
    return "Opponent takes a tile into their reserve, or skips." if engine.acting_seat != me && engine.phase == "awaiting_reserve_action"
    return "Opponent's turn." unless engine.acting_seat == me

    who = player_name(me, me, hot_seat:)
    case engine.phase
    when "awaiting_draw"
      turn = hot_seat ? "#{who}'s turn" : "Your turn"
      engine.can_play_reserve? ? "#{turn}. Draw from the bag, or place your reserve tile." : "#{turn}. Draw from the bag."
    when "awaiting_place" then hot_seat ? "#{who}: place one of your tiles." : "Place one of your tiles."
    when "awaiting_species" then "#{who} completed a cat and a dog. Choose your species."
    when "awaiting_reserve_action"
      done = if engine.turn == me then "#{who} completed an animal."
      elsif hot_seat then "Player #{engine.turn} completed an animal of #{who}."
      else "Opponent completed one of your animals."
      end
      "#{done} Take a tile from the discard pile into your reserve, or skip."
    end
  end

  def turn_alert(engine, me, hot_seat: false)
    return "" if engine.nil? || engine.ended?
    return "player-#{engine.acting_seat}" if hot_seat

    engine.acting_seat == me ? "you" : ""
  end

  def turn_bar_class(engine, me, hot_seat: false)
    return "turn-bar" if engine.nil? || engine.ended?
    return [ "turn-bar", "seat", engine.state.species[engine.acting_seat] ] if hot_seat

    [ "turn-bar", ("mine" if engine.acting_seat == me) ]
  end

  def page_title(engine, me, hot_seat: false)
    turn_alert(engine, me, hot_seat:) == "you" ? "● Your turn – CatDog" : "CatDog"
  end

  def result_line(engine, me, hot_seat: false)
    winner = engine.winner
    result = winner.nil? ? "The game is a draw." : "#{player_name(winner, me, hot_seat:)} won."
    ending = engine.state.ending
    reason = if ending.fetch("reason") == "resign"
      "#{player_name(ending.fetch("seat"), me, hot_seat:)} resigned."
    else
      END_REASONS.fetch(ending.fetch("reason"))
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
