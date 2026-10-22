# catdog
An AI fever dream of a game similar to CatNap

Live at <https://catdog.fidusmaskine.dk>.

## Docs

- [docs/spec.md](docs/spec.md): the PoC spec and build order
- [docs/rules.md](docs/rules.md): the game rules
- [GLOSSARY.md](GLOSSARY.md): the terms to use in code and UI
- [docs/adr/](docs/adr/): architecture decisions

## Run locally

Ruby 4.0.2, SQLite. There is no Node and no JS build step.

```sh
bin/setup
```

`bin/setup` installs gems, prepares the databases and starts the server on <http://localhost:3000>. Later, start the server with `bin/dev`.

## Test

```sh
bin/rails test
bin/rails test:system
```

`bin/ci` runs the same checks as GitHub Actions: RuboCop, the security audits, the tests and the system tests.

## Deploy

GitHub Actions must be green on `main` before a deploy.

```sh
bin/kamal deploy
```

Kamal 2 deploys one arm64 container to the Hetzner box, behind kamal-proxy. All SQLite databases are on the `/var/lib/catdog` volume. There are no backups.

## Playtest report

The report replays every started game through the rules engine and prints Markdown.

```sh
bin/rails playtest:report
bin/kamal app exec "bin/rails playtest:report"
```

The second command runs it on the production data.
