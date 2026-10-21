# CatDog PoC spec

The spec for the CatDog proof of concept. The PoC is a game for two players on two devices, online, in real time. Player 1 creates a game and shares an invite link. A secret seat token in a cookie identifies each seat. There are no accounts.

This file is an index in build order. Each decision is recorded in one place: the linked ticket, `docs/rules.md`, `GLOSSARY.md` or an ADR. If this file and a source do not agree, the source is correct. The map is [CatDog PoC spec](https://github.com/omegahm/catdog/issues/1).

## Sources of truth

- **Rules:** [docs/rules.md](rules.md). The engine implements this file and nothing else.
- **Terms:** [GLOSSARY.md](../GLOSSARY.md). Use these names in code (classes, columns, moves, UI text).
- **Tile set:** [config/tiles/base.yml](../config/tiles/base.yml), 44 tiles with stable ids. Published tiles are immutable.
- **Architecture decisions:** [docs/adr/](adr/).

## Stack

Rails 8 with its defaults: Hotwire (Turbo + Stimulus), importmap, Solid Cable, Solid Queue, SQLite, Minitest and Kamal. There is no Node and no JS build step.

## Build order

### 1. Rules engine

Plain Ruby objects, with no ActiveRecord. Input: the cached state and the tile set. Output: the legal placements, the next state after a move, the animals, the completions, the scores and the game end. The replay from `moves` and the live server use the same engine.

- [Lock tile anatomy and connection rules](https://github.com/omegahm/catdog/issues/2)
- [Lock animal completion, ownership and species](https://github.com/omegahm/catdog/issues/3)
- [Lock the reserve rules](https://github.com/omegahm/catdog/issues/8)
- [Lock scoring and game end](https://github.com/omegahm/catdog/issues/9)
- [Define the tile set](https://github.com/omegahm/catdog/issues/7): the YAML format, the crossing tiles, and the loader that rejects faces with bad anatomy.
- [Choose where rule checks run](https://github.com/omegahm/catdog/issues/13): the engine boundary and the legal placement function.

### 2. Data model and moves

The `games`, `seats` and `moves` tables. The append-only move log is the source of truth. `games.state` is a cache that holds only facts. `seq` is the optimistic lock. Draws record the tile ids, and there is no seed and no undo.

- [Choose the game state model](https://github.com/omegahm/catdog/issues/11) and [ADR 0001](adr/0001-move-log-with-recorded-draws.md)
- [Lock whether drawn tiles are hidden](https://github.com/omegahm/catdog/issues/12): all game information is open, so every seat renders the same state.

### 3. Lobby and seats

Create, invite link, join, the cookie map from game to seat token, the seat link, a random first player, rematch. There are no names.

- [Choose the lobby flow](https://github.com/omegahm/catdog/issues/14)

### 4. Game page and real-time sync

The page is rendered on the server for each seat. It holds the legal placements as JSON. There is one Turbo stream for each game, with refresh broadcasts and morphing. After a reconnect, the page refreshes.

- [Research real-time turn sync on Rails 8 defaults](https://github.com/omegahm/catdog/issues/5)
- [Prototype board interaction](https://github.com/omegahm/catdog/issues/10): both faces, tap or drag.
- [Prototype the reserve UI](https://github.com/omegahm/catdog/issues/16): the table layout, the reserve slot, the discard pile and auto-draw.
- [Prototype tile art](https://github.com/omegahm/catdog/issues/17): generated SVG sprites, two art styles and species colours, set in each browser.

The prototype branches named in these tickets are the primary source for the UI. They are never merged.

### 5. Presence and resign

Online or offline from `presences` rows with a heartbeat, a "Reconnecting…" banner, and a Resign button. There is no timeout.

- [Decide on opponent presence](https://github.com/omegahm/catdog/issues/15)

### 6. Tests and CI

Minitest. Unit tests for each rule in the engine, 50 seeded random playouts that check invariants and replay, tile set checks, and 6 system tests with two sessions. There are no JS unit tests. GitHub Actions must be green on `main` before a deploy.

- [Choose the test strategy](https://github.com/omegahm/catdog/issues/18)

Write the engine tests together with step 1, not after step 5.

### 7. Deploy

Kamal 2 to the shared Hetzner box (arm64), behind Lullabook's kamal-proxy, at `catdog.fidusmaskine.dk`. One container with Solid Queue in Puma. All SQLite databases are on one volume. There are no backups.

- [Choose PoC hosting](https://github.com/omegahm/catdog/issues/6)

## Background

- [Research CatNap rules to compare](https://github.com/omegahm/catdog/issues/4): CatDog is based on Cat Nap (Aerobellum, 2025).

## Out of scope

Each PoC decision must not block these later features:

- Hot-seat play (one screen).
- Asynchronous play with notifications.
- Public play, accounts, matchmaking.
- ELO or other ratings.
- Backups.
- Tile mix tuning (after playtests of the PoC).
