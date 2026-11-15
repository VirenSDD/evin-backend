require "test_helper"

# specs/game-sessions/spec.md
class GameSessionsTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_token = token_for(:profesor)
    @alumno = create_alumno("Session Player")
  end

  # --- Requirement: Record a game session ---

  test "Record a game session: Session of a catalog game" do
    get "/api/v1/juegos"
    puzzle_id = json.find { |juego| juego["nombre"] == "Puzzle" }["id"]

    travel_to Time.zone.local(2026, 3, 11, 12) do
      post_sesion(juego: "Puzzle", aciertos: 3, intentos: 4)
    end

    assert_response :created
    assert json["id"].present?
    assert_equal "Session Player", json["alumno_nombre"]
    assert_equal "Puzzle", json["juego_nombre"]
    assert_equal "2026-03-11", json["fecha"]
    assert_equal 3, json["aciertos"]
    assert_equal 4, json["intentos"]
    assert_equal @alumno["id"], json["alumno_id"]
    assert_equal puzzle_id, json["juego_id"]
    assert_equal 75, json["porcentaje"]
  end

  test "Record a game session: Session of a game not in the catalog" do
    post_sesion(juego: "Not In The Catalog")

    assert_response :created
    assert_equal "Not In The Catalog", json["juego_nombre"]
    assert_nil json["juego_id"]
  end

  test "Record a game session: More hits than attempts" do
    post_sesion(aciertos: 5, intentos: 4)

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Record a game session: Incomplete or invalid data" do
    [ { alumno: nil, alumno_id: nil }, { juego: nil }, { intentos: 0 }, { aciertos: -1 } ].each do |invalid|
      post_sesion(**invalid)

      assert_response :unprocessable_entity, "invalid #{invalid}"
      assert_kind_of Array, json["errors"]
      assert_not_empty json["errors"]
    end
  end

  test "Record a game session: Missing token" do
    post "/api/v1/sesiones", params: sesion_params, as: :json

    assert_response :unauthorized
    get "/api/v1/sesiones", headers: auth_headers(@teacher_token)
    assert_empty json
  end

  # --- Requirement: List game sessions ---

  test "List game sessions: Teacher lists every session" do
    post_sesion(fecha: "2026-03-02")
    post_sesion(fecha: "2026-03-09")
    post_sesion(fecha: "2026-03-05")

    get "/api/v1/sesiones", headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal [ "2026-03-09", "2026-03-05", "2026-03-02" ], json.map { |sesion| sesion["fecha"] }
  end

  test "List game sessions: Filter by student" do
    other = create_alumno("Other Player")
    post_sesion
    post_sesion
    post_sesion(alumno: other["nombre"], alumno_id: other["id"])

    get "/api/v1/sesiones", params: { alumno_id: @alumno["id"] }, headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal [ @alumno["id"] ] * 2, json.map { |sesion| sesion["alumno_id"] }
  end

  test "List game sessions: Filter by game" do
    post_sesion(juego: "Puzzle")
    post_sesion(juego: "Exploraciones")
    post_sesion(juego: "Puzzle")

    get "/api/v1/sesiones", params: { juego: "PUZZ" }, headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal [ "Puzzle" ] * 2, json.map { |sesion| sesion["juego_nombre"] }
  end

  test "List game sessions: Missing token" do
    get "/api/v1/sesiones"

    assert_response :unauthorized
  end

  private

  def create_alumno(nombre)
    post "/api/v1/alumnos", params: { nombre: nombre }, headers: auth_headers(@teacher_token), as: :json
    assert_response :created
    json
  end

  def sesion_params(**overrides)
    { alumno: @alumno["nombre"], alumno_id: @alumno["id"], juego: "Puzzle", aciertos: 3, intentos: 4 }
      .merge(overrides).compact
  end

  def post_sesion(**overrides)
    post "/api/v1/sesiones", params: sesion_params(**overrides), headers: auth_headers(@teacher_token), as: :json
  end
end
