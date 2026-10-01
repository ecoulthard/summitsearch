require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  
  set_fixture_class :forem_categories => Forem::Category
  set_fixture_class :forem_forums => Forem::Forum
  set_fixture_class :forem_topics => Forem::Topic
  set_fixture_class :forem_posts => Forem::Post
  fixtures :forem_categories
  fixtures :forem_forums
  fixtures :forem_topics
  fixtures :forem_posts
  fixtures :users

  setup do
    @controller = Forem::CategoriesController.new
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @category = forem_categories(:regional)
    @forum = forem_forums(:rockies)
    @topic = forem_topics(:columbia)
    @post = forem_posts(:columbia_post)

    @routes = Forem::Engine.routes
  end

  test "should show category" do
    sign_in @admin
    get :show, {:id => @category.to_param}
    assert_response :success
    sign_out @admin
  end
end
