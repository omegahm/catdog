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

## Species

The players do not choose if they want to play as cat or dog.
The first completed animal will determine which animal the player is playing as.

## Reserve

When you complete a cat or dog, you get to place a tile from the discard pile in a special area next to you.
You can choose to play this tile instead of drawing from the bag on your turn.
The rest of the tiles in the discard pile go back to the bag.

## Game end and scoring

The game ends when you draw from the bag, but cannot draw two tiles from the bag.

The purpose of the game is to make the most of each length of cats or dogs.
That is, if, at the end, player 1 has two cats of length 3, they will score the length 3 point.
Most points win.
