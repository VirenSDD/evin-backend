require "test_helper"

# specs/teacher-dashboard/spec.md
class TeacherDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_token = token_for(:profesor)
  end

  # --- Requirement: Activity overview ---

  test "Activity overview: Teacher reads the dashboard" do
    get "/api/v1/dashboard", headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal %w[actividad_reciente activos_semana juegos_populares sesiones_hoy sesiones_semana sin_sesiones
                    tendencias total_alumnos total_sesiones],
                 json.keys.sort
    assert_equal %w[empeorando estable mejorando], json["tendencias"].keys.sort
  end

  test "Activity overview: Totals reflect recorded sessions" do
    travel_to Time.zone.local(2026, 3, 11, 12) do
      alumno = create_alumno(@teacher_token, nombre: "Dashboard Player")

      get "/api/v1/dashboard", headers: auth_headers(@teacher_token)
      before = json

      sesion = record_sesion(@teacher_token, alumno, juego: "Puzzle", aciertos: 2, intentos: 4)

      get "/api/v1/dashboard", headers: auth_headers(@teacher_token)

      assert_response :ok
      assert_equal before["total_sesiones"] + 1, json["total_sesiones"]
      assert_equal before["sesiones_hoy"] + 1, json["sesiones_hoy"]
      assert_equal sesion["id"], json["actividad_reciente"].first["id"]
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
