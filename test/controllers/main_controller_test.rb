require 'test_helper'

class MainControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  set_fixture_class :forem_categories => Forem::Category
  set_fixture_class :forem_forums => Forem::Forum
  set_fixture_class :forem_topics => Forem::Topic
  set_fixture_class :forem_posts => Forem::Post
  fixtures :places
  fixtures :users

  test "should get index" do
    get :index
    assert_response :success
#   assert_select '#columns #side a', :minimum => 4
#   assert_select '#content .entry', 4
#   assert_select 'h3', 'Mount Columbia'
  end

  test "should get index with more new entries" do
    get :index, :everything => true
    assert_response :success
  end
  
  test "should get index with updated entries" do
    get :index, :updated => true
    assert_response :success
  end

  test "should get gmap" do
    sign_in users(:author)
    @request.user_agent = 'firefox'
    get :gmap, :place_id => places(:columbia).id 
    assert_response :success
    sign_out users(:author)
  end

  test "should not get gmap" do
    @request.user_agent = 'msnbot'
    get :gmap, :place_id => places(:columbia).id 
    assert_response 302
  end

  test "should get search" do
    @request.user_agent = 'firefox'
    get :search, :search => 'columbia' 
    assert_response :redirect
  end

  test "should get contribution guide" do
    get :contributions
    assert_response :success
  end

  test "should get terms" do
    get :terms
    assert_response :success
  end

  test "should get disclaimer" do
    get :disclaimer
    assert_response :success
  end
end
