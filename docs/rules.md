# Rules for CatDog

Two-player game.

The game is played on 7x7 grid.

## Tiles

Each tile is a square with 4 edges and two faces.
Each face holds 1 or 2 parts. A face never has 0 parts.
A part is a cat or a dog part, and is one of:

- Head: touches 1 edge.
- Tail: touches 1 edge.
- Straight body: touches 2 opposite edges.
- Turn body: touches 2 adjacent edges.

Two parts on one face never share an edge.
Two parts on one face never cross, with one exception: two straight bodies may cross. They can be of the same species or of different species.
Crossing parts do not connect. One goes over the other.
An edge with no part is background.
A face can hold a cat part and a dog part, two parts of the same species, or just one part.

### Tile set

The bag holds the 44 tiles of the base tile set. The file [config/tiles/base.yml](../config/tiles/base.yml) describes each tile.
Two tiles can be identical.

## Placement

Each turn, a player draws two tiles from a bag.
The player chooses one of the tiles to place on the board.
The other tile is discarded.

The drawn tiles are open. Both players can see them as soon as they are drawn.
The number of tiles in the bag is open. The tiles in the bag are not shown.

When placing a tile, the player chooses which face is up and rotates it to any of 4 orientations.

You are not allowed to place a tile, if it does not share an edge with an existing tile on the board. Diagonal neighbours do not count. (Except for the first tile, which can be placed anywhere on the board.)

Every shared edge must match:

- Background meets background.
- A part meets a part of the same species.

A part may never meet background.
A part may face an empty cell. The animal is then open.
A part may not face the outer edge of the board. Background may.

An animal is a connected chain of parts of one species.
You are not allowed to place a tile, if it makes an animal with 2 heads or 2 tails.
You are not allowed to place a tile, if it closes an animal into a loop with no head and no tail.
A head meeting a tail directly is legal.

## Animals

An animal is complete when it has exactly 1 head and 1 tail, with 0 or more body parts between them.
The length of an animal is its number of parts, counted from tail to head. If the animal passes through the same tile twice, each part counts. The shortest animal is a head meeting a tail: length 2. There is no maximum length.

## Species

The players do not choose if they want to play as cat or dog.
The player who completes the first animal plays as that animal's species. The other player plays as the other species. This does not change for the rest of the game.
If the placement that completes the first animal completes both a cat and a dog, the player who placed the tile chooses their species.

A complete animal belongs to the player who plays as its species, no matter who completed it.
You may complete your opponent's animals, for example to stop them at a length they do not want. Your opponent then gets the reserve action.

## Reserve

Each player has a reserve next to them. A reserve holds 0 or 1 tile.
The discard pile and both reserves are open. Both players can see all their tiles.

### Getting a reserve tile

When a placement completes one or more animals, one player gets one reserve action:

- If all the completed animals are of one species, the player who plays as that species gets the reserve action. This is true also when the opponent placed the tile.
- If the placement completes a cat and a dog at the same time, the player who placed the tile gets the reserve action.

The first complete animal sets the species of the player who placed the tile, so that player gets the reserve action.

The order is:

1. Place your tile.
2. Discard the tile you did not place (if you drew two tiles).
3. Check for complete animals.
4. The player who gets the reserve action does it.
5. The turn goes to the opponent of the player who placed the tile.

In the reserve action, you may take any one tile from the discard pile and put it in your reserve.
If your reserve already holds a tile, you swap it: your old reserve tile goes to the discard pile.
You may also skip the reserve action.

After the reserve action, all tiles left in the discard pile go back to the bag. This also happens when you skip the reserve action.
If the discard pile is empty, the reserve action does nothing.

### Playing the reserve tile

On your turn, you may play your reserve tile instead of drawing from the bag.
You do not draw and you do not discard. Your reserve is then empty.
You may do this also when the bag holds fewer than two tiles.
If the reserve tile completes an animal, the reserve action follows the usual rule.

## Game end and scoring

### Game end

The game ends at once when one of these happens:

- You draw from the bag, but the bag holds fewer than two tiles. You do not draw. This is true also when you have a reserve tile: you may choose to draw and end the game.
- You draw two tiles, and neither tile has a legal placement with any face up and any rotation.

If only one of the two drawn tiles has a legal placement, you must place that tile.
You may not play your reserve tile if it has no legal placement. You must then draw from the bag.
After the draw, you may not change your choice and play your reserve tile.
The opponent does not get a last turn.

### Scoring

Only complete animals score. Open animals score nothing.

Each length is its own category. For each length, the player with more complete animals of that length scores 1 point.
If both players have the same number of animals of a length, no one scores that length.

Example: player 1 has cats of length 3, 3 and 5. Player 2 has dogs of length 3 and 4. Player 1 scores length 3 and length 5. Player 2 scores length 4. Player 1 wins 2–1.

Most points win.

If the points are tied, compare the lengths from the longest down. The first length where one player has more animals than the other decides the winner.
If no length is different, the game is a draw.
If no animal is complete at the end, both players score 0 and the game is a draw.

### Resign

You may resign at any time during the game, also on the opponent's turn.
The game ends at once and the opponent wins. The board is not scored.
