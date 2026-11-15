require "test_helper"

# specs/authentication/spec.md — Requirement: Edit own profile
module Api
  module V1
    module Authentication
      class EditOwnProfileTest < ActionDispatch::IntegrationTest
        test "Edit own profile: Change name" do
          token = token_for(:padre)

          patch "/api/v1/me", params: { nombre: "Renamed Family" }, headers: auth_headers(token), as: :json

          assert_response :ok
          assert json["token"].present?
          assert_equal({ "id" => 3, "nombre" => "Renamed Family", "email" => "padre@example.com", "rol" => "padre",
                         "alumno_id" => nil },
                       json["user"])
        end

        test "Edit own profile: Change password with the current password (new password works)" do
          email = "padre@example.com"
          token = login(email, PASSWORD)

          patch "/api/v1/me", params: { password: NEW_PASSWORD, password_actual: PASSWORD },
                              headers: auth_headers(token), as: :json

          assert_response :ok
          assert login(email, NEW_PASSWORD).present?
        end

        test "Edit own profile: Change password with the current password (old password rejected)" do
          email = "padre@example.com"
          token = login(email, PASSWORD)

          patch "/api/v1/me", params: { password: NEW_PASSWORD, password_actual: PASSWORD },
                              headers: auth_headers(token), as: :json

          assert_response :ok
          assert_nil login(email, PASSWORD)
        end

        test "Edit own profile: Change password without the correct current password (wrong)" do
          email = "padre@example.com"
          token = login(email, PASSWORD)

          patch "/api/v1/me", params: { password: NEW_PASSWORD, password_actual: "wrong-password" },
                              headers: auth_headers(token), as: :json

          assert_response :unprocessable_entity
          assert login(email, PASSWORD).present?, "login with the old password"
          assert_nil login(email, NEW_PASSWORD), "login with the new password"
        end

        test "Edit own profile: Change password without the correct current password (missing)" do
          email = "padre@example.com"
          token = login(email, PASSWORD)

          patch "/api/v1/me", params: { password: NEW_PASSWORD }, headers: auth_headers(token), as: :json

          assert_response :unprocessable_entity
          assert login(email, PASSWORD).present?, "login with the old password"
          assert_nil login(email, NEW_PASSWORD), "login with the new password"
        end
      end
    end
  end
end
