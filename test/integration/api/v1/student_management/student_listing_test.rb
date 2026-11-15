require "test_helper"

# specs/student-management/spec.md — Requirement: Student listing
module Api
  module V1
    module StudentManagement
      class StudentListingTest < ActionDispatch::IntegrationTest
        setup do
          @teacher_token = token_for(:profesor)
        end

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
          student = create_account(nombre: "Signed-up Student", email: "signed-up-student@example.com",
                                   password: PASSWORD, rol: "alumno")

          get "/api/v1/alumnos", headers: auth_headers(student[:token])

          assert_response :ok
          assert_equal [ student[:alumno_id] ], json.map { |alumno| alumno["id"] }
        end

        test "Student listing: Missing token" do
          get "/api/v1/alumnos"

          assert_response :unauthorized
        end
      end
    end
  end
end
