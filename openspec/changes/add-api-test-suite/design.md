# Design

## Context

See proposal.md (Why). Starting point that shapes the approach:

- Rails 7.2 in API mode with Minitest, the test framework Rails ships with. `test/test_helper.rb` loads every fixture and runs tests in parallel.
- `config/database.yml` requires the `DB_PASSWORD` variable and uses `host: localhost`. The CI `test` job starts PostgreSQL 16 on port 5432 with password `evin1234` but does not define `DB_PASSWORD`, so it fails with `KeyError` before running anything.
- `bin/brakeman` adds `--ensure-latest`, which exits with code 5 whenever a newer Brakeman exists, even with no security warnings.
- Business logic lives in the controllers, so today it can only be tested through HTTP. Refactoring it is planned in later changes.
- `config/initializers/resend.rb` sets SMTP as the delivery method in every environment; emails are sent with `deliver_later`.
- The route `GET /api/v1/juegos/:id` is declared in `config/routes.rb`, but the controller has no `show` action.

## Goals / Non-Goals

**Goals:**

- Tests survive the later refactor of controllers, services and models without changes.
- `bin/rails test` works the same locally (Docker Compose) and in CI.
- CI is green and required to merge into `develop` and `main`.

**Non-Goals:**

- Frontend or browser end-to-end tests (later change).
- Unit tests of models or services: they will come once the refactor extracts the logic.
- Fixing questionable behavior: this change pins it as it is. Any fix will be its own change that modifies the relevant spec.
- The `GET /api/v1/juegos/:id` route without an action: it is neither specified nor tested. A later change will decide whether to implement it or remove the route.

## Decisions

### Rails integration tests instead of an external suite

Use `ActionDispatch::IntegrationTest`, which sends HTTP requests to the whole application in the same process. Tests only use routes, headers and JSON; they never call controllers, models or internal classes.

- Alternative: an external TypeScript suite (for example Playwright) against the Docker environment. Language-independent, but slower, another stack to maintain, and not really needed: the planned refactor stays within Rails.
- Alternative: RSpec. Widely used, but adds dependencies, and the project already ships Minitest.

### Test data created through the API

Fixtures are reduced to what the API cannot create: one account per role (technician, teacher, family member) and the catalog games. Students, sessions and student accounts are created in each test by calling the API itself.

- Reason: fixtures are written against the tables. When a later change migrates `sesions` to foreign keys, only these few fixtures will need changes, not hundreds of lines.
- Alternative: FactoryBot. More flexible, but still coupled to the data model and adds a dependency.
- Test data does not reuse the credentials in `db/seeds.rb`.

### Small, explicit test helpers

`test/test_helper.rb` only adds generic helpers: get a token by logging in through the API, build the `Authorization` header and read the JSON response. No business logic in helpers, so each test can be understood by reading it.

### Controlled time

Date-dependent scenarios (streak, today's and this week's sessions, recovery token expiry) use `travel_to` to pin the day, so they do not fail depending on when they run.

### Emails without real delivery

Rails includes the Active Job helpers in tests, which enqueue jobs without running them, and the Action Mailer helpers. Recovery request scenarios assert that the email is (or is not) enqueued. For the reset, the test performs the enqueued job and reads the token from the link in the delivered email, without reading the database. Since `config/initializers/resend.rb` also sets SMTP in test, `test/test_helper.rb` sets the `:test` delivery method, so no test ever contacts Resend.

### Layout

One file per capability in `test/integration/api/v1/` (`authentication_test.rb`, `game_catalog_test.rb`, etc.), with one test per spec scenario named after the scenario. Every scenario can be traced to its test.

### CI

- `test` job: define `DB_PASSWORD` with the service password, remove the Chrome, `libvips` and `sqlite3` installation, and run `bin/rails db:test:prepare test` without `test:system`.
- Brakeman: remove `--ensure-latest` from `bin/brakeman`. Keeping Brakeman up to date is left to Dependabot, which is already configured upstream (it is not enabled by default on forks).
- RuboCop: `bin/rubocop -a` (safe corrections only) for the 16 current offenses.
- Branches: on the fork, protect `develop` and `main` so the three jobs must pass before merging.

## Risks / Trade-offs

- [Tests pin behavior that may be a bug, such as the streak counting up to the last session instead of today] → Intended: the goal is to detect changes. Fixing them will be an explicit change that modifies the spec and its test.
- [Sign-up reveals whether an email is already registered (422 "Email has already been taken"), unlike the password recovery request, which always answers with the same message] → Known behavior, pinned on purpose by the "Email already registered" scenario. A later `harden-authentication` change will make sign-up answer identically and add rate limiting to login, sign-up and password recovery; that change will modify the scenario and its test.
- [Authorization cases not covered in this public change] → They will be handled privately, and tests will be added once they are fixed.
- [Parallel tests share each process's database] → Each test runs in its own transaction; tests only rely on absolute counts for data they create themselves.
- [The Resend initializer forces SMTP in test too] → `test/test_helper.rb` sets `:test` delivery. If it were forgotten, delivery would fail for lack of a key instead of sending a real email.

## Migration Plan

No migration: neither data nor API change. Reverting the pull request rolls everything back.
