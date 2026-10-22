# Keep the stuck game end

The game ends at once when neither drawn tile has a legal placement ([rules](../rules.md#game-end)). We keep this rule, although it can end a game after only one placement. In 1000 random playouts with the first tile in the centre, 0.3% of games ended this way (0.9% with the first tile on a random cell). Most games (about 75%) end stuck late, at 26 to 33 placements on the 49-cell board. A board with no space left is an end we want. The rare early end does not justify a new rule.

## Considered Options

- Discard and draw again when neither tile fits, so the game ends only when the bag runs out: the end becomes predictable, fewer tiles go back to the bag, and the rule set grows.

## Consequences

- Random play is a weak model of real play. If the playtest report shows many early stuck ends in real games, look at this decision again.
- Tests that draw at random after a placement can end the game as stuck. Such tests must control the bag.
