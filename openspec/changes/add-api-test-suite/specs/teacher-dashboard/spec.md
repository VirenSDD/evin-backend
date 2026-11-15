# Spec Delta

## Purpose

Gives teachers and technicians an overview of all students' activity: totals, this week's activity, inactive students, most played games and trends.

## ADDED Requirements

### Requirement: Activity overview
The system SHALL return the activity overview to teachers and technicians and SHALL deny it to every other role.

#### Scenario: Teacher reads the dashboard
- **WHEN** a teacher sends `GET /api/v1/dashboard`
- **THEN** the response is 200 with `total_alumnos`, `total_sesiones`, `sesiones_hoy`, `sesiones_semana`, `activos_semana`, `sin_sesiones`, `juegos_populares`, `actividad_reciente` and `tendencias` with `mejorando`, `empeorando` and `estable`

#### Scenario: Totals reflect recorded sessions
- **WHEN** a session dated today is recorded and a teacher then reads the dashboard
- **THEN** `total_sesiones` and `sesiones_hoy` increase by one and the session appears first in `actividad_reciente`

#### Scenario: Family member tries to read the dashboard
- **WHEN** a user with the `padre` role sends `GET /api/v1/dashboard`
- **THEN** the response is 403

#### Scenario: Missing token
- **WHEN** `GET /api/v1/dashboard` is sent without an `Authorization` header
- **THEN** the response is 401
