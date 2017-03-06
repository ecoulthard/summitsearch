require 'test_helper'

class AlbumsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  fixtures :albums
  fixtures :routes
  fixtures :places
  fixtures :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @album = albums(:columbia)
  end

  test "should get index" do
    get :index
    assert_response :success
    #assert_not_nil assigns(:albums)
  end

  #Each call to new creates a new album.
  test "should get new" do
    sign_in @author
    assert_difference('Album.count', 2) do
      get :new, :route_id => routes(:one).id
      assert_redirected_to edit_album_path(assigns(:album))
      get :new, :place_id => places(:columbia).id
      assert_redirected_to edit_album_path(assigns(:album))
    end
    sign_out @author
  end

  test "should create album" do
    sign_in @author
    assert_difference('Album.count') do
      post :create, :album => @album.attributes
    end

    assert_redirected_to album_path(assigns(:album))
    sign_out @author
  end

  test "should show album" do
    sign_in @admin
    get :show, :id => @album.to_param
    assert_response :success
    sign_out @admin
  end

  test "should get edit" do
    sign_in @admin
    get :edit, :id => @album.to_param
    assert_response :success
    sign_out @admin
  end

  test "should update album" do
    sign_in @admin
    put :update, :id => @album.to_param, :album => @album.attributes
    assert_response :success
    assert !@album.deleted
    sign_out @admin
  end

#  test "should destroy album" do
#    sign_in @admin
#    assert_difference('Album.count', -1) do
#      delete :destroy, :id => @album.to_param
#    end
#
#    assert_redirected_to albums_path
#    sign_out @admin
#  end
end
