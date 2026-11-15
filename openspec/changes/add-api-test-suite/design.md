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

`test/test_helper.rb` only adds generic helpers: get a token by logging in through the API (the password is always passed explicitly), build the `Authorization` header and read the JSON response. Setup steps used by several test files (sign up, create an account, a student or a game session through the API) live in `test/support/api_helpers.rb`, which `test/test_helper.rb` requires and includes in every integration test. Helpers that act as a user take that user's token as an argument. No business logic in helpers, so each test can be understood by reading it.

Fixtures have explicit ids, and assertions compare against literal values (`2`, `"Test Teacher"`, `"profesor@example.com"`) instead of reading them back from the fixtures, so changing a fixture breaks the tests that depend on it. Responses whose exact shape matters (user, account and session data) are compared as a whole hash, which also fails if a field is added, such as `password_digest`.

### Controlled time

Date-dependent scenarios (streak, today's and this week's sessions, recovery token expiry) use `travel_to` to pin the day, so they do not fail depending on when they run.

### Emails without real delivery

Rails includes the Active Job helpers in tests, which enqueue jobs without running them, and the Action Mailer helpers. Recovery request scenarios assert that the email is (or is not) enqueued. For the reset, the test performs the enqueued job and reads the token from the link in the delivered email, without reading the database. Since `config/initializers/resend.rb` also sets SMTP in test, `test/test_helper.rb` sets the `:test` delivery method, so no test ever contacts Resend.

### Layout

One directory per capability and one file per requirement: `test/integration/api/v1/<capability>/<requirement>_test.rb`, both in snake_case (for example `authentication/login_test.rb` or `student_management/student_statistics_test.rb`). Classes follow the path with the nested modules the controllers use (`Api::V1::Authentication::LoginTest`); no app constant uses these capability names. Each file starts with a comment pointing to its spec and requirement.

Each test is named `"<Requirement>: <Scenario>"` (for example `"Password reset: Valid token"`). The requirement prefix keeps names unique and readable in test output, because several scenarios share a name ("Valid token", "Unknown student", "Missing token"). When a scenario lists several cases (a malformed, foreign or expired token; several kinds of invalid data), each case gets its own test named `"<Requirement>: <Scenario> (<case>)"`, for example `"Public sign-up: Privileged role requested (profesor)"`. Every scenario can be traced to at least one test.

### Local runs

The repository had no Docker Compose file for tests, so `docker-compose.test.yml` adds one: a PostgreSQL 16 service with the same credentials as CI and a `ruby` service (version from `.ruby-version`) that runs `bin/rails db:test:prepare test`. `DATABASE_URL` points it at the database container, so `config/database.yml` stays unchanged.

### CI

- `test` job: define `DB_PASSWORD` with the service password, remove the Chrome, `libvips` and `sqlite3` installation, and run `bin/rails db:test:prepare test` without `test:system`.
- Brakeman: remove `--ensure-latest` from `bin/brakeman`. Keeping Brakeman up to date is left to Dependabot, which is already configured upstream (it is not enabled by default on forks).
- Runners: `ubuntu-latest` is now Ubuntu 26.04, for which `ruby/setup-ruby` only builds the latest patch of each series, so Ruby 3.2.0 (`.ruby-version`) cannot be installed. The three jobs are pinned to `ubuntu-24.04` until the Ruby upgrade lands.
- Brakeman also reports two end-of-life notices (Ruby 3.2.0 and Rails 7.2.3) that are not code vulnerabilities. They are ignored with a note in `config/brakeman.ignore`; each upgrade will be its own change.
- RuboCop: `bin/rubocop -a` (safe corrections only) for the 16 current offenses.
- Schema: `db/schema.rb` was not regenerated after the data-only migration `20260821090000_rename_juegos_a_nombres_visibles`, so `rails/test_help` aborted every run with a pending migration error. Its version is bumped to that migration; no table changes.
- Branches: on the fork, protect `develop` and `main` so the three jobs must pass before merging.

## Risks / Trade-offs

- [Tests pin behavior that may be a bug, such as the streak counting up to the last session instead of today] → Intended: the goal is to detect changes. Fixing them will be an explicit change that modifies the spec and its test.
- [Sign-up reveals whether an email is already registered (422 "Email has already been taken"), unlike the password recovery request, which always answers with the same message] → Known behavior, pinned on purpose by the "Email already registered" scenario. A later `harden-authentication` change will make sign-up answer identically and add rate limiting to login, sign-up and password recovery; that change will modify the scenario and its test.
- [Authorization cases not covered in this public change] → They will be handled privately, and tests will be added once they are fixed.
- [Parallel tests share each process's database] → Each test runs in its own transaction; tests only rely on absolute counts for data they create themselves.
- [The Resend initializer forces SMTP in test too] → `test/test_helper.rb` sets `:test` delivery. If it were forgotten, delivery would fail for lack of a key instead of sending a real email.

## Migration Plan

No migration: neither data nor API change. Reverting the pull request rolls everything back.
