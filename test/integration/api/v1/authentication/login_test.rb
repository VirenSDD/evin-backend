require "test_helper"

# specs/authentication/spec.md — Requirement: Login
module Api
  module V1
    module Authentication
      class LoginTest < ActionDispatch::IntegrationTest
        test "Login: Valid credentials" do
          post "/api/v1/login", params: { email: "profesor@example.com", password: PASSWORD }, as: :json

          assert_response :ok
          assert json["token"].present?
          assert_equal({ "id" => 2, "nombre" => "Test Teacher", "email" => "profesor@example.com", "rol" => "profesor",
                         "alumno_id" => nil },
                       json["user"])
        end

        test "Login: Email in uppercase" do
          post "/api/v1/login", params: { email: "PROFESOR@EXAMPLE.COM", password: PASSWORD }, as: :json

          assert_response :ok
          assert json["token"].present?
        end

        test "Login: Wrong password" do
          post "/api/v1/login", params: { email: "profesor@example.com", password: "wrong-password" }, as: :json

          assert_response :unauthorized
          assert json["error"].present?
          assert_nil json["token"]
        end

        test "Login: Unknown user" do
          post "/api/v1/login", params: { email: "nobody@example.com", password: PASSWORD }, as: :json

          assert_response :unauthorized
        end
      end
    end
  end
end
