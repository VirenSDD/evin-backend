require "test_helper"

# specs/authentication/spec.md — Requirement: Password recovery request
module Api
  module V1
    module Authentication
      class PasswordRecoveryRequestTest < ActionDispatch::IntegrationTest
        test "Password recovery request: Registered email" do
          assert_enqueued_emails 1 do
            post "/api/v1/password/forgot", params: { email: "padre@example.com" }, as: :json
          end

          assert_response :ok
          assert json["message"].present?
          perform_enqueued_jobs
          assert_equal [ "padre@example.com" ], ActionMailer::Base.deliveries.last.to
        end

        test "Password recovery request: Unregistered email" do
          post "/api/v1/password/forgot", params: { email: "padre@example.com" }, as: :json
          generic_message = json["message"]

          assert_no_enqueued_emails do
            post "/api/v1/password/forgot", params: { email: "nobody@example.com" }, as: :json
          end

          assert_response :ok
          assert_equal generic_message, json["message"]
        end
      end
    end
  end
end
