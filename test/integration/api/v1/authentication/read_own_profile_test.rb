require "test_helper"

# specs/authentication/spec.md — Requirement: Read own profile
module Api
  module V1
    module Authentication
      class ReadOwnProfileTest < ActionDispatch::IntegrationTest
        test "Read own profile: Valid token" do
          token = token_for(:padre)

          get "/api/v1/me", headers: auth_headers(token)

          assert_response :ok
          assert_equal({ "id" => 3, "nombre" => "Test Family Member", "email" => "padre@example.com", "rol" => "padre",
                         "alumno_id" => nil },
                       json["user"])
        end

        test "Read own profile: Missing token" do
          get "/api/v1/me"

          assert_response :unauthorized
        end

        test "Read own profile: Tampered or expired token (malformed)" do
          get "/api/v1/me", headers: auth_headers("not-a-jwt")

          assert_response :unauthorized
        end

        test "Read own profile: Tampered or expired token (signed with another key)" do
          foreign_token = JWT.encode({ user_id: 3, exp: 1.hour.from_now.to_i }, "another-key", "HS256")

          get "/api/v1/me", headers: auth_headers(foreign_token)

          assert_response :unauthorized
        end

        test "Read own profile: Tampered or expired token (expired)" do
          token = token_for(:padre)

          travel 25.hours do
            get "/api/v1/me", headers: auth_headers(token)

            assert_response :unauthorized
          end
        end
      end
    end
  end
end
