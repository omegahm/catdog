module Rules
  State = Data.define(:board, :bag, :discard, :reserves, :drawn, :species, :phase, :turn, :reserve_seat, :ending) do
    def self.initial(tile_set, first_seat)
      new(
        board: {},
        bag: tile_set.ids.sort,
        discard: [],
        reserves: SEATS.to_h { [ it, nil ] },
        drawn: [],
        species: SEATS.to_h { [ it, nil ] },
        phase: "awaiting_draw",
        turn: first_seat,
        reserve_seat: nil,
        ending: nil
      )
    end

    def self.from_h(hash)
      board = hash.fetch("board").to_h do |key, placement|
        cell = key.split(",").map(&:to_i)
        [ cell, Board::Placement.new(tile_id: placement.fetch("tile"), face: placement.fetch("face"), rotation: placement.fetch("rotation")) ]
      end
      new(
        board:,
        bag: hash.fetch("bag"),
        discard: hash.fetch("discard"),
        reserves: SEATS.to_h { [ it, hash.fetch("reserves")[it.to_s] ] },
        drawn: hash.fetch("drawn"),
        species: SEATS.to_h { [ it, hash.fetch("species")[it.to_s] ] },
        phase: hash.fetch("phase"),
        turn: hash.fetch("turn"),
        reserve_seat: hash["reserve_seat"],
        ending: hash["ending"]
      )
    end

    def as_json(*)
      {
        "board" => board.sort.to_h do |cell, placement|
          [ cell.join(","), { "tile" => placement.tile_id, "face" => placement.face, "rotation" => placement.rotation } ]
        end,
        "bag" => bag,
        "discard" => discard,
        "reserves" => reserves.transform_keys(&:to_s),
        "drawn" => drawn,
        "species" => species.transform_keys(&:to_s),
        "phase" => phase,
        "turn" => turn,
        "reserve_seat" => reserve_seat,
        "ending" => ending
      }
    end

    def tile_count = board.size + bag.size + discard.size + reserves.values.compact.size + drawn.size
  end
end
