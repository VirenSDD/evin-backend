require "test_helper"

# specs/student-management/spec.md — Requirement: Delete students
module Api
  module V1
    module StudentManagement
      class DeleteStudentsTest < ActionDispatch::IntegrationTest
        setup do
          @teacher_token = token_for(:profesor)
        end

        test "Delete students: Teacher deletes a student without an account" do
          alumno = create_alumno(@teacher_token, nombre: "Leaving")

          delete "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)

          assert_response :ok
          get "/api/v1/alumnos/#{alumno['id']}", headers: auth_headers(@teacher_token)
          assert_response :not_found
        end

        test "Delete students: Teacher deletes a student with an account" do
          student = create_account(nombre: "Account Holder", email: "account-holder@example.com",
                                   password: PASSWORD, rol: "alumno")

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
      end
    end
  end
end
