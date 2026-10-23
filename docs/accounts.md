# CatDog accounts spec

The spec for optional accounts in CatDog. A **guest** (a player with no account) plays as today, through seat tokens. An **account** holds the player's settings and statistics about finished online games, and opens its own seats on any device. Sign-in is with passkeys only.

This file is an index in build order. Each decision is recorded in one place: the linked ticket, `GLOSSARY.md` or an ADR. If this file and a source do not agree, the source is correct. The map is [CatDog accounts spec](https://github.com/omegahm/catdog/issues/39).

## Sources of truth

- **PoC spec:** [docs/spec.md](spec.md). Accounts build on it and do not change the game.
- **Rules:** [docs/rules.md](rules.md).
- **Terms:** [GLOSSARY.md](../GLOSSARY.md). Account, Guest, Claim, Passkey, Display name, Settings and Statistics are defined there. Use these names in code and UI text.
- **Architecture decisions:** [docs/adr/](adr/). Statistics depend on [ADR 0001](adr/0001-move-log-with-recorded-draws.md).

## Stack

The same as the PoC: Rails 8 defaults, importmap, SQLite, Minitest, Kamal. One new gem: `webauthn`. No email, no mail provider, no OAuth, no bcrypt.

## Build order

### 1. Sign-in with passkeys

Run the Rails 8 authentication generator, rename `User` to `Account`, and replace passwords with passkeys (`webauthn` 3.4.3 and a Stimulus controller). If Rails PR #57100 is in a released Rails version when the build starts, use it instead. Sign-up is one page: display name, then the first passkey; the account row is made only after the registration succeeds. Sign-in is one button with discoverable passkeys. Sessions keep the generator default (`Session` row per browser, signed cookie, until sign-out), without `ip_address` and `user_agent`. `rate_limit` per IP on sign-up and sign-in. A browser with no passkey support hides the account buttons.

- [Research passwordless sign-in for Rails 8](https://github.com/omegahm/catdog/issues/40)
- [Choose the sign-in method](https://github.com/omegahm/catdog/issues/41)

### 2. Data model, claim and access

The `accounts` table with typed, nullable setting columns and a `webauthn_id`; the `passkeys` table; rename `seats.user_id` to `account_id` with a foreign key `on_delete: :nullify`. One claim rule in `remember_seat`. `seat_for` and the Action Cable connection match a seat by token or by account. Rematch copies `account_id`.

- [Choose the account data model](https://github.com/omegahm/catdog/issues/42)

### 3. Display names

Normalise and validate the name (1 to 20 characters, reserved labels rejected, not unique). In an online game, the own seat is "You" and the other seat is its display name or "Guest". "Opponent" goes away everywhere, `status_line` included. Hot-seat keeps "Player 1" and "Player 2". The possessive rule is in the ticket.

- [Choose the display name rules](https://github.com/omegahm/catdog/issues/46)

### 4. Settings sync

The account wins at sign-in; a new account takes the browser's settings. The whole set of 4 values moves together. When signed in, the layout renders the settings on `<html>` and `localStorage` is a cache. Sign-out keeps `localStorage`. The game page panel stays, with "Saved to your account" for an account.

- [Prototype settings sync between browser and account](https://github.com/omegahm/catdog/issues/43)

### 5. Account UI

A "<display name> ▾" menu in every header (Your games, Your statistics, Account, Sign out); "Sign in" and "Create account" for a guest. Home is the hub when signed in: "New game", the account's open games on any device, and a statistics strip. The account page has the display name, the passkeys (the last one cannot be removed) and "Delete account". There are no settings on the account page.

- [Prototype the account UI](https://github.com/omegahm/catdog/issues/47)

### 6. Statistics

Add `games.ended_at` (set when the game ends, backfilled from the last move). One plain Ruby object, `Statistics.new(account)`, computes the totals and the past-game rows on each request from each game's cached state, with no new table. Ended, non-hot-seat games count, against guests too. A finished game keeps the result of its own `rules_version`. The page is "Your statistics": stat tiles, then past games, 20 per page. It is linked from the account menu and the result panel.

- [Prototype the statistics page](https://github.com/omegahm/catdog/issues/44)
- [Choose how statistics are computed](https://github.com/omegahm/catdog/issues/45)

### 7. Delete account and privacy page

`/account/delete` with a passkey re-auth. Before the delete, this browser gets new tokens for the account's open seats that it does not hold. The delete removes the account, its passkeys and all its sessions; the seats become guest seats. `/privacy` names the controller and `privacy@fidusmaskine.dk`. Write the 10 MB log limits into `config/deploy.yml`.

- [Choose the delete-account flow and privacy page](https://github.com/omegahm/catdog/issues/48)

### 8. Tests and deploy

The PoC test strategy applies ([Choose the test strategy](https://github.com/omegahm/catdog/issues/18)). Add a test that pins one game's statistics result for each `rules_version`. Deploy as in the PoC; the only deploy change is the log limits from step 7.

## Prototypes

The prototype branches are the primary source for the UI. They are never merged.

- [`prototype/settings-sync`](https://github.com/omegahm/catdog/tree/prototype/settings-sync): `app/javascript/controllers/settings_sync.prototype.html`.
- [`prototype/stats-page`](https://github.com/omegahm/catdog/tree/prototype/stats-page): `/prototype/stats?variant=A`.
- [`prototype/account-ui`](https://github.com/omegahm/catdog/tree/prototype/account-ui): `/prototype/account?variant=C` for home, A for the header menu.

## Known risk

There are no backups. A lost volume deletes all accounts and statistics, with no recovery. This is accepted, and the privacy page says so.

## Out of scope

- Backups (e.g. Litestream).
- Matchmaking, public game lists, ELO or other ratings.
- Data export. GDPR requests go to the contact address on the privacy page.
- Game-creation options in the account (tile sets, hot-seat default).
- Head-to-head records against each opponent.
- Email, OAuth and passwords.
