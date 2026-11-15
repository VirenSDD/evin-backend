# EVIN backend

Rails 7.2 API (Ruby 3.2.0, PostgreSQL 16) for EVIN, a visual stimulation platform.

## Running the tests

The test suite is made of integration tests in `test/integration/api/v1/`, with
one directory per capability in `openspec/changes/add-api-test-suite/specs/` and
one file per requirement (for example `authentication/login_test.rb`). They only
use the HTTP API, so they do not depend on the internal structure of the app.
Helpers shared by several files are in `test/support/api_helpers.rb`.

### With Docker Compose (no local Ruby needed)

```sh
docker compose -f docker-compose.test.yml run --rm test
docker compose -f docker-compose.test.yml down
```

The first command starts PostgreSQL, installs the gems into a cached volume,
prepares the test database and runs `bin/rails test`. To run a single file or
the linters, pass the command explicitly (a directory runs a whole capability):

```sh
docker compose -f docker-compose.test.yml run --rm test \
  bash -c "bundle install --quiet && bin/rails db:test:prepare && bin/rails test test/integration/api/v1/authentication/login_test.rb"
docker compose -f docker-compose.test.yml run --rm test \
  bash -c "bundle install --quiet && bin/rubocop && bin/brakeman --no-pager"
```

Add `-v` to `down` to also remove the cached gems volume.

### With a local Ruby

With Ruby 3.2.0 and a PostgreSQL server on `localhost` whose `evin` user has
the password in `DB_PASSWORD`:

```sh
bundle install
DB_PASSWORD=<password> bin/rails db:test:prepare test
```

### Continuous integration

`.github/workflows/ci.yml` runs Brakeman (`scan_ruby`), RuboCop (`lint`) and
the test suite (`test`) on every pull request.
