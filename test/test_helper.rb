ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers if explicitly configured
    parallelize(workers: :number_of_processors) if ENV["PARALLEL_WORKERS"] == "true"

    if defined?(Forem)
      set_fixture_class forem_categories: Forem::Category if defined?(Forem::Category)
      set_fixture_class forem_forums: Forem::Forum if defined?(Forem::Forum)
      set_fixture_class forem_topics: Forem::Topic if defined?(Forem::Topic)
      set_fixture_class forem_posts: Forem::Post if defined?(Forem::Post)
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include Devise::Test::IntegrationHelpers

    def assert_permission_denied
      assert_redirected_to root_path
      assert_equal "You don't have permission to complete that action.", flash[:notice]
    end
  end
end
