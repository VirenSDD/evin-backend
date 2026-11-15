# Spec Delta

## Purpose

Lets the platform administrator (the `tecnico` role) see every account and assign roles, which is the only way to obtain the `profesor` and `tecnico` roles.

## ADDED Requirements

### Requirement: Account listing
The system SHALL return every account ordered by name to the administrator, without password data, and SHALL deny it to every other role.

#### Scenario: Administrator lists accounts
- **WHEN** a user with the `tecnico` role sends `GET /api/v1/users`
- **THEN** the response is 200 with every account ordered by `nombre`, each with only `id`, `nombre`, `email` and `rol`

#### Scenario: Teacher tries to list accounts
- **WHEN** a teacher sends `GET /api/v1/users`
- **THEN** the response is 403

### Requirement: Role assignment
The system SHALL let the administrator change an account's role to `alumno`, `profesor`, `tecnico` or `padre`, and SHALL prevent the administrator from removing their own `tecnico` role.

#### Scenario: Administrator assigns the teacher role
- **WHEN** a user with the `tecnico` role sends `PATCH /api/v1/users/:id` with `rol` set to `profesor`
- **THEN** the response is 200 with the account and its new role, and that account can then list students

#### Scenario: Unknown role
- **WHEN** a user with the `tecnico` role sends `PATCH /api/v1/users/:id` with a role that does not exist
- **THEN** the response is 422 and the role does not change

#### Scenario: Administrator tries to remove their own role
- **WHEN** a user with the `tecnico` role sends `PATCH /api/v1/users/:id` with their own id and a role other than `tecnico`
- **THEN** the response is 422 and they remain `tecnico`

#### Scenario: Unknown account
- **WHEN** a user with the `tecnico` role sends `PATCH /api/v1/users/:id` with an id that does not exist
- **THEN** the response is 404

#### Scenario: Teacher tries to assign a role
- **WHEN** a teacher sends `PATCH /api/v1/users/:id`
- **THEN** the response is 403 and the role does not change
