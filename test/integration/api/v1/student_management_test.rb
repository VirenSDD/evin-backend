require "test_helper"

# specs/student-management/spec.md
class StudentManagementTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_token = token_for(:profesor)
  end

  # --- Requirement: Student listing ---

  test "Student listing: Teacher lists students" do
    create_alumno(@teacher_token, nombre: "Zoe Student")
    create_alumno(@teacher_token, nombre: "Adam Student")

    get "/api/v1/alumnos", headers: auth_headers(@teacher_token)

    assert_response :ok
    names = json.map { |alumno| alumno["nombre"] }
    assert_equal [ "Adam Student", "Zoe Student" ], names
    json.each do |alumno|
      assert_empty %w[id nombre edad curso dificultad progreso img] - alumno.keys
    end
  end

  test "Student listing: Student lists students" do
    create_alumno(@teacher_token, nombre: "Another Student")
    student = create_account(nombre: "Signed-up Student", email: "signed-up-student@example.com", password: PASSWORD,
                             rol: "alumno")

    get "/api/v1/alumnos", headers: auth_headers(student[:token])

    assert_response :ok
    assert_equal [ student[:alumno_id] ], json.map { |alumno| alumno["id"] }
  end

  test "Student listing: Missing token" do
    get "/api/v1/alumnos"

    assert_response :unauthorized
  end

  # --- Requirement: Read a student ---

  test "Read a student: Teacher reads a student" do
    alumno = create_alumno(@teacher_token, nombre: "Read Me")

    get "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_equal alumno["id"], json["id"]
    assert_equal "Read Me", json["nombre"]
  end

  test "Read a student: Student reads their own record" do
    student = create_account(nombre: "Self Reader", email: "self-reader@example.com", password: PASSWORD,
                             rol: "alumno")

    get "/api/v1/alumnos/#{student[:alumno_id]}", headers: auth_headers(student[:token])

    assert_response :ok
    assert_equal student[:alumno_id], json["id"]
  end

  test "Read a student: Student reads another record" do
    other = create_alumno(@teacher_token, nombre: "Somebody Else")
    student = create_account(nombre: "Curious Student", email: "curious-student@example.com", password: PASSWORD,
                             rol: "alumno")

    get "/api/v1/alumnos/#{other['id']}", headers: auth_headers(student[:token])

    assert_response :forbidden
  end

  test "Read a student: Unknown student" do
    get "/api/v1/alumnos/#{MISSING_ID}", headers: auth_headers(@teacher_token)

    assert_response :not_found
  end

  # --- Requirement: Create students ---

  test "Create students: Teacher creates a student" do
    post "/api/v1/alumnos", params: valid_attributes(nombre: "Brand New"), headers: auth_headers(@teacher_token), as: :json

    assert_response :created
    created = json
    assert_equal "Brand New", created["nombre"]
    assert_equal 8, created["edad"]
    assert_equal "3º Primaria", created["curso"]
    assert_equal "Medio", created["dificultad"]
    assert_equal 50, created["progreso"]

    get "/api/v1/alumnos", headers: auth_headers(@teacher_token)
    assert_includes json.map { |alumno| alumno["id"] }, created["id"]
  end

  test "Create students: Family member tries to create a student" do
    post "/api/v1/alumnos", params: valid_attributes(nombre: "Not Allowed"),
                            headers: auth_headers(token_for(:padre)), as: :json

    assert_response :forbidden
    get "/api/v1/alumnos", headers: auth_headers(@teacher_token)
    assert_not_includes json.map { |alumno| alumno["nombre"] }, "Not Allowed"
  end

  test "Create students: Invalid data (missing name)" do
    post "/api/v1/alumnos", params: valid_attributes(nombre: nil), headers: auth_headers(@teacher_token), as: :json

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Create students: Invalid data (age 150)" do
    post "/api/v1/alumnos", params: valid_attributes(edad: 150), headers: auth_headers(@teacher_token), as: :json

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  test "Create students: Invalid data (unknown difficulty)" do
    post "/api/v1/alumnos", params: valid_attributes(dificultad: "Imposible"), headers: auth_headers(@teacher_token), as: :json

    assert_response :unprocessable_entity
    assert_kind_of Array, json["errors"]
    assert_not_empty json["errors"]
  end

  # --- Requirement: Update students ---

  test "Update students: Teacher updates a student" do
    alumno = create_alumno(@teacher_token, nombre: "Moving Up")

    patch "/api/v1/alumnos/#{alumno['id']}", params: { curso: "4º Primaria" }, headers: auth_headers(@teacher_token), as: :json

    assert_response :ok
    assert_equal alumno["id"], json["id"]
    assert_equal "4º Primaria", json["curso"]
  end

  test "Update students: Family member tries to update a student" do
    alumno = create_alumno(@teacher_token, nombre: "Stays Put", curso: "5º Primaria")

    patch "/api/v1/alumnos/#{alumno['id']}", params: { curso: "6º Primaria" },
                                             headers: auth_headers(token_for(:padre)), as: :json

    assert_response :forbidden
    get "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)
    assert_equal "5º Primaria", json["curso"]
  end

  test "Update students: Unknown student" do
    patch "/api/v1/alumnos/#{MISSING_ID}", params: { curso: "4º Primaria" }, headers: auth_headers(@teacher_token), as: :json

    assert_response :not_found
  end

  # --- Requirement: Delete students ---

  test "Delete students: Teacher deletes a student without an account" do
    alumno = create_alumno(@teacher_token, nombre: "Leaving")

    delete "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)

    assert_response :ok
    get "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)
    assert_response :not_found
  end

  test "Delete students: Teacher deletes a student with an account" do
    student = create_account(nombre: "Account Holder", email: "account-holder@example.com", password: PASSWORD,
                             rol: "alumno")

    delete "/api/v1/alumnos/#{student[:alumno_id]}", headers: auth_headers(@teacher_token)

    assert_response :ok
    assert_nil login("account-holder@example.com", PASSWORD), "login with the deleted account"
  end

  test "Delete students: Family member tries to delete a student" do
    alumno = create_alumno(@teacher_token, nombre: "Protected")

    delete "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(token_for(:padre))

    assert_response :forbidden
    get "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)
    assert_response :ok
  end

  # --- Requirement: Student statistics ---

  test "Student statistics: Statistics fields" do
    alumno = create_alumno(@teacher_token, nombre: "Stats Fields")

    get_estadisticas(@teacher_token, alumno)

    assert_response :ok
    assert_equal %w[juego_favorito juegos_practicados racha_dias sesiones_semana sesiones_totales tendencia ultima_sesion],
                 json.keys.sort
  end

  test "Student statistics: Student without sessions" do
    alumno = create_alumno(@teacher_token, nombre: "Never Played")

    get_estadisticas(@teacher_token, alumno)

    assert_equal 0, json["sesiones_totales"]
    assert_equal 0, json["racha_dias"]
    assert_equal "sin_datos", json["tendencia"]
  end

  test "Student statistics: Most played game" do
    alumno = create_alumno(@teacher_token, nombre: "Puzzle Fan")
    record_sesion(@teacher_token, alumno, juego: "Puzzle")
    record_sesion(@teacher_token, alumno, juego: "Puzzle")
    record_sesion(@teacher_token, alumno, juego: "Exploraciones")

    get_estadisticas(@teacher_token, alumno)

    assert_equal "Puzzle", json["juego_favorito"]
    assert_equal [ "Exploraciones", "Puzzle" ], json["juegos_practicados"].sort
  end

  test "Student statistics: Streak of consecutive days" do
    alumno = create_alumno(@teacher_token, nombre: "On A Streak")
    record_sesion(@teacher_token, alumno, fecha: "2026-03-02")
    record_sesion(@teacher_token, alumno, fecha: "2026-03-04")
    record_sesion(@teacher_token, alumno, fecha: "2026-03-05")
    record_sesion(@teacher_token, alumno, fecha: "2026-03-06")

    # Two days after the last session: the streak counts back from it, not from today.
    travel_to Time.zone.local(2026, 3, 8, 12) do
      get_estadisticas(@teacher_token, alumno)
    end

    assert_equal 3, json["racha_dias"]
  end

  test "Student statistics: Trend with few sessions" do
    alumno = create_alumno(@teacher_token, nombre: "Few Sessions")
    3.times { record_sesion(@teacher_token, alumno) }

    get_estadisticas(@teacher_token, alumno)

    assert_equal 3, json["sesiones_totales"]
    assert_equal "sin_datos", json["tendencia"]
  end

  test "Student statistics: Improving trend" do
    alumno = create_alumno(@teacher_token, nombre: "Getting Better")
    # Recorded from worst to best, with session dates in the opposite order:
    # the trend follows the recording order, not the session date.
    start = Time.zone.local(2026, 3, 10, 12)
    [ [ 1, "2026-03-09" ], [ 1, "2026-03-08" ], [ 4, "2026-03-07" ], [ 4, "2026-03-06" ] ].each_with_index do |(aciertos, fecha), i|
      travel_to(start + i.minutes) { record_sesion(@teacher_token, alumno, aciertos: aciertos, intentos: 4, fecha: fecha) }
    end

    get_estadisticas(@teacher_token, alumno)

    assert_equal "mejorando", json["tendencia"]
  end

  test "Student statistics: Unknown student" do
    get "/api/v1/alumnos/#{MISSING_ID}/estadisticas", headers: auth_headers(@teacher_token)

    assert_response :not_found
  end

  private

  def valid_attributes(**overrides)
    { nombre: "Student", edad: 8, curso: "3º Primaria", dificultad: "Medio", progreso: 50 }.merge(overrides)
  end

  def get_estadisticas(token, alumno)
    get "/api/v1/alumnos/#{alumno['id']}/estadisticas", headers: auth_headers(token)
  end
end
