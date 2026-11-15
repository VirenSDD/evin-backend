# Spec Delta

## Purpose

Lets professionals, families and students create an account, log in with a token, read and edit their own profile, and recover their password by email.

## ADDED Requirements

### Requirement: Login
The system SHALL return an access token and the user data when the email and password are correct, treating the email case-insensitively, and SHALL reject wrong credentials.

#### Scenario: Valid credentials
- **WHEN** `POST /api/v1/login` is sent with the email and password of an existing user
- **THEN** the response is 200 with a `token` and a `user` with `id`, `nombre`, `email`, `rol` and `alumno_id`

#### Scenario: Email in uppercase
- **WHEN** `POST /api/v1/login` is sent with an existing user's email in uppercase and their password
- **THEN** the response is 200 with a `token`

#### Scenario: Wrong password
- **WHEN** `POST /api/v1/login` is sent with an existing email and a wrong password
- **THEN** the response is 401 with an error message and no `token`

#### Scenario: Unknown user
- **WHEN** `POST /api/v1/login` is sent with an email that is not registered
- **THEN** the response is 401

### Requirement: Public sign-up
The system SHALL create a new account and return its token. Public sign-up SHALL accept only the `alumno` and `padre` roles; any other requested role SHALL become `alumno`.

#### Scenario: Sign-up as family member
- **WHEN** `POST /api/v1/register` is sent with a name, a new email, a password and role `padre`
- **THEN** the response is 201 with a `token` and a `user` with role `padre`

#### Scenario: Sign-up as student creates the student record
- **WHEN** `POST /api/v1/register` is sent with a name no student has, a new email, a password and role `alumno`
- **THEN** the response is 201 and the returned `user` has role `alumno` and a non-empty `alumno_id`

#### Scenario: Privileged role requested
- **WHEN** `POST /api/v1/register` is sent with role `profesor` or `tecnico`
- **THEN** the response is 201 and the returned `user` has role `alumno`

#### Scenario: Email already registered
- **WHEN** `POST /api/v1/register` is sent with an email that already exists
- **THEN** the response is 422 with an `errors` list

#### Scenario: Missing name
- **WHEN** `POST /api/v1/register` is sent without a name
- **THEN** the response is 422 with an `errors` list

### Requirement: Read own profile
The system SHALL return the data of the user identified by the token and SHALL reject requests without a valid token.

#### Scenario: Valid token
- **WHEN** `GET /api/v1/me` is sent with a valid token
- **THEN** the response is 200 with a `user` whose data belongs to the token owner

#### Scenario: Missing token
- **WHEN** `GET /api/v1/me` is sent without an `Authorization` header
- **THEN** the response is 401

#### Scenario: Tampered or expired token
- **WHEN** `GET /api/v1/me` is sent with a malformed token, a token signed with another key, or an expired token
- **THEN** the response is 401

### Requirement: Edit own profile
The system SHALL let users change their name and email, and SHALL require the current password to change the password.

#### Scenario: Change name
- **WHEN** `PATCH /api/v1/me` is sent with a valid token and a new name
- **THEN** the response is 200 with a new `token` and the `user` with the updated name

#### Scenario: Change password with the current password
- **WHEN** `PATCH /api/v1/me` is sent with a new `password` and the correct `password_actual`
- **THEN** the response is 200 and from then on login works with the new password and not with the old one

#### Scenario: Change password without the correct current password
- **WHEN** `PATCH /api/v1/me` is sent with a new `password` and a wrong or missing `password_actual`
- **THEN** the response is 422 and the password does not change

### Requirement: Password recovery request
The system SHALL always answer with the same generic message, whether or not the email exists, and SHALL send the recovery email only when the account exists.

#### Scenario: Registered email
- **WHEN** `POST /api/v1/password/forgot` is sent with an existing user's email
- **THEN** the response is 200 with the generic message and a recovery email for that user is enqueued

#### Scenario: Unregistered email
- **WHEN** `POST /api/v1/password/forgot` is sent with an email that does not exist
- **THEN** the response is 200 with the same generic message and no email is enqueued

### Requirement: Password reset
The system SHALL change the password when the recovery token exists and is less than 2 hours old, and SHALL invalidate the token once used.

#### Scenario: Valid token
- **WHEN** `POST /api/v1/password/reset` is sent with a recovery token issued less than 2 hours ago and a new password
- **THEN** the response is 200, login works with the new password and the same token is no longer accepted

#### Scenario: Expired token
- **WHEN** `POST /api/v1/password/reset` is sent with a token issued more than 2 hours ago
- **THEN** the response is 422 and the password does not change

#### Scenario: Unknown token
- **WHEN** `POST /api/v1/password/reset` is sent with a token that does not exist
- **THEN** the response is 422
