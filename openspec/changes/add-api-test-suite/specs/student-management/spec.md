# Spec Delta

## Purpose

Lets teachers and technicians create, read, update and delete students, and read each student's activity statistics.

## ADDED Requirements

### Requirement: Student listing
The system SHALL return every student ordered by name to teachers and technicians, and only their own record to a user with the `alumno` role.

#### Scenario: Teacher lists students
- **WHEN** a teacher sends `GET /api/v1/alumnos`
- **THEN** the response is 200 with every student ordered by `nombre`, each with `id`, `nombre`, `edad`, `curso`, `dificultad`, `progreso` and `img`

#### Scenario: Student lists students
- **WHEN** a user with the `alumno` role sends `GET /api/v1/alumnos`
- **THEN** the response is 200 with a list containing only their own record

#### Scenario: Missing token
- **WHEN** `GET /api/v1/alumnos` is sent without an `Authorization` header
- **THEN** the response is 401

### Requirement: Read a student
The system SHALL return a student record to teachers, technicians and the student themselves, and SHALL answer 404 when it does not exist.

#### Scenario: Teacher reads a student
- **WHEN** a teacher sends `GET /api/v1/alumnos/:id` for an existing student
- **THEN** the response is 200 with the student record

#### Scenario: Student reads their own record
- **WHEN** a user with the `alumno` role sends `GET /api/v1/alumnos/:id` with the id of their own record
- **THEN** the response is 200

#### Scenario: Student reads another record
- **WHEN** a user with the `alumno` role sends `GET /api/v1/alumnos/:id` with another student's id
- **THEN** the response is 403

#### Scenario: Unknown student
- **WHEN** a teacher sends `GET /api/v1/alumnos/:id` with an id that does not exist
- **THEN** the response is 404

### Requirement: Create students
The system SHALL allow only teachers and technicians to create students, and SHALL validate a required name, an age between 1 and 99, a difficulty of `Fácil`, `Medio` or `Difícil`, and a progress between 0 and 100.

#### Scenario: Teacher creates a student
- **WHEN** a teacher sends `POST /api/v1/alumnos` with a valid name, age, course, difficulty and progress
- **THEN** the response is 201 with the created record, which then appears in the listing

#### Scenario: Family member tries to create a student
- **WHEN** a user with the `padre` role sends `POST /api/v1/alumnos`
- **THEN** the response is 403 and no student is created

#### Scenario: Invalid data
- **WHEN** a teacher sends `POST /api/v1/alumnos` without a name, with age 150, or with a difficulty that does not exist
- **THEN** the response is 422 with an `errors` list

### Requirement: Update students
The system SHALL allow only teachers and technicians to update students, with the same validations as creation.

#### Scenario: Teacher updates a student
- **WHEN** a teacher sends `PATCH /api/v1/alumnos/:id` with a new course
- **THEN** the response is 200 with the updated record

#### Scenario: Family member tries to update a student
- **WHEN** a user with the `padre` role sends `PATCH /api/v1/alumnos/:id`
- **THEN** the response is 403 and the record does not change

#### Scenario: Unknown student
- **WHEN** a teacher sends `PATCH /api/v1/alumnos/:id` with an id that does not exist
- **THEN** the response is 404

### Requirement: Delete students
The system SHALL allow only teachers and technicians to delete students. When the student has a linked user account, the system SHALL delete that account as well.

#### Scenario: Teacher deletes a student without an account
- **WHEN** a teacher sends `DELETE /api/v1/alumnos/:id` for a student with no linked account
- **THEN** the response is 200 and a later read of that student answers 404

#### Scenario: Teacher deletes a student with an account
- **WHEN** a teacher sends `DELETE /api/v1/alumnos/:id` for a student who signed up with their own account
- **THEN** the response is 200 and logging in with that account no longer works

#### Scenario: Family member tries to delete a student
- **WHEN** a user with the `padre` role sends `DELETE /api/v1/alumnos/:id`
- **THEN** the response is 403 and the student still exists

### Requirement: Student statistics
The system SHALL return to teachers and technicians a student's activity statistics, computed from their game sessions.

#### Scenario: Statistics fields
- **WHEN** a teacher sends `GET /api/v1/alumnos/:id/estadisticas`
- **THEN** the response is 200 with `sesiones_totales`, `sesiones_semana`, `ultima_sesion`, `juegos_practicados`, `juego_favorito`, `racha_dias` and `tendencia`

#### Scenario: Student without sessions
- **WHEN** a teacher reads the statistics of a student with no sessions
- **THEN** `sesiones_totales` and `racha_dias` are 0 and `tendencia` is `sin_datos`

#### Scenario: Most played game
- **WHEN** a student has more sessions of one game than of any other
- **THEN** `juego_favorito` is that game and `juegos_practicados` contains every game they have played

#### Scenario: Streak of consecutive days
- **WHEN** a student has sessions on three consecutive days and none on the day before the first one
- **THEN** `racha_dias` is 3, counting backwards from their last session

#### Scenario: Trend with few sessions
- **WHEN** a student has fewer than 4 sessions
- **THEN** `tendencia` is `sin_datos`

#### Scenario: Improving trend
- **WHEN** a student has at least 4 sessions and the average hit rate of the most recently recorded half is more than 5 points higher than that of the earlier half (by recording order, not by session date)
- **THEN** `tendencia` is `mejorando`

#### Scenario: Unknown student
- **WHEN** a teacher sends `GET /api/v1/alumnos/:id/estadisticas` with an id that does not exist
- **THEN** the response is 404
