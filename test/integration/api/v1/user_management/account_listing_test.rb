require "test_helper"

# specs/user-management/spec.md — Requirement: Account listing
module Api
  module V1
    module UserManagement
      class AccountListingTest < ActionDispatch::IntegrationTest
        setup do
          @admin_token = token_for(:tecnico)
        end

        test "Account listing: Administrator lists accounts" do
          get "/api/v1/users", headers: auth_headers(@admin_token)

          assert_response :ok
          assert_equal [
            { "id" => 1, "nombre" => "Test Administrator", "email" => "tecnico@example.com", "rol" => "tecnico" },
            { "id" => 3, "nombre" => "Test Family Member", "email" => "padre@example.com", "rol" => "padre" },
            { "id" => 2, "nombre" => "Test Teacher", "email" => "profesor@example.com", "rol" => "profesor" }
          ], json
        end

        test "Account listing: Teacher tries to list accounts" do
          get "/api/v1/users", headers: auth_headers(token_for(:profesor))

          assert_response :forbidden
        end
      end
    end
  end
end
