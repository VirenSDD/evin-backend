require "test_helper"

# specs/user-management/spec.md
class UserManagementTest < ActionDispatch::IntegrationTest
  setup do
    @admin_token = token_for(:tecnico)
  end

  # --- Requirement: Account listing ---

  test "Account listing: Administrator lists accounts" do
    get "/api/v1/users", headers: auth_headers(@admin_token)

    assert_response :ok
    assert_equal [ { "id" => 1, "nombre" => "Test Administrator", "email" => "tecnico@example.com", "rol" => "tecnico" },
                   { "id" => 3, "nombre" => "Test Family Member", "email" => "padre@example.com", "rol" => "padre" },
                   { "id" => 2, "nombre" => "Test Teacher", "email" => "profesor@example.com", "rol" => "profesor" } ],
                 json
  end

  test "Account listing: Teacher tries to list accounts" do
    get "/api/v1/users", headers: auth_headers(token_for(:profesor))

    assert_response :forbidden
  end

  # --- Requirement: Role assignment ---

  test "Role assignment: Administrator assigns the teacher role" do
    create_alumno(token_for(:profesor), nombre: "Visible Student")
    account = create_account(nombre: "New Teacher", email: "new-teacher@example.com", password: PASSWORD,
                             rol: "padre")

    patch "/api/v1/users/#{account[:id]}", params: { rol: "profesor" }, headers: auth_headers(@admin_token), as: :json

    assert_response :ok
    assert_equal({ "id" => account[:id], "nombre" => "New Teacher", "email" => "new-teacher@example.com",
                   "rol" => "profesor" },
                 json)

    get "/api/v1/alumnos", headers: auth_headers(account[:token])
    assert_response :ok
    assert_includes json.map { |alumno| alumno["nombre"] }, "Visible Student"
  end

  test "Role assignment: Unknown role" do
    account = create_account(nombre: "Keeps Role", email: "keeps-role@example.com", password: PASSWORD,
                             rol: "padre")

    patch "/api/v1/users/#{account[:id]}", params: { rol: "superuser" }, headers: auth_headers(@admin_token), as: :json

    assert_response :unprocessable_entity
    assert_equal "padre", role_of(@admin_token, account[:id])
  end

  test "Role assignment: Administrator tries to remove their own role" do
    admin_id = 1

    patch "/api/v1/users/#{admin_id}", params: { rol: "profesor" }, headers: auth_headers(@admin_token), as: :json

    assert_response :unprocessable_entity
    assert_equal "tecnico", role_of(@admin_token, admin_id)
  end

  test "Role assignment: Unknown account" do
    patch "/api/v1/users/#{MISSING_ID}", params: { rol: "profesor" }, headers: auth_headers(@admin_token), as: :json

    assert_response :not_found
  end

  test "Role assignment: Teacher tries to assign a role" do
    account = create_account(nombre: "Not Promoted", email: "not-promoted@example.com", password: PASSWORD,
                             rol: "padre")

    patch "/api/v1/users/#{account[:id]}", params: { rol: "tecnico" },
                                           headers: auth_headers(token_for(:profesor)), as: :json

    assert_response :forbidden
    assert_equal "padre", role_of(@admin_token, account[:id])
  end

  private

  def role_of(token, user_id)
    get "/api/v1/users", headers: auth_headers(token)
    json.find { |user| user["id"] == user_id }["rol"]
  end
end
