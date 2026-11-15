ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/api_helpers"

# config/initializers/resend.rb sets SMTP as the delivery method in every
# environment, overriding config/environments/test.rb. Force the :test method
# so no test ever contacts Resend.
ActionMailer::Base.delivery_method = :test

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

module ActionDispatch
  class IntegrationTest
    include ActionMailer::TestHelper
    include ApiHelpers

    # Password of every account in test/fixtures/users.yml.
    PASSWORD = "Test-pass-123"

    # Logs in through the API and returns the access token (nil on failure).
    def login(email, password)
      post "/api/v1/login", params: { email: email, password: password }, as: :json
      json["token"]
    end

    # Access token of one of the fixture accounts (:tecnico, :profesor, :padre).
    def token_for(fixture)
      login(users(fixture).email, PASSWORD)
    end

    def auth_headers(token)
      { "Authorization" => "Bearer #{token}" }
    end

    def json
      JSON.parse(response.body)
    end
  end
end
