require "test_helper"

class ForemControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  test "forem routes exist if defined" do
    if defined?(Forem) && defined?(Forem::Engine)
      assert defined?(Forem::CategoriesController)
    else
      assert true
    end
  end
end
