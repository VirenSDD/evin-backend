require "test_helper"

# specs/game-sessions/spec.md — Requirement: List game sessions
module Api
  module V1
    module GameSessions
      class ListGameSessionsTest < ActionDispatch::IntegrationTest
        setup do
          @teacher_token = token_for(:profesor)
          @alumno = create_alumno(@teacher_token, nombre: "Session Player")
        end

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
      end
    end
  end
end
