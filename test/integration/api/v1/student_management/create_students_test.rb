require "test_helper"

# specs/student-management/spec.md — Requirement: Create students
module Api
  module V1
    module StudentManagement
      class CreateStudentsTest < ActionDispatch::IntegrationTest
        setup do
          @teacher_token = token_for(:profesor)
        end

        test "Create students: Teacher creates a student" do
          post "/api/v1/alumnos", params: valid_attributes(nombre: "Brand New"),
                                  headers: auth_headers(@teacher_token), as: :json

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
          post "/api/v1/alumnos", params: valid_attributes(nombre: nil),
                                  headers: auth_headers(@teacher_token), as: :json

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
          post "/api/v1/alumnos", params: valid_attributes(dificultad: "Imposible"),
                                  headers: auth_headers(@teacher_token), as: :json

          assert_response :unprocessable_entity
          assert_kind_of Array, json["errors"]
          assert_not_empty json["errors"]
        end

        private

        def valid_attributes(**overrides)
          { nombre: "Student", edad: 8, curso: "3º Primaria", dificultad: "Medio", progreso: 50 }.merge(overrides)
        end
      end
    end
  end
end
