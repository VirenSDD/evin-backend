require "test_helper"

# specs/student-management/spec.md — Requirement: Student statistics
module Api
  module V1
    module StudentManagement
      class StudentStatisticsTest < ActionDispatch::IntegrationTest
        setup do
          @teacher_token = token_for(:profesor)
        end

        test "Student statistics: Statistics fields" do
          alumno = create_alumno(@teacher_token, nombre: "Stats Fields")

          get_estadisticas(@teacher_token, alumno)

          assert_response :ok
          assert_equal %w[juego_favorito juegos_practicados racha_dias sesiones_semana sesiones_totales tendencia
                          ultima_sesion],
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
          sesiones = [ [ 1, "2026-03-09" ], [ 1, "2026-03-08" ], [ 4, "2026-03-07" ], [ 4, "2026-03-06" ] ]
          sesiones.each_with_index do |(aciertos, fecha), i|
            travel_to(start + i.minutes) do
              record_sesion(@teacher_token, alumno, aciertos: aciertos, intentos: 4, fecha: fecha)
            end
          end

          get_estadisticas(@teacher_token, alumno)

          assert_equal "mejorando", json["tendencia"]
        end

        test "Student statistics: Unknown student" do
          get "/api/v1/alumnos/#{MISSING_ID}/estadisticas", headers: auth_headers(@teacher_token)

          assert_response :not_found
        end

        private

        def get_estadisticas(token, alumno)
          get "/api/v1/alumnos/#{alumno['id']}/estadisticas", headers: auth_headers(token)
        end
      end
    end
  end
end
