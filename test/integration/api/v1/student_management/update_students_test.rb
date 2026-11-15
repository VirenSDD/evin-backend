require "test_helper"

# specs/student-management/spec.md — Requirement: Update students
module Api
  module V1
    module StudentManagement
      class UpdateStudentsTest < ActionDispatch::IntegrationTest
        setup do
          @teacher_token = token_for(:profesor)
        end

        test "Update students: Teacher updates a student" do
          alumno = create_alumno(@teacher_token, nombre: "Moving Up")

          patch "/api/v1/alumnos/#{alumno['id']}", params: { curso: "4º Primaria" },
                                                   headers: auth_headers(@teacher_token), as: :json

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
          patch "/api/v1/alumnos/#{MISSING_ID}", params: { curso: "4º Primaria" },
                                                 headers: auth_headers(@teacher_token), as: :json

          assert_response :not_found
        end
      end
    end
  end
end
