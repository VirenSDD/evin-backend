require "test_helper"

# specs/authentication/spec.md — Requirement: Public sign-up
module Api
  module V1
    module Authentication
      class PublicSignUpTest < ActionDispatch::IntegrationTest
        test "Public sign-up: Sign-up as family member" do
          register(nombre: "New Family Member", email: "family@example.com", password: PASSWORD, rol: "padre")

          assert_response :created
          assert json["token"].present?
          assert json["user"]["id"].present?
          assert_equal({ "id" => json["user"]["id"], "nombre" => "New Family Member", "email" => "family@example.com",
                         "rol" => "padre", "alumno_id" => nil },
                       json["user"])
        end

        test "Public sign-up: Sign-up as student creates the student record" do
          register(nombre: "New Student", email: "student@example.com", password: PASSWORD, rol: "alumno")

          assert_response :created
          assert_equal "alumno", json["user"]["rol"]
          assert json["user"]["alumno_id"].present?
        end

        test "Public sign-up: Privileged role requested (profesor)" do
          register(nombre: "Wants Profesor", email: "wants-profesor@example.com", password: PASSWORD, rol: "profesor")

          assert_response :created
          assert_equal "alumno", json["user"]["rol"]
        end

        test "Public sign-up: Privileged role requested (tecnico)" do
          register(nombre: "Wants Tecnico", email: "wants-tecnico@example.com", password: PASSWORD, rol: "tecnico")

          assert_response :created
          assert_equal "alumno", json["user"]["rol"]
        end

        test "Public sign-up: Email already registered" do
          register(nombre: "Someone Else", email: "profesor@example.com", password: PASSWORD, rol: "padre")

          assert_response :unprocessable_entity
          assert_kind_of Array, json["errors"]
          assert_not_empty json["errors"]
        end

        test "Public sign-up: Missing name" do
          register(nombre: nil, email: "no-name@example.com", password: PASSWORD, rol: "padre")

          assert_response :unprocessable_entity
          assert_kind_of Array, json["errors"]
          assert_not_empty json["errors"]
        end
      end
    end
  end
end
