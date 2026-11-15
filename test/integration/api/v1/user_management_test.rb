require "test_helper"

# specs/user-management/spec.md
class UserManagementTest < ActionDispatch::IntegrationTest
  MISSING_ID = 0

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
    post "/api/v1/alumnos", params: { nombre: "Visible Student" }, headers: auth_headers(token_for(:profesor)), as: :json
    account = register("New Teacher")

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
    account = register("Keeps Role")

    patch "/api/v1/users/#{account[:id]}", params: { rol: "superuser" }, headers: auth_headers(@admin_token), as: :json

    assert_response :unprocessable_entity
    assert_equal "padre", role_of(account[:id])
  end

  test "Role assignment: Administrator tries to remove their own role" do
    admin_id = 1

    patch "/api/v1/users/#{admin_id}", params: { rol: "profesor" }, headers: auth_headers(@admin_token), as: :json

    assert_response :unprocessable_entity
    assert_equal "tecnico", role_of(admin_id)
  end

  test "Role assignment: Unknown account" do
    patch "/api/v1/users/#{MISSING_ID}", params: { rol: "profesor" }, headers: auth_headers(@admin_token), as: :json

    assert_response :not_found
  end

  test "Role assignment: Teacher tries to assign a role" do
    account = register("Not Promoted")

    patch "/api/v1/users/#{account[:id]}", params: { rol: "tecnico" },
                                           headers: auth_headers(token_for(:profesor)), as: :json

    assert_response :forbidden
    assert_equal "padre", role_of(account[:id])
  end

  private

  # Signs up a family member account and returns its id and token.
  def register(nombre)
    post "/api/v1/register", params: { nombre: nombre, email: "#{nombre.parameterize}@example.com",
                                       password: PASSWORD, rol: "padre" }, as: :json
    assert_response :created
    { id: json["user"]["id"], token: json["token"] }
  end

  def role_of(user_id)
    get "/api/v1/users", headers: auth_headers(@admin_token)
    json.find { |user| user["id"] == user_id }["rol"]
  end
end
