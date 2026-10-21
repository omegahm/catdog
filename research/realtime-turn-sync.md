# Research: real-time turn sync on Rails 8 defaults

Ticket: [#5](https://github.com/omegahm/catdog/issues/5). Map: [#1](https://github.com/omegahm/catdog/issues/1).

Checked on 2026-10-21 against these versions:

| Piece | Version |
| --- | --- |
| Rails | 8.1.4 |
| turbo-rails | 2.0.23 |
| @hotwired/turbo | 8.0.23 |
| solid_cable | 4.1.0 |
| anycable-rails (only as an alternative) | 1.6.2 |

## Recommendation

Use **one shared stream per game** and send **page refresh broadcasts** (Turbo 8 morphing), not HTML fragments.

- After each accepted move, the server calls `broadcast_refresh_later_to(game)`.
- Each browser gets a small `<turbo-stream action="refresh">` message. It has no game data in it.
- Each browser then fetches the game page again with its own cookie. The server renders the page for that seat. Hidden info never goes over the shared stream.
- The page sets `<meta name="turbo-refresh-method" content="morph">` and `<meta name="turbo-refresh-scroll" content="preserve">`, so the update is smooth.
- On reconnect (and when the tab becomes visible again), the client asks for one refresh. This resyncs the full state, because the page is always rendered from the database.

The Rails 8 defaults are enough for a two-player PoC. No Redis, no AnyCable.

Tiny sketch (not production code):

```erb
<%# app/views/games/show.html.erb %>
<% content_for :head do %>
  <meta name="turbo-refresh-method" content="morph">
  <meta name="turbo-refresh-scroll" content="preserve">
<% end %>
<%= turbo_stream_from @game %>
```

```ruby
game.broadcast_refresh_later_to(game)
```

## How the pieces work

### Turbo Streams over Action Cable

- `turbo_stream_from(*streamables)` renders a `<turbo-cable-stream-source>` tag with a **signed** stream name. The client subscribes to `Turbo::StreamsChannel` with it.
- The channel verifies the signature with `Turbo.signed_stream_verifier` (an `ActiveSupport::MessageVerifier`, SHA256). If it fails, the subscription is rejected.
- The stream name is built from the streamables: `to_gid_param` for records, joined with `:`. So `turbo_stream_from(game, seat)` gives a stream unique to that seat.
- Sources: [streams_channel.rb](https://github.com/hotwired/turbo-rails/blob/main/app/channels/turbo/streams_channel.rb), [stream_name.rb](https://github.com/hotwired/turbo-rails/blob/main/app/channels/turbo/streams/stream_name.rb), [lib/turbo-rails.rb](https://github.com/hotwired/turbo-rails/blob/main/lib/turbo-rails.rb).

Important: the signed name is a **bearer token**. Anyone who has it can subscribe. I found no expiry on it in the code. The channel does no other auth check. If you need more, write a custom channel with a `subscription_allowed?` check (the comments in `streams_channel.rb` show this), or identify the seat in `ApplicationCable::Connection` from the seat cookie.

### Broadcast helpers

- `broadcast_replace_later_to`, `broadcast_append_later_to`, and similar render HTML and push it. The `_later` forms run in a job (Solid Queue by default). turbo-rails recommends `_later` in request paths.
- `broadcasts_refreshes` (model macro) and `broadcast_refresh_later_to` push a refresh signal. turbo-rails **debounces** repeated refresh calls for the same stream, so only the last one is sent.
- Source: [broadcastable.rb](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb), [broadcasts.rb](https://github.com/hotwired/turbo-rails/blob/main/app/channels/turbo/streams/broadcasts.rb).

### Page refresh and morphing (Turbo 8)

- A `refresh` stream action makes the page fetch itself again. With `turbo-refresh-method=morph`, Turbo uses idiomorph and changes only the DOM nodes that differ.
- Elements with `data-turbo-permanent` are not morphed (good for an open tile picker or a drag in progress).
- The refresh carries a `request-id`. The client skips the refresh if the id matches one of its own recent requests. So the player who made the move does not refresh twice. The client also skips it if a visit is already running, or if the URL is not the current page.
- Sources: [Turbo handbook, page refreshes](https://turbo.hotwired.dev/handbook/page_refreshes), [session.js `refresh()`](https://github.com/hotwired/turbo/blob/main/src/core/session.js), [stream_actions.js](https://github.com/hotwired/turbo/blob/main/src/core/streams/stream_actions.js).

Trade-off: each refresh is one full page request per player. For two players and one move every few seconds, this cost is very small. It also means we write the game view once, and the same view serves first load, live updates, reconnect, and later async play.

## Hidden info and per-player streams

The rules (`docs/rules.md`) do not yet say if the two drawn tiles are hidden from the opponent. The discard pile and the special areas seem public. Two options:

1. **Refresh on a shared stream (recommended).** The stream carries no data. Each player's page is rendered on the server for their seat (from the seat cookie). Hidden info is safe by design.
2. **Per-seat fragment streams.** `turbo_stream_from @game, @seat` on each seat's page, and broadcast seat-specific HTML to `[game, seat]`. This works, because the signed name is only rendered into that seat's page. But you must render each fragment twice (once per seat) and keep the two views in sync. More code, more ways to leak.

Note: broadcast partials render outside a request, so they have no cookie or `current_seat`. Seat-specific HTML must get the seat passed in as a local. The refresh approach avoids this problem.

## Solid Cable: latency and SQLite limits

From the [Solid Cable README](https://github.com/rails/solid_cable) (v4.1.0):

- It stores each broadcast as a row and each server process **polls** the table. Default `polling_interval: 0.1.seconds`.
- Default install config (`config/cable.yml`, production): `polling_interval: 0.1.seconds`, `message_retention: 1.day`, `writer_batch_size: 4`, `writer_batch_delay: 0.001.seconds`. Development uses the `async` adapter, test uses `test`.
- Rails 8.1.4's SQLite template puts cable in its own file: `storage/production_cable.sqlite3`.
- README benchmark, SQLite, 0.1 s polling, 100 virtual users: round trip avg ~136 ms, p95 ~195 ms. Redis on the same machine: avg ~69 ms. With 0.01 s polling, SQLite at 250 users was ~84 ms avg.
- Retention: the README says a few minutes is plenty. The default of 1 day is generous. For us (very few messages) it does not matter much. Autotrim runs on broadcast.
- v4.1.0 added optional payload encryption (`encrypt: true`). Not needed with the refresh approach, since payloads have no game data.

For a turn-based game, ~100-200 ms extra delay is fine. Add the Solid Queue hop if you use `_later` broadcasts. I did not measure that hop.

SQLite limits that matter:

- SQLite is a local file. All web processes that broadcast or listen must be on **one host** (one Kamal server with a volume). Scaling to more hosts needs a different database or adapter. This is fine for the PoC.
- SQLite has one writer at a time. Each broadcast is a write to the cable database (a separate file from the game data, so it does not lock game writes). At our message rate this is not a problem. I found no hard numbers for low-traffic apps, only the README benchmark above.

## Reconnect behaviour and resync

What the code does:

- Action Cable's client `ConnectionMonitor` treats the socket as stale after **6 s** with no ping (two missed server pings). It then reconnects with backoff (rate 0.15, capped after 10 attempts, with jitter). When the tab becomes visible again, it checks after 200 ms and reopens a stale or closed socket. Source: [connection_monitor.js (Rails 8.1.4)](https://github.com/rails/rails/blob/v8.1.4/actioncable/app/javascript/action_cable/connection_monitor.js).
- `<turbo-cable-stream-source>` sets a `connected` attribute when the subscription is up and removes it on disconnect. It has **no replay, no sequence numbers, no catch-up**. Messages sent while a client is offline are lost for that client. Source: [cable_stream_source_element.js](https://github.com/hotwired/turbo-rails/blob/main/app/javascript/turbo/cable_stream_source_element.js).
- Stock Action Cable does not replay missed messages. (AnyCable docs say the same, and sell "reliable streams" as the fix: [AnyCable reliability](https://docs.anycable.io/js/reliability).)

How to resync:

- Watch the `connected` attribute (a tiny Stimulus controller with a `MutationObserver`). When it comes back after a loss, ask Turbo to reload the page (for example `Turbo.visit(location.href, { action: "replace" })`). With morphing on, this looks like a normal refresh. `Turbo.session.refresh(url)` also exists, but I am not sure it is public API, so I would not depend on it.
- Also refresh on `visibilitychange` to visible. Phones suspend tabs a lot.
- Optional: render a `data-move-number` (or game version) on the page. The client can then tell if it is behind. This fits a move-log model (see "Game state model" in #1).
- Because the page is the source of truth, resync is the same code path as first load. No special "catch-up" logic on the server.

What the other player sees during a disconnect is a product decision (open in #1). The `connected` attribute is enough to show "reconnecting..." locally. Showing "opponent offline" needs presence, which Action Cable does not give for free. You could track it in the channel's `subscribed` / `unsubscribed` callbacks, but I did not research this in depth.

## How others build turn-based games with Hotwire

I found little real evidence here.

- A RailsConf 2023 session about a real-time tic-tac-toe game with Turbo Streams and Action Cable is listed, but I could not open the abstract or find code ([sessionize](https://railsconf2023.sessionize.com/session/453119)).
- [nigelfds/maths](https://github.com/nigelfds/maths) is a small real-time multiplayer grid game on Rails 8.1 + Hotwire, but it uses PostgreSQL and Redis. I did not read its source.
- The common pattern in guides: one stream per game record, broadcast on each move from the model or controller. Turbo 8's docs push "broadcast a general signal, then refresh with morphing" as the simple default ([page refreshes](https://turbo.hotwired.dev/handbook/page_refreshes)).

I would not treat any of these as proven designs for our case.

## Fit with later features (#1 constraint)

- **Async play:** the page renders full state from the DB. Live refresh is a bonus, not a need. Nothing to undo.
- **Hot-seat:** same page, the server renders for "both seats". The stream still works.
- **Accounts:** seat lookup moves from cookie to user. The stream (`game`) does not change. If stream auth matters later, add a custom channel check.
- **Multiple servers:** this is the one place the defaults stop. See alternatives.

## Alternatives (only if the defaults fall short)

| Option | When | Trade-offs |
| --- | --- | --- |
| Solid Cable on PostgreSQL/MySQL | More than one app host | Same code, needs a DB server. Same polling model. |
| Action Cable Redis adapter | Lower latency, many hosts | ~half the round trip in the README benchmark. Adds a Redis service to run. Still no replay. |
| [AnyCable](https://docs.anycable.io/guides/reliable_streams) | Need replay of missed messages, or many connections | Go server process plus broker; reliable streams with history (default history TTL 300 s per their docs). More moving parts. Overkill for a two-player PoC. |

## Open points

- Are the two drawn tiles hidden from the opponent? (Rules ticket.) The recommendation works either way.
- Opponent presence ("offline" badge): not covered here.
- I did not test any of this in a running app. Numbers are from the Solid Cable README, not from us.
