require 'test_helper'

class PhotosControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  set_fixture_class :forem_categories => Forem::Category
  set_fixture_class :forem_forums => Forem::Forum
  set_fixture_class :forem_topics => Forem::Topic
  set_fixture_class :forem_posts => Forem::Post
  fixtures :forem_categories
  fixtures :forem_forums
  fixtures :forem_topics
  fixtures :forem_posts
  fixtures :photos
  fixtures :ip_addresses
  fixtures :visits
  fixtures :views
  fixtures :users

  setup do
    module ThinkingSphinx
      def self.search(query = '', options = {})
        ThinkingSphinx::Search.new "1234567891011121314"
      end
    end
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @photo = photos(:columbia)
    @photo_visit = visits(:author_ip_visit)
    @photo_view = views(:author_view)
  end

  test "should get index" do
    get :index
    assert_response :success
    #assert_not_nil assigns(:photos)
  end

  test "should get new" do
    sign_in @admin
    get :new
    assert_response :success
    sign_out @admin
  end

  test "should not create photo" do
    sign_in @admin
    post :create, :photo => @photo.attributes
    assert_equal Photo.count, 4
    assert_response :success
    sign_out @admin
  end

  test "should create photo" do
    sign_in @admin
    photo = fixture_file_upload('gorilla.jpg', 'image/jpeg')
    
    assert_difference('Photo.count') do
      post :create, :photo => { title: 'Not Mount Columbia',
                      ref_latitude: @photo.ref_latitude,
                      ref_longitude: @photo.ref_longitude,
                      ref_title: @photo.ref_title,
                      ref_content: @photo.ref_content,
                      user_id: @photo.user_id,
                      photo: photo }
    end

    assert_redirected_to photo_path(assigns(:photo))
    sign_out @admin
  end

  test "should show photo" do
    sign_in @admin
    get :show, :id => @photo.to_param
    assert_response :success
    sign_out @admin
  end

  test "should get edit" do
    sign_in @admin
    get :edit, :id => @photo.to_param
    assert_response :success
    sign_out @admin
  end

  test "should update photo" do
    sign_in @admin
    put :update, :id => @photo.to_param, :photo => @photo.attributes
    assert_redirected_to photo_path(assigns(:photo))
    sign_out @admin
  end

  test "should like photo" do
    sign_in @author
    @request.env['REMOTE_ADDR'] = '1.2.3.4'
    @request.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:10.0.1) Gecko/20100101 Firefox/10.0.1'
    get :show, :id => @photo.to_param
    put :social_update, :id => @photo.to_param, :facebook_like => "true" 
    assert_response :success
    assert_equal 1, Photo.find(@photo.id).likes.count
    put :thumbs_up, :id => @photo.to_param
    assert_equal 1, Photo.find(@photo.id).user_likes.count
    put :social_update, :id => @photo.to_param, :facebook_like => "false" 
    assert_response :success
    assert_equal 0, Photo.find(@photo.id).likes.count
    sign_out @author
  end

  test "should create comment" do

    sign_in @author
      put :create_comment, :id => @photo.to_param, :text => "my comment"
      sleep(0.5)#Give sidekiq sometime to run
      assert_not_nil Photo.find(@photo.id).topic
      assert_equal "my comment", Photo.find(@photo.id).comments.first.text
      put :create_comment, :id => @photo.to_param, :text => "2nd comment"
      sleep(1)#Give sidekiq sometime to run
      assert_equal "2nd comment", Photo.find(@photo.id).comments.last.text 
      assert_equal Photo.find(@photo.id).comments.count, 2
    sign_out @author
  end

#  test "should destroy photo" do
#    sign_in @admin
#    assert_difference('Photo.count', -1) do
#      delete :destroy, :id => @photo.to_param
#    end

#    assert_redirected_to photos_path
#    sign_out @admin
#  end
end
