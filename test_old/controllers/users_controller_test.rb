require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should show user" do
    get :show, :id => @author.to_param
    assert_response :success
  end

#  test "admin should get edit" do
#    sign_in @admin
#    get :edit, :id => @author.to_param
#    assert_response :success
#    sign_out @admin
#  end

#  test "user should get edit profile" do
#    sign_in @author
#    get :edit, :id => @author.to_param
#    assert_response :success
#    sign_out @author
#  end

#  test "admin should update user" do
#    sign_in @admin
#    put :update, :id => @author.to_param, :user => @author.attributes
#    assert_redirected_to user_path(assigns(:user))
#    sign_out @admin
#  end

#  test "user should update profile" do
#    sign_in @author
#    put :update, :id => @author.to_param, :user => @author.attributes
#    assert_redirected_to user_path(assigns(:user))
#    sign_out @author
#  end

#  test "admin should destroy user" do
#    sign_in @admin
#    assert_difference('User.count', -1) do
#      delete :destroy, :id => @author.to_param
#    end
#    assert_redirected_to users_path
#    sign_out @admin
#  end

  test "editor should promote author" do
    sign_in @editor
    get :make_editor, :id => @author.to_param
    assert_equal "Editor", User.find(@author.id).role
    sign_out @editor
  end
 
  test "admin should promote author" do
    sign_in @admin
    get :make_admin, :id => @author.to_param
    assert_equal "Admin", User.find(@author.id).role
    sign_out @admin
  end
  
  test "admin should demote editor" do
    sign_in @admin
    get :demote, :id => @editor.to_param
    assert_equal "Author", User.find(@editor.id).role
    sign_out @admin
  end

  test "should get permission denied" do
    sign_in @editor
#    get :edit, :id => @author.to_param
#    assert_permission_denied
#    put :update, :id => @author.to_param, :user => @author.attributes
#    assert_permission_denied
#    assert_difference('Mountain.count', 0) do
#      delete :destroy, :id => @author.to_param
#    end
#    assert_permission_denied
    get :make_admin, :id => @author.to_param
    assert_permission_denied
    get :demote, :id => @author.to_param
    assert_permission_denied
    sign_out @editor
    sign_in @author
    get :make_editor, :id => @author.to_param
    assert_permission_denied
    sign_out @author
  end
end
