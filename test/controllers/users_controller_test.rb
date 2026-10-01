require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should show user" do
    get user_url(@author)
    assert_response :success
  end

  test "editor should promote author" do
    sign_in @editor
    get make_editor_user_url(@author)
    assert_equal "Editor", @author.reload.role
  end
 
  test "admin should promote author" do
    sign_in @admin
    get make_admin_user_url(@author)
    assert_equal "Admin", @author.reload.role
  end
  
  test "admin should demote editor" do
    sign_in @admin
    get demote_user_url(@editor)
    assert_equal "Author", @editor.reload.role
  end

  test "should get permission denied" do
    sign_in @editor
    get make_admin_user_url(@author)
    assert_permission_denied

    get demote_user_url(@author)
    assert_permission_denied

    sign_out @editor
    sign_in @author
    get make_editor_user_url(@author)
    assert_permission_denied
  end
end
