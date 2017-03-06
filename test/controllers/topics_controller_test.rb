require 'test_helper'

class TopicsControllerTest < ActionController::TestCase
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
    @controller = Forem::TopicsController.new
    @admin = users(:vador)
    @user = users(:forem_user)
    @category = forem_categories(:regional)
    @forum = forem_forums(:rockies)
    @topic = forem_topics(:columbia)
    @post = forem_posts(:columbia_post)

    @routes = Forem::Engine.routes
  end

#  test "should get new" do
#    sign_in @user
#    get :new, {:use_route => :forem, :forum_id => @forum.to_param}
#    assert_response :success
#    sign_out @user
#  end

#  test "should create topic" do
#    sign_in @author
#    puts @topic.posts.count
#    assert_difference('Forem::Topic.count') do
#      post :create, {:use_route => :forem, :topic => @topic.attributes, :forum_id => @topic.forum.id}
#    end
#    assert_redirected_to @topic.forum
#    sign_out @author
#  end

  test "should show topic" do
    sign_in @admin
    get :show, {:id => @topic.to_param, :forum_id => @forum.to_param}
    assert_response :success
    sign_out @admin
  end

  test "should destroy topic" do
    sign_in @admin
    assert_difference('Forem::Topic.count', -1) do
      delete :destroy, {:id => 1, :forum_id => @topic.forum.id}
    end

    assert_redirected_to @topic.forum
    sign_out @admin
  end
end
