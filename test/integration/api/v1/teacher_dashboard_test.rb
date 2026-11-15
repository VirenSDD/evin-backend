require "test_helper"

# specs/teacher-dashboard/spec.md
class TeacherDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = token_for(:profesor)
  end

  # --- Requirement: Activity overview ---

  test "Activity overview: Teacher reads the dashboard" do
    get "/api/v1/dashboard", headers: auth_headers(@teacher)

    assert_response :ok
    assert_equal %w[actividad_reciente activos_semana juegos_populares sesiones_hoy sesiones_semana sin_sesiones
                    tendencias total_alumnos total_sesiones],
                 json.keys.sort
    assert_equal %w[empeorando estable mejorando], json["tendencias"].keys.sort
  end

  test "Activity overview: Totals reflect recorded sessions" do
    travel_to Time.zone.local(2026, 3, 11, 12) do
      post "/api/v1/alumnos", params: { nombre: "Dashboard Player" }, headers: auth_headers(@teacher), as: :json
      alumno = json

      get "/api/v1/dashboard", headers: auth_headers(@teacher)
      before = json

      post "/api/v1/sesiones", params: { alumno: alumno["nombre"], alumno_id: alumno["id"], juego: "Puzzle",
                                         aciertos: 2, intentos: 4 },
                               headers: auth_headers(@teacher), as: :json
      assert_response :created
      sesion_id = json["id"]

      get "/api/v1/dashboard", headers: auth_headers(@teacher)

      assert_response :ok
      assert_equal before["total_sesiones"] + 1, json["total_sesiones"]
      assert_equal before["sesiones_hoy"] + 1, json["sesiones_hoy"]
      assert_equal sesion_id, json["actividad_reciente"].first["id"]
    end
  end

  test "Activity overview: Family member tries to read the dashboard" do
    get "/api/v1/dashboard", headers: auth_headers(token_for(:padre))

    assert_response :forbidden
  end

  test "Activity overview: Missing token" do
    get "/api/v1/dashboard"

    assert_response :unauthorized
  end
end
