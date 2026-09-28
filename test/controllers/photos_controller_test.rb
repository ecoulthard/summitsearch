require "test_helper"

class PhotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @photo = Photo.first
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
end
