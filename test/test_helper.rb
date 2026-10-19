ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers if explicitly configured
    parallelize(workers: :number_of_processors) if ENV["PARALLEL_WORKERS"] == "true"

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include Devise::Test::IntegrationHelpers

    def assert_permission_denied
      assert_redirected_to root_path
      assert_equal "You don't have permission to complete that action.", flash[:notice]
    end
  end
end
