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
