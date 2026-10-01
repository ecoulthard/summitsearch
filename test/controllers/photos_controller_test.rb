require "test_helper"

class PhotosControllerTest < ActionDispatch::IntegrationTest
  fixtures :photos, :ip_addresses, :visits, :views, :users, :places

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @photo = photos(:columbia)
    @photo_visit = visits(:author_ip_visit)
    @photo_view = views(:author_view)
  end

  test "should get index" do
    get photos_url
    assert_response :success
  end

  test "should get index in xml" do
    get photos_url(format: :xml)
    assert_response :success
  end

  test "should get show in xml" do
    get photo_url(@photo, format: :xml)
    assert_response :success
  end

  test "should get nearby_list xml" do
    get nearby_list_photos_url(format: :xml, latitude: 52.7, longitude: -118.0)
    assert_response :success
  end

  test "should get new" do
    sign_in @admin
    get new_photo_url
    assert_response :success
  end

  test "should not create photo without valid attributes" do
    sign_in @admin
    post photos_url, params: { photo: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "should create photo" do
    sign_in @admin
    file = fixture_file_upload("gorilla.jpg", "image/jpeg")

    assert_difference("Photo.count") do
      post photos_url, params: {
        photo: {
          title: "Not Mount Columbia",
          ref_latitude: @photo.ref_latitude,
          ref_longitude: @photo.ref_longitude,
          ref_title: @photo.ref_title,
          ref_content: @photo.ref_content,
          user_id: @photo.user_id,
          photo: file
        }
      }
    end

    assert_redirected_to photo_path(Photo.last)
  end

  test "should show photo" do
    sign_in @admin
    get photo_url(@photo)
    assert_response :success
  end

  test "should get edit" do
    sign_in @admin
    get edit_photo_url(@photo)
    assert_response :success
  end

  test "should update photo" do
    sign_in @admin
    put photo_url(@photo), params: { photo: { title: "Updated Title" } }
    assert_redirected_to photo_path(@photo.reload)
    assert_equal "Updated Title", @photo.title
  end

  test "should like photo" do
    sign_in @author
    get photo_url(@photo), headers: { "REMOTE_ADDR" => "1.2.3.4", "HTTP_USER_AGENT" => "Mozilla/5.0" }
    put social_update_photo_url(@photo), params: { facebook_like: "true" }
    assert_response :success
    assert_equal 1, @photo.reload.likes.count

    put thumbs_up_photo_url(@photo)
    assert_equal 1, @photo.reload.user_likes.count

    put social_update_photo_url(@photo), params: { facebook_like: "false" }
    assert_response :success
    assert_equal 0, @photo.reload.likes.count
  end
end
