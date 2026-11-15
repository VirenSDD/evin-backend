require "test_helper"

# specs/authentication/spec.md
class AuthenticationTest < ActionDispatch::IntegrationTest
  NEW_PASSWORD = "New-pass-456"

  # --- Requirement: Login ---

  test "Login: Valid credentials" do
    post "/api/v1/login", params: { email: "profesor@example.com", password: PASSWORD }, as: :json

    assert_response :ok
    assert json["token"].present?
    assert_equal({ "id" => 2, "nombre" => "Test Teacher", "email" => "profesor@example.com", "rol" => "profesor",
                   "alumno_id" => nil },
                 json["user"])
  end

  test "Login: Email in uppercase" do
    post "/api/v1/login", params: { email: "PROFESOR@EXAMPLE.COM", password: PASSWORD }, as: :json

    assert_response :ok
    assert json["token"].present?
  end

  test "Login: Wrong password" do
    post "/api/v1/login", params: { email: "profesor@example.com", password: "wrong-password" }, as: :json

    assert_response :unauthorized
    assert json["error"].present?
    assert_nil json["token"]
  end

  test "Login: Unknown user" do
    post "/api/v1/login", params: { email: "nobody@example.com", password: PASSWORD }, as: :json

    assert_response :unauthorized
  end

  # --- Requirement: Public sign-up ---

  test "Public sign-up: Sign-up as family member" do
    register(nombre: "New Family Member", email: "family@example.com", rol: "padre")

    assert_response :created
    assert json["token"].present?
    assert json["user"]["id"].present?
    assert_equal({ "id" => json["user"]["id"], "nombre" => "New Family Member", "email" => "family@example.com",
                   "rol" => "padre", "alumno_id" => nil },
                 json["user"])
  end

  test "Public sign-up: Sign-up as student creates the student record" do
    register(nombre: "New Student", email: "student@example.com", rol: "alumno")

    assert_response :created
    assert_equal "alumno", json["user"]["rol"]
    assert json["user"]["alumno_id"].present?
  end

  test "Public sign-up: Privileged role requested" do
    %w[profesor tecnico].each do |rol|
      register(nombre: "Wants #{rol}", email: "wants-#{rol}@example.com", rol: rol)

      assert_response :created
      assert_equal "alumno", json["user"]["rol"], "requested role #{rol}"
    end
  end

  test "Public sign-up: Email already registered" do
    register(nombre: "Someone Else", email: "profesor@example.com", rol: "padre")

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Public sign-up: Missing name" do
    register(nombre: nil, email: "no-name@example.com", rol: "padre")

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  # --- Requirement: Read own profile ---

  test "Read own profile: Valid token" do
    token = token_for(:padre)

    get "/api/v1/me", headers: auth_headers(token)

    assert_response :ok
    assert_equal({ "id" => 3, "nombre" => "Test Family Member", "email" => "padre@example.com", "rol" => "padre",
                   "alumno_id" => nil },
                 json["user"])
  end

  test "Read own profile: Missing token" do
    get "/api/v1/me"

    assert_response :unauthorized
  end

  test "Read own profile: Tampered or expired token" do
    get "/api/v1/me", headers: auth_headers("not-a-jwt")
    assert_response :unauthorized, "malformed token"

    foreign_token = JWT.encode({ user_id: 3, exp: 1.hour.from_now.to_i }, "another-key", "HS256")
    get "/api/v1/me", headers: auth_headers(foreign_token)
    assert_response :unauthorized, "token signed with another key"

    token = token_for(:padre)
    travel 25.hours do
      get "/api/v1/me", headers: auth_headers(token)
      assert_response :unauthorized, "expired token"
    end
  end

  # --- Requirement: Edit own profile ---

  test "Edit own profile: Change name" do
    token = token_for(:padre)

    patch "/api/v1/me", params: { nombre: "Renamed Family" }, headers: auth_headers(token), as: :json

    assert_response :ok
    assert json["token"].present?
    assert_equal({ "id" => 3, "nombre" => "Renamed Family", "email" => "padre@example.com", "rol" => "padre",
                   "alumno_id" => nil },
                 json["user"])
  end

  test "Edit own profile: Change password with the current password" do
    email = "padre@example.com"
    token = login(email, PASSWORD)

    patch "/api/v1/me", params: { password: NEW_PASSWORD, password_actual: PASSWORD },
                        headers: auth_headers(token), as: :json

    assert_response :ok
    assert login(email, NEW_PASSWORD).present?, "login with the new password"
    assert_nil login(email, PASSWORD), "login with the old password"
  end

  test "Edit own profile: Change password without the correct current password" do
    email = "padre@example.com"
    token = login(email, PASSWORD)

    [ { password_actual: "wrong-password" }, {} ].each do |current|
      patch "/api/v1/me", params: { password: NEW_PASSWORD, **current }, headers: auth_headers(token), as: :json

      assert_response :unprocessable_entity
    end
    assert login(email, PASSWORD).present?, "login with the old password"
    assert_nil login(email, NEW_PASSWORD), "login with the new password"
  end

  # --- Requirement: Password recovery request ---

  test "Password recovery request: Registered email" do
    assert_enqueued_emails 1 do
      post "/api/v1/password/forgot", params: { email: "padre@example.com" }, as: :json
    end

    assert_response :ok
    assert json["message"].present?
    perform_enqueued_jobs
    assert_equal [ "padre@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "Password recovery request: Unregistered email" do
    post "/api/v1/password/forgot", params: { email: "padre@example.com" }, as: :json
    generic_message = json["message"]

    assert_no_enqueued_emails do
      post "/api/v1/password/forgot", params: { email: "nobody@example.com" }, as: :json
    end

    assert_response :ok
    assert_equal generic_message, json["message"]
  end

  # --- Requirement: Password reset ---

  test "Password reset: Valid token" do
    email = "padre@example.com"
    token = request_recovery_token(email)

    post "/api/v1/password/reset", params: { token: token, password: NEW_PASSWORD }, as: :json

    assert_response :ok
    assert login(email, NEW_PASSWORD).present?, "login with the new password"

    post "/api/v1/password/reset", params: { token: token, password: "Another-pass-789" }, as: :json
    assert_response :unprocessable_entity, "the token is accepted only once"
  end

  test "Password reset: Expired token" do
    email = "padre@example.com"
    token = request_recovery_token(email)

    travel 2.hours + 1.minute do
      post "/api/v1/password/reset", params: { token: token, password: NEW_PASSWORD }, as: :json

      assert_response :unprocessable_entity
      assert login(email, PASSWORD).present?, "the password does not change"
    end
  end

  test "Password reset: Unknown token" do
    post "/api/v1/password/reset", params: { token: "unknown-token", password: NEW_PASSWORD }, as: :json

    assert_response :unprocessable_entity
  end

  private

  def register(nombre:, email:, rol:)
    post "/api/v1/register", params: { nombre: nombre, email: email, password: PASSWORD, rol: rol }, as: :json
  end

  # Requests a recovery email, delivers it and reads the token from its link.
  def request_recovery_token(email)
    perform_enqueued_jobs do
      post "/api/v1/password/forgot", params: { email: email }, as: :json
    end
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ email ], mail.to
    mail.text_part.body.decoded[/reset_token=([\w-]+)/, 1].tap { |token| assert token.present? }
  end
end
