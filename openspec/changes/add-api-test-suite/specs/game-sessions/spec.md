# Spec Delta

## Purpose

Stores the result of each played game (student, game, date, hits and attempts) and lets professionals list them to follow each student's progress.

## ADDED Requirements

### Requirement: Record a game session
The system SHALL store a game session sent by an authenticated user and return it with its hit percentage. When no date is given, the system SHALL use the current date.

#### Scenario: Session of a catalog game
- **WHEN** a teacher sends `POST /api/v1/sesiones` with `alumno`, `alumno_id`, `juego` equal to the name of a catalog game, `aciertos` 3 and `intentos` 4
- **THEN** the response is 201 with `id`, `alumno_nombre`, `juego_nombre`, today's `fecha`, `aciertos`, `intentos`, `alumno_id`, the game's `juego_id` and `porcentaje` 75

#### Scenario: Session of a game not in the catalog
- **WHEN** a teacher sends `POST /api/v1/sesiones` with a game name that does not exist in the catalog
- **THEN** the response is 201, the session stores that `juego_nombre` and its `juego_id` is empty

#### Scenario: More hits than attempts
- **WHEN** `POST /api/v1/sesiones` is sent with `aciertos` greater than `intentos`
- **THEN** the response is 422 with an `errors` list

#### Scenario: Incomplete or invalid data
- **WHEN** `POST /api/v1/sesiones` is sent without a student name, without a game, with `intentos` 0, or with negative `aciertos`
- **THEN** the response is 422 with an `errors` list

#### Scenario: Missing token
- **WHEN** `POST /api/v1/sesiones` is sent without an `Authorization` header
- **THEN** the response is 401 and no session is stored

### Requirement: List game sessions
The system SHALL return game sessions from newest to oldest, with optional filters by student and by game.

#### Scenario: Teacher lists every session
- **WHEN** a teacher sends `GET /api/v1/sesiones`
- **THEN** the response is 200 with the sessions ordered by `fecha` descending

#### Scenario: Filter by student
- **WHEN** a teacher sends `GET /api/v1/sesiones?alumno_id=<id>`
- **THEN** the response contains only that student's sessions

#### Scenario: Filter by game
- **WHEN** a teacher sends `GET /api/v1/sesiones?juego=<text>`
- **THEN** the response contains only the sessions whose game name includes that text, case-insensitively

#### Scenario: Missing token
- **WHEN** `GET /api/v1/sesiones` is sent without an `Authorization` header
- **THEN** the response is 401
