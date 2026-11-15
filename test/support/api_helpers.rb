# Helpers shared by several integration tests. They only call the HTTP API,
# like the tests themselves. Helpers that act as a user take that user's
# access token as their first argument.
module ApiHelpers
  # An id that no record has.
  MISSING_ID = 0

  # A password different from ActionDispatch::IntegrationTest::PASSWORD.
  NEW_PASSWORD = "New-pass-456"

  # Sends a public sign-up request and leaves the response for the test to check.
  def register(nombre:, email:, password:, rol:)
    post "/api/v1/register", params: { nombre: nombre, email: email, password: password, rol: rol }, as: :json
  end

  # Signs up an account and returns its user id, access token and, for the
  # alumno role, the id of the student record created with it.
  def create_account(nombre:, email:, password:, rol:)
    register(nombre: nombre, email: email, password: password, rol: rol)
    assert_response :created
    { id: json["user"]["id"], token: json["token"], alumno_id: json["user"]["alumno_id"] }
  end

  # Creates a student and returns the created record.
  def create_alumno(token, nombre:, **attributes)
    post "/api/v1/alumnos", params: { nombre: nombre, **attributes }, headers: auth_headers(token), as: :json
    assert_response :created
    json
  end

  # Records a game session of a student and returns the created session.
  def record_sesion(token, alumno, juego: "Puzzle", aciertos: 3, intentos: 4, fecha: nil)
    post "/api/v1/sesiones", params: { alumno: alumno["nombre"], alumno_id: alumno["id"], juego: juego,
                                       aciertos: aciertos, intentos: intentos, fecha: fecha }.compact,
                             headers: auth_headers(token), as: :json
    assert_response :created
    json
  end
end
