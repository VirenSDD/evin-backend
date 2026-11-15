# Spec Delta

## Purpose

Gives any visitor, with or without an account, the list of visual stimulation games available in EVIN with their description, level and type.

## ADDED Requirements

### Requirement: Public catalog listing
The system SHALL return every game ordered by name, without requiring authentication.

#### Scenario: Without a token
- **WHEN** `GET /api/v1/juegos` is sent without an `Authorization` header
- **THEN** the response is 200 with a list of games ordered by `nombre`

#### Scenario: Fields of each game
- **WHEN** `GET /api/v1/juegos` is sent
- **THEN** each item includes `id`, `nombre`, `descripcion`, `img`, `nivel` and `tipo`
