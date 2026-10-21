# CatNap rules: research for CatDog

Ticket: [#4 Research CatNap rules to compare](https://github.com/omegahm/catdog/issues/4)

## Which game

The game is **Cat Nap** by Aerobellum Games (design Matthew Folger and Logan Grayson, art Parker Simpson, 2025, BGG id 445874). It is a 1-2 player tile-laying game. You connect head, body and tail parts of orange and purple cats.

How sure: **high**. Its turn loop matches the CatDog draft almost word for word: draw two, play one, discard one; the first completed cat sets your color; completing a cat lets you take a discard; you score one point per cat length where you have the majority.

Other games with a similar name that are **not** this game:
- *Cat Naps* (2024), a Disney speed-matching card game.
- "Catnap" / "Cat-Nap!" RPG zines on itch.io.

Main source: the official Deluxe Edition rulebook (16 pages) that the publisher links from its store page. Unless I say otherwise, all facts below come from it.

## How Cat Nap works

### Tile anatomy and edges
- 40 double-sided square cat tiles. You look at both sides of each drawn tile and choose which side to play.
- Each tile edge shows either **carpet** (background) or a **cat part** of one color (orange or purple).
- Cat parts on a tile are heads, tails and body segments. Body segments go straight across or turn 90 degrees (seen on the component page).
- From the component page: some tiles have one cat part, some have two parts of the same color, some have one orange and one purple part, and some have a head and a tail on one tile.

### Part matching
- After the first tile, each tile must go orthogonally next to a tile already on the board.
- Carpet must meet carpet.
- A cat part must meet a cat part of the **same color**.
- Anatomy must make sense: no cat with 2 heads or 2 tails, and no cat that goes from purple to orange.
- Cat parts must not go off the edge of the board. (Exception: an expansion furniture tile.)
- A cat part that faces an **empty** square is fine. The rulebook example puts the first tile with its cat parts facing outward, and incomplete cats are allowed.

### Rotation
- **Not stated** in the rulebook. The pictures show tiles in many orientations, and a store page says "cats can twist and stretch in any direction". So free rotation is very likely, but this is my inference, not a written rule.

### Completing an animal
- A complete cat has exactly 1 head and 1 tail, with zero or more body segments between them.
- A 2-tile cat is called a "Kitten". So the smallest cat has length 2.
- Cats have no maximum length.
- The rulebook does not define "length" in words. The Kitten rule and the score tracker (lengths 2 to 7+) suggest that length = number of tiles the cat covers. This is an inference.

### Ownership
- At the start, no player has a color.
- The player who completes the **first** cat takes the Cat's Paw of that cat's color. The other player takes the other Paw. You play that color for the rest of the game.
- If the first placement completes two cats of different colors, that player chooses the color.
- After that, either player can complete a cat of **either** color. You score only the cats of your color.

### Reserve (Cat's Paw) and discard (Litter Box)
- The discarded tile goes to the "Litter Box", an open area next to the board.
- The Cat's Paw holds **one** tile.
- After you have a Paw, each time you complete a cat (of either color), take **any one** tile from the Litter Box (also the one you just discarded) and put it on your Paw. If your Paw already has a tile, you may swap it with a tile from the Litter Box.
- Then all other Litter Box tiles go back into the bag.
- On your turn you can play the Paw tile instead of drawing two tiles.
- The first completed cat: the example says the Litter Box is shuffled back into the bag. The rulebook does not say clearly if the first completer also takes a tile. The wording "After you get a Cat's Paw..." and "the **next** player to complete a cat ... will be able to nab one" suggest: no tile for the first cat.

### Scoring
- At game end, for each cat length, the player with more complete cats of that length gets **1 point**.
- A big lead in one length gives the same 1 point as a lead of one cat.
- A tied length gives no point to anybody.
- Incomplete cats score nothing.

### Ties (whole game)
- If the points are tied, compare the longest cat length: the player with the majority there wins. If that length is also tied, look at the next longest length, and so on.
- The rulebook also says "the player with the longest cat wins" in one place. The detailed tie text and the example use the majority method above.
- A 0-0 draw is possible (there is an achievement for it).

### Game end
The game ends when either:
1. A player chooses to draw 2 tiles but cannot, because 1 or 0 tiles are left, or
2. A player cannot play a drawn tile because it has no legal placement.

Store pages also say "when no spaces remain".

### Tile set size and mix
- 40 double-sided cat tiles, two colors (orange and purple).
- The component page shows 32 tile designs. Two of them are marked "5x": a purple straight-body/curved-body tile and an orange one. The other 30 designs appear once each. 30 + 2 x 5 = 40, which matches the count. The exact per-design list is my reading of the picture, not text.
- The Deluxe box has 7 mini-expansions (the Super Deluxe Edition lists 8): furniture, Calico cats, toys, and more. They are optional and not relevant to the CatDog base rules.

### Board size
- **Not found.** The rulebook pictures show the board ("Snuggle Zone", a cloth mat) only in part. No source I could read gives the grid size.

## Per open point in docs/rules.md

`docs/rules.md` has no list of open points, so I used the gaps and unclear parts in the draft (and the related tickets #2, #3, #7, #8, #9).

| CatDog draft point | What Cat Nap does |
|---|---|
| 7x7 grid | Grid size not found. |
| Draw two, play one, discard one | Same. |
| Tile has two sides | Same: 40 double-sided tiles, you choose the side. |
| Rotation (not in draft) | Not stated. Pictures suggest free rotation (inference). |
| Edge types / matching (draft only says tiles "fit together") | Carpet meets carpet; cat part meets cat part of the same color; no 2 heads or 2 tails in one cat; no color change in one cat. A part may face an empty square. |
| Tile must "connect" to an existing tile | Must be orthogonally next to a tile. Carpet-to-carpet contact counts. |
| Parts must not go off the board | Same (an expansion adds an exception). |
| Background to background allowed; floating parts allowed | Same: carpet to carpet is legal, incomplete cats are legal. |
| What is a complete animal / minimum length | 1 head + 1 tail + 0 or more body. Minimum length 2 ("Kitten"). No maximum. |
| Species per player set by first completed animal | Same, by color. If the first move completes both colors, the player chooses. |
| Can you complete the opponent's animal? | Yes. Any completion of either color gives the reserve reward. |
| Reserve: how many tiles, swap? | One tile on the Paw. You may swap it for a Litter Box tile when you complete a cat. |
| Reward for the first completed animal | Unclear; most likely no tile, only the Litter Box goes back into the bag. |
| Rest of discard pile goes back to bag | Same: after each completion. |
| Play the reserve tile instead of drawing | Same. |
| Game end | Cannot draw 2 (1 or 0 left), **or** a drawn tile has no legal placement. The draft has only the first. |
| Scoring per length majority | Same: 1 point per length where you have more complete cats. Tied length = 0 points. Incomplete = 0. |
| Ties | Compare majority in the longest length, then the next longest, and so on. |
| Tile set size and mix | 40 tiles: 2 designs x 5 copies plus 30 single designs (reading of the picture). |

## Could not find

- Board grid size.
- An explicit rotation rule.
- A written definition of "length".
- A clear rule for the reward on the first completed cat.
- A text list of the tile designs (only a picture).
- What happens to the second drawn tile when neither can be placed (the game just ends).

## Sources

- Official rulebook (Deluxe Edition, PDF): https://cdn.shopify.com/s/files/1/0987/1084/7779/files/CatNap_Rules_Deluxe_Web_Cropped.pdf
- Publisher store page (links the rulebook, "over 50" tiles incl. expansions, list of expansions): https://aerobellum.games/catnap
- Board Game Matcher (designer, year, BGG id 445874): https://boardgamematcher.com/game/cat-nap
- Asmodee Canada, Super Deluxe Edition (turn loop, end, "any direction"): https://shop.asmodee.ca/en/abg-cat-sdlx
- FroGames (overview): https://frogames.it/en/products/cat-nap
- Board Game Bliss (overview): https://www.boardgamebliss.com/collections/c/products/cat-nap
- Kickstarter (could not open, HTTP 403): https://www.kickstarter.com/projects/aerobellumgames/catnap/
- BoardGameGeek (could not open, HTTP 403): https://boardgamegeek.com/boardgame/445874
