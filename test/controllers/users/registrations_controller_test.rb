require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  setup do
    @user = users(:author)
  end

  test "should redirect edit when not signed in" do
    get edit_user_registration_url
    assert_response :redirect
  end

  test "should get edit when signed in" do
    sign_in @user
    get edit_user_registration_url
    assert_response :success
  end

  test "should update user profile" do
    sign_in @user
    patch user_registration_url, params: {
      user: {
        realname: "Updated Author",
        current_password: "Password123!"
      }
    }
    assert_redirected_to user_url(@user)
    assert_equal "Updated Author", @user.reload.realname
  end
end
