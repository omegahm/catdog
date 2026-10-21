# Move log with recorded draws, cached state

A game is stored as an append-only `moves` log, one row per step of a turn, and the log is the source of truth. A `state` JSON on `games` is a cache, written in the same transaction and rebuilt from the log when `state_seq` does not match. Random draws are not reproduced from a seed: each `draw` move records the tile ids it drew, so replay never runs an RNG and survives changes to Ruby or to the shuffle code. The bag has no order; it is the set of tiles not yet out. The log never holds an undo, and undo will not be added.

## Considered Options

- Snapshot only: no replay, and a bad write damages the game for good.
- Shuffle seed with deterministic replay: breaks when RNG or shuffle code changes, and a leaked seed predicts future draws.
