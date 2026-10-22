# Research: passwordless sign-in for Rails 8

Ticket: [#40](https://github.com/omegahm/catdog/issues/40). Map: [#39 CatDog accounts spec](https://github.com/omegahm/catdog/issues/39).
Date: 2026-10-22. This file is input for a later grilling ticket. It does not make a decision.

Context: Rails 8.1, Ruby 4.0, SQLite, Hotwire, importmap, no Node. Kamal 2 deploys one arm64 container to a Hetzner box (`catdog.fidusmaskine.dk`). Open sign-up. Guests keep playing through seat tokens. An account holds only 4 settings and game statistics, so a lost account costs the player little.

## Start point: the Rails 8 generator

- `bin/rails generate authentication` (Rails 8.0 and 8.1) makes `User` with `has_secure_password` (bcrypt), `Session` (a row per signed-in browser, signed cookie), `Current`, an `Authentication` concern, `SessionsController` with `rate_limit`, and a password-reset mailer. It has no sign-up form and no passwordless method.
- All 3 methods below keep `Session`, `Current`, the concern and `start_new_session_for`. They replace or remove the password parts. The column `password_digest` and the bcrypt gem can go.
- Rails PR [#57100 "Passkeys"](https://github.com/rails/rails/pull/57100) (opened 2026-03-30 by Stanko Krtalić, last update 2026-07-16, still open) adds `ActionPack::Passkey`, `has_passkeys`, `passkey_sign_in_button` web components for importmap, and changes the generator default to **magic links + passkeys** (passwords move behind `--password-based`). It is extracted from 37signals' Fizzy. It is not merged and not in any release. If it lands in Rails 8.2, it is the closest fit to this stack. Today the same code is in the gem [unmagic-passkeys](https://rubygems.org/gems/unmagic-passkeys) (0.3.0, 2026-07-13).
- Open generator fixes worth knowing: [#58926](https://github.com/rails/rails/pull/58926) (put a random token in the session cookie, not the ID).

## 1. Magic link (or one-time code) by email

**Gems.** None needed. `generates_token_for :magic_link, expires_in: 15.minutes` on `User` (Active Record, Rails 7.1+) plus Action Mailer. Optional engines: [passkey_auth](https://rubygems.org/gems/passkey_auth) (0.1.0, 2025-12), `dlnk_auth`, `rails_simple_auth`. All are young and small; hand-rolled is about 2 controllers and 1 mailer ([Rails Designer guide](https://railsdesigner.com/magic-links-for-rails-authentication/)).

**Setup effort.** Low code, medium ops: pick a provider, verify the sending domain (SPF, DKIM, DMARC DNS records on `fidusmaskine.dk`), add SMTP settings to `production.rb`. Mail must go through Solid Queue (`deliver_later`), which already runs in Puma.

**Secrets with Kamal.** Two options:
- Put the SMTP user and password in Rails credentials. `RAILS_MASTER_KEY` already reaches the container, so `deploy.yml` does not change.
- Or add `SMTP_PASSWORD` to `.kamal/secrets` and to `env.secret` in `config/deploy.yml`.

**EU providers (small volume).**

| Provider | Base | Free tier | Cheapest paid | Notes |
|---|---|---|---|---|
| [Scaleway TEM](https://www.scaleway.com/en/pricing/managed-services/) | France | 300 mails/month | €0.25 per 1,000 after that, no fee | Shared IP. Pay as you go. |
| [Lettermint](https://lettermint.co/pricing) | Netherlands | 300 mails/month, hard cap | €10/month for 10,000 | EU infrastructure, DPA included. |
| Brevo ([review](https://dreamlit.ai/blog/brevo-review)) | France | 300 mails/day | about $9/month | Free mails carry Brevo branding (marketing side). |
| Mailjet ([comparison](https://www.courier.com/integrations/compare/mailersend-vs-mailjet)) | France (Sinch) | about 6,000/month | paid tiers | |
| MailerSend ([comparison](https://www.courier.com/integrations/compare/brevo-vs-mailersend)) | Lithuania | small free tier | paid tiers | EU data residency by default. |
| Sweego ([listing](https://agentdeals.dev/vendor/sweego)) | France | 100/day | paid tiers | |

Free-tier numbers come mostly from third-party sites; check each pricing page before you sign up. Expected volume for CatDog is far below every free tier.

**Self-hosted mail is a poor fit.** Hetzner blocks outbound ports 25 and 465 on new cloud servers; you must request an unblock ([report](https://sudonix.org/post/8491)). Port 587 to a relay works.

**Deliverability.** Below 5,000 mails/day to Gmail you are not a "bulk sender", but Gmail still wants SPF or DKIM, and DMARC is recommended; Microsoft wants SPF + DKIM + DMARC `p=none` or stricter ([MailReach](https://www.mailreach.co/blog/gmail-sender-guidelines), [Red Sift](https://redsift.com/guides/bulk-email-sender-requirements)). A shared IP at a reputable provider is fine at this volume. Links can be eaten by corporate link scanners that "click" them first; a confirm button on the landing page (POST) avoids that.

**CatDog-specific risk: the wrong browser.** A player often opens the mail on a phone mail app. The link then signs in a different browser, and that browser has no seat cookies, so "claim this browser's seats" fails. A **6-digit code** that the player types into the same tab avoids this. 37signals' Fizzy mails a code that can also be typed (not verified in the Rails PR's generator code).

**Running cost.** €0 at hobby volume on any provider above.

**Abuse.** Open sign-up lets anyone make the app send mail to any address (mail bombing, reputation damage, provider suspension). Mitigate with `rate_limit` per IP and per email, do not create the `User` row until the code is used, and keep the mail text plain with no user input.

**GDPR.** You store an email address (personal data). The provider is a processor: you need its DPA (EU providers include one) and must list it on the privacy page. Delete-account must delete the email. EU-based provider avoids third-country transfer questions.

## 2. Passkeys (WebAuthn)

**Gems.**
- [webauthn](https://rubygems.org/gems/webauthn) (webauthn-ruby) 3.4.3, 2025-10-23. The base library. You write the controllers and about 60 lines of JS for `navigator.credentials` in a Stimulus controller.
- [webauthn-rails](https://www.rubydoc.info/gems/webauthn-rails) 0.1.2 (2025-10): a generator on top of the Rails auth generator; needs stimulus-rails.
- [has_secure_passkey](https://rubygems.org/gems/has_secure_passkey) 0.4.0 (2026-10-13), needs Rails 8 + webauthn.
- [unmagic-passkeys](https://rubygems.org/gems/unmagic-passkeys) 0.3.0: the Fizzy/Rails-PR code.
- All work with importmap; no Node needed.

**Browser support.** About 95% of users globally ([caniuse, Sept 2026 data](https://caniuse.com/passkeys)): Chrome/Edge 108+, Safari 16+, Firefox 122+, iOS 16+, Samsung Internet 21+. Gaps: old Android browsers, some shared or school computers, and people without a password manager or screen lock.

**Setup effort.** Medium. Two ceremonies (register, authenticate), a `passkeys` table (credential id, public key, sign count), a challenge kept in the session, the relying-party id set to `catdog.fidusmaskine.dk` (dev uses `localhost`). Testing needs Chrome's virtual authenticator in system tests.

**Recovery when a device is lost.** Synced passkeys (iCloud Keychain, Google Password Manager, 1Password, Bitwarden) survive a lost device. A device-bound key (hardware key, some Windows Hello setups) does not. Options:
- Let a signed-in user add more passkeys.
- An email fallback (method 1) for recovery. This brings back all of method 1's cost and GDPR load.
- No recovery: the account is lost. For CatDog this loses settings and stats only; the player can make a new account. Passkey-only means no email is stored at all.

**Running cost.** €0. No third party.

**Abuse.** No mail is sent, so no mail-bomb risk. Bots can still make many accounts; `rate_limit` on registration covers it. Phishing-resistant by design.

**GDPR.** Least data of the three: a public key and a display name. No processor. Passkey-only sign-up also has no contact channel, so "GDPR requests by email" depends on the user mailing you.

**Fit with the generator.** Good. Keep `Session`; replace `SessionsController#create` with passkey authentication. Sign-up = create `User` + register first passkey in one step.

## 3. OAuth (Google, GitHub)

**Gems.** [omniauth](https://rubygems.org/gems/omniauth) 2.3.1 (2026-10-22), [omniauth-rails_csrf_protection](https://rubygems.org/gems/omniauth-rails_csrf_protection) 2.0.1 (required; start must be a POST), [omniauth-google-oauth2](https://rubygems.org/gems/omniauth-google-oauth2) 1.2.3 (2026-08-31), [omniauth-github](https://rubygems.org/gems/omniauth-github) 2.0.1 (2022-09, old but stable). Each provider adds 1 gem.

**App registration.**
- Google: a Google Cloud project, OAuth consent screen, client id/secret, redirect URI `https://catdog.fidusmaskine.dk/auth/google_oauth2/callback`. With only `openid email profile` (non-sensitive) no app verification is needed; showing a logo needs light brand verification ([Google](https://support.google.com/cloud/answer/13463073)). The consent screen needs a privacy policy URL.
- GitHub: an OAuth App per environment (one callback URL each). Use the `user:email` scope only if you need an email ([GitHub scopes](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps)); for a display name and uid, no scope is needed.
- Client secrets go in Rails credentials or Kamal secrets, as in method 1.

**Setup effort.** Low code, some console work per provider. An `identities` table (provider, uid, user_id) lets one user have several providers.

**Running cost.** €0.

**Abuse.** Lowest: Google and GitHub do the bot filtering. One account per provider identity.

**GDPR.** Google and GitHub are US companies. They act as independent controllers for their own login; you receive uid, name and maybe email. Name them on the privacy page. Some EU players do not want to use a Google login on a game site. No account for players without Google or GitHub (GitHub is mostly developers).

**CatDog-specific note.** The flow leaves the site and comes back by a top-level GET, so `SameSite=Lax` seat cookies survive and seat claiming works in the same browser.

**Fit with the generator.** Good. Keep `Session`; the callback finds or creates the `User` via `Identity` and calls `start_new_session_for`.

## Trade-offs (no decision)

| | Magic link / code | Passkeys | OAuth |
|---|---|---|---|
| New gems | none | webauthn (+ helper gem) | omniauth + 1 per provider |
| Third party | mail provider (EU possible) | none | Google / GitHub (US) |
| Running cost | €0 at this volume | €0 | €0 |
| Personal data | email | public key only | provider uid, name, maybe email |
| Abuse surface | mail bombing, sender reputation | cheap bot accounts | low |
| Recovery | inbox is the recovery | needs fallback or accept loss | provider handles it |
| Reach | everyone with email | about 95% of browsers | only users with Google/GitHub |
| Seat claim works | only with code in same tab | yes | yes |

- Methods combine. A common pair is passkeys first with an email code as fallback; that is also what Rails PR #57100 proposes as the new generator default.
- If #57100 is merged before the build, using it avoids an extra gem. Today it is unmerged; building on `webauthn` or `unmagic-passkeys` is the current path.
- Open question for grilling: is losing an account (settings + stats) acceptable, so that passkey-only with no email is enough?
