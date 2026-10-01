require 'test_helper'

class PostsControllerTest < ActionController::TestCase
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
    @controller = Forem::PostsController.new
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
#    get :new, {:use_route => :forem, :topic_id => @post.topic.id}
#    assert_response :success
#    sign_out @user
#  end

#  test "should create post" do
#    sign_in @user
#    assert_difference('Forem::Post.count') do
#      post :create, {:post => @post.attributes, :topic_id => @post.topic.id}
#    end
#    sign_out @user
#  end

#  test "should get edit" do
#    sign_in @admin
#    get :edit, {:use_route => :forem, :id => @post.id, :topic_id => @post.topic.id}
#    assert_response :success
#    sign_out @admin
#  end

#  test "should update post" do
#    sign_in @admin
#    put :update, {:id => @post.id, :post => @post.attributes, :topic_id => @post.topic.id}
#    sign_out @admin
#  end

#  test "should destroy post" do
#    sign_in @admin
#    assert_difference('Forem::Post.count', -1) do
#      delete :destroy, {:id => @post.id, :topic_id => @post.topic.id}
#    end

#    assert_redirected_to @post.topic.forum
#    sign_out @admin
#  end
end
