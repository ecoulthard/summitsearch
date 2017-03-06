require 'test_helper'

class ForumsControllerTest < ActionController::TestCase
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
    @controller = Forem::ForumsController.new
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @category = forem_categories(:regional)
    @forum = forem_forums(:rockies)
    @topic = forem_topics(:columbia)
    @post = forem_posts(:columbia_post)

    @routes = Forem::Engine.routes
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:categories)
  end

  test "should show forum" do
    sign_in @admin
    get :show, {:id => @forum.to_param}
    assert_response :success
    sign_out @admin
  end

  test "should get search" do
    @routes = Rails.application.routes
    @request.user_agent = 'firefox'
    get :search, :search => 'bastille' 
    assert_response :success
  end
end
