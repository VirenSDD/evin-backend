# Tasks

## 1. Clean test base

- [x] 1.1 Delete the Rails-generated tests (`test/controllers/`, `test/models/`, `test/mailers/` and `test/channels/`) and verify no `*_test.rb` file remains outside `test/integration/`
- [x] 1.2 Replace the fixtures with the minimal set from the design (one account per role and the catalog games) and verify `bin/rails db:fixtures:load RAILS_ENV=test` loads them without errors
- [x] 1.3 Add the generic helpers (token through the API, `Authorization` header, JSON response) and the `:test` email delivery to `test/test_helper.rb`, and verify `bin/rails test` finishes green with 0 tests
- [ ] 1.4 Document in `README.md` how to run the tests locally with Docker Compose and verify the steps work as written

## 2. Working CI

- [ ] 2.1 Define `DB_PASSWORD` in the `test` job, remove the Chrome, `libvips` and `sqlite3` installation and run `bin/rails db:test:prepare test` without `test:system`; verify the job passes on the pull request
- [x] 2.2 Remove `--ensure-latest` from `bin/brakeman` and verify the `scan_ruby` job passes with no warnings
- [x] 2.3 Apply `bin/rubocop -a` and verify the `lint` job passes and the diff only changes quotes and whitespace

## 3. Authentication

- [x] 3.1 Tests for login, sign-up and own profile from `specs/authentication/spec.md`, and verify they pass
- [x] 3.2 Tests for password recovery request and reset from `specs/authentication/spec.md`, using `travel_to` for expiry, and verify they pass without contacting Resend

## 4. Game catalog

- [x] 4.1 Tests for `specs/game-catalog/spec.md` and verify they pass without a token

## 5. Students

- [x] 5.1 Tests for listing, reading, creating, updating and deleting students from `specs/student-management/spec.md`, and verify they pass
- [x] 5.2 Tests for statistics (fields, no sessions, most played game, streak and trend) using `travel_to`, and verify they pass regardless of the system date

## 6. Game sessions

- [x] 6.1 Tests for recording and listing sessions from `specs/game-sessions/spec.md`, and verify they pass

## 7. Dashboard and users

- [x] 7.1 Tests for `specs/teacher-dashboard/spec.md` and verify they pass
- [ ] 7.2 Tests for `specs/user-management/spec.md` and verify they pass

## 8. Integration

- [ ] 8.1 Verify every scenario in the six specs has a test with the same name and the whole CI passes on the pull request
- [ ] 8.2 Protect `develop` and `main` on the fork so the `scan_ruby`, `lint` and `test` jobs are required before merging, and verify a pull request with a broken test cannot be merged

## Workflow follow-up

- Archive the change with OpenSpec once the implementation pull request is merged into `develop`.
- Check that `openspec/specs/` contains the six archived specs.
