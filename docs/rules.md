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

Two parts on one face never share an edge and never cross.
An edge with no part is background.
A face can hold a cat part and a dog part, two parts of the same species, or just one part.

## Placement

Each turn, a player draws two tiles from a bag.
The player chooses one of the tiles to place on the board.
The other tile is discarded.

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
You may complete your opponent's animals, for example to stop them at a length they do not want.

## Reserve

Each player has a reserve next to them. A reserve holds 0 or 1 tile.
The discard pile and both reserves are open. Both players can see all their tiles.

### Getting a reserve tile

When your placement completes one or more animals, you get one reserve action.
This is true for any species, also for the first complete animal.

The order is:

1. Place your tile.
2. Discard the tile you did not place (if you drew two tiles).
3. Check for complete animals.
4. Do your reserve action.

In the reserve action, you may take any one tile from the discard pile and put it in your reserve.
If your reserve already holds a tile, you swap it: your old reserve tile goes to the discard pile.
You may also skip the reserve action.

After the reserve action, all tiles left in the discard pile go back to the bag. This also happens when you skip the reserve action.
If the discard pile is empty, the reserve action does nothing.

### Playing the reserve tile

On your turn, you may play your reserve tile instead of drawing from the bag.
You do not draw and you do not discard. Your reserve is then empty.
You may do this also when the bag holds fewer than two tiles.
If the reserve tile completes an animal, you get a reserve action as usual.

## Game end and scoring

The game ends when you draw from the bag, but cannot draw two tiles from the bag.

The purpose of the game is to make the most of each length of cats or dogs.
That is, if, at the end, player 1 has two cats of length 3, they will score the length 3 point.
Most points win.
