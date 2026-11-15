require "test_helper"

# specs/game-sessions/spec.md
class GameSessionsTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_token = token_for(:profesor)
    @alumno = create_alumno(@teacher_token, nombre: "Session Player")
  end

  # --- Requirement: Record a game session ---

  test "Record a game session: Session of a catalog game" do
    travel_to Time.zone.local(2026, 3, 11, 12) do
      post_sesion(@teacher_token, @alumno, juego: "Puzzle", aciertos: 3, intentos: 4)
    end

    assert_response :created
    assert json["id"].present?
    assert_equal({ "id" => json["id"], "alumno_nombre" => "Session Player", "juego_nombre" => "Puzzle",
                   "fecha" => "2026-03-11", "aciertos" => 3, "intentos" => 4, "alumno_id" => @alumno["id"],
                   "juego_id" => 6, "porcentaje" => 75 },
                 json)
  end

  test "Record a game session: Session of a game not in the catalog" do
    post_sesion(@teacher_token, @alumno, juego: "Not In The Catalog")

    assert_response :created
    assert_equal "Not In The Catalog", json["juego_nombre"]
    assert_nil json["juego_id"]
  end

  test "Record a game session: More hits than attempts" do
    post_sesion(@teacher_token, @alumno, aciertos: 5, intentos: 4)

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Record a game session: Incomplete or invalid data (missing student name)" do
    post_sesion(@teacher_token, @alumno, alumno: nil, alumno_id: nil)

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Record a game session: Incomplete or invalid data (missing game)" do
    post_sesion(@teacher_token, @alumno, juego: nil)

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Record a game session: Incomplete or invalid data (zero attempts)" do
    post_sesion(@teacher_token, @alumno, intentos: 0)

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Record a game session: Incomplete or invalid data (negative hits)" do
    post_sesion(@teacher_token, @alumno, aciertos: -1)

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Record a game session: Missing token" do
    post "/api/v1/sesiones", params: sesion_params(@alumno), as: :json

    assert_response :unauthorized
    get "/api/v1/sesiones", headers: auth_headers(@teacher_token)
    assert_empty json
  end

  # --- Requirement: List game sessions ---

  test "List game sessions: Teacher lists every session" do
    record_sesion(@teacher_token, @alumno, fecha: "2026-03-02")
    record_sesion(@teacher_token, @alumno, fecha: "2026-03-09")
    record_sesion(@teacher_token, @alumno, fecha: "2026-03-05")

    get "/api/v1/sesiones", headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal [ "2026-03-09", "2026-03-05", "2026-03-02" ], json.map { |sesion| sesion["fecha"] }
  end

  test "List game sessions: Filter by student" do
    other = create_alumno(@teacher_token, nombre: "Other Player")
    record_sesion(@teacher_token, @alumno)
    record_sesion(@teacher_token, @alumno)
    record_sesion(@teacher_token, other)

    get "/api/v1/sesiones", params: { alumno_id: @alumno["id"] }, headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal [ @alumno["id"] ] * 2, json.map { |sesion| sesion["alumno_id"] }
  end

  test "List game sessions: Filter by game" do
    record_sesion(@teacher_token, @alumno, juego: "Puzzle")
    record_sesion(@teacher_token, @alumno, juego: "Exploraciones")
    record_sesion(@teacher_token, @alumno, juego: "Puzzle")

    get "/api/v1/sesiones", params: { juego: "PUZZ" }, headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal [ "Puzzle" ] * 2, json.map { |sesion| sesion["juego_nombre"] }
  end

  test "List game sessions: Missing token" do
    get "/api/v1/sesiones"

    assert_response :unauthorized
  end

  private

  def sesion_params(alumno, **overrides)
    { alumno: alumno["nombre"], alumno_id: alumno["id"], juego: "Puzzle", aciertos: 3, intentos: 4 }
      .merge(overrides).compact
  end

  def post_sesion(token, alumno, **overrides)
    post "/api/v1/sesiones", params: sesion_params(alumno, **overrides), headers: auth_headers(token), as: :json
  end
end
