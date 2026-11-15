require "test_helper"

# specs/authentication/spec.md — Requirement: Password reset
module Api
  module V1
    module Authentication
      class PasswordResetTest < ActionDispatch::IntegrationTest
        test "Password reset: Valid token" do
          email = "padre@example.com"
          recovery_token = request_recovery_token(email)

          post "/api/v1/password/reset", params: { token: recovery_token, password: NEW_PASSWORD }, as: :json

          assert_response :ok
          assert login(email, NEW_PASSWORD).present?, "login with the new password"

          post "/api/v1/password/reset", params: { token: recovery_token, password: "Another-pass-789" }, as: :json
          assert_response :unprocessable_entity, "the token is accepted only once"
        end

        test "Password reset: Expired token" do
          email = "padre@example.com"
          recovery_token = request_recovery_token(email)

          travel 2.hours + 1.minute do
            post "/api/v1/password/reset", params: { token: recovery_token, password: NEW_PASSWORD }, as: :json

            assert_response :unprocessable_entity
            assert login(email, PASSWORD).present?, "the password does not change"
          end
        end

        test "Password reset: Unknown token" do
          post "/api/v1/password/reset", params: { token: "unknown-token", password: NEW_PASSWORD }, as: :json

          assert_response :unprocessable_entity
        end

        private

        # Requests a recovery email, delivers it and reads the token from its link.
        def request_recovery_token(email)
          perform_enqueued_jobs do
            post "/api/v1/password/forgot", params: { email: email }, as: :json
          end
          mail = ActionMailer::Base.deliveries.last
          assert_equal [ email ], mail.to
          mail.text_part.body.decoded[/reset_token=([\w-]+)/, 1].tap { |token| assert token.present? }
        end
      end
    end
  end
end
