require "test_helper"

class AlbumsControllerTest < ActionDispatch::IntegrationTest
  fixtures :albums, :routes, :places, :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @album = albums(:columbia)
  end

  test "should get index" do
    get albums_url
    assert_response :success
  end

  test "should get new" do
    sign_in @author
    assert_difference("Album.count", 2) do
      get new_album_url, params: { route_id: routes(:one).id }
      assert_redirected_to edit_album_path(Album.last)
      get new_album_url, params: { place_id: places(:columbia).id }
      assert_redirected_to edit_album_path(Album.last)
    end
  end

  test "should create album" do
    sign_in @author
    assert_difference("Album.count") do
      post albums_url, params: { album: @album.attributes }
    end

    assert_redirected_to album_path(Album.last)
  end

  test "new album uses border coordinates when place coordinates are missing" do
    sign_in @author
    place = places(:columbia)
    place.update_columns(latitude: nil, longitude: nil)
    place.border_points.delete_all
    place.border_points.create!(latitude: 49.8, longitude: -123.0, local_index: 0)
    place.border_points.create!(latitude: 50.0, longitude: -123.2, local_index: 1)

    assert_difference("Album.count") do
      get new_album_url, params: { place_id: place.id }
    end

    album = Album.last
    assert_redirected_to edit_album_path(album)
    assert_in_delta 49.9, album.ref_latitude
    assert_in_delta(-123.1, album.ref_longitude)
  end

  test "new album shows errors when place has no coordinates" do
    sign_in @author
    place = places(:columbia)
    place.update_columns(latitude: nil, longitude: nil)
    place.border_points.delete_all

    assert_no_difference("Album.count") do
      get new_album_url, params: { place_id: place.id }
    end

    assert_response :success
    assert_select "#error_explanation", text: /Ref latitude can't be blank/
  end

  test "should show album" do
    sign_in @admin
    get album_url(@album)
    assert_response :success
  end

  test "should get edit" do
    sign_in @admin
    get edit_album_url(@album)
    assert_response :success
  end

  test "should update album" do
    sign_in @admin
    put album_url(@album), params: { album: @album.attributes }
    assert_response :success
    assert_not @album.reload.deleted
  end
end
