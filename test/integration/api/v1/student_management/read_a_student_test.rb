require "test_helper"

# specs/student-management/spec.md — Requirement: Read a student
module Api
  module V1
    module StudentManagement
      class ReadAStudentTest < ActionDispatch::IntegrationTest
        setup do
          @teacher_token = token_for(:profesor)
        end

        test "Read a student: Teacher reads a student" do
          alumno = create_alumno(@teacher_token, nombre: "Read Me")

          get "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)

          assert_response :ok
          assert_equal alumno["id"], json["id"]
          assert_equal "Read Me", json["nombre"]
        end

        test "Read a student: Student reads their own record" do
          student = create_account(nombre: "Self Reader", email: "self-reader@example.com",
                                   password: PASSWORD, rol: "alumno")

          get "/api/v1/alumnos/#{student[:alumno_id]}", headers: auth_headers(student[:token])

          assert_response :ok
          assert_equal student[:alumno_id], json["id"]
        end

        test "Read a student: Student reads another record" do
          other = create_alumno(@teacher_token, nombre: "Somebody Else")
          student = create_account(nombre: "Curious Student", email: "curious-student@example.com",
                                   password: PASSWORD, rol: "alumno")

          get "/api/v1/alumnos/#{other['id']}", headers: auth_headers(student[:token])

          assert_response :forbidden
        end

        test "Read a student: Unknown student" do
          get "/api/v1/alumnos/#{MISSING_ID}", headers: auth_headers(@teacher_token)

          assert_response :not_found
        end
      end
    end
  end
end
