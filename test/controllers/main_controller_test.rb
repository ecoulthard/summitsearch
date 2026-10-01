require "test_helper"

class MainControllerTest < ActionDispatch::IntegrationTest
  fixtures :places, :users

  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should get index with more new entries" do
    get root_url, params: { everything: true }
    assert_response :success
  end
  
  test "should get index with updated entries" do
    get root_url, params: { updated: true }
    assert_response :success
  end

  test "should get gmap" do
    sign_in users(:author)
    get gmap_url, params: { place_id: places(:columbia).id }, headers: { "HTTP_USER_AGENT" => "firefox" }
    assert_response :success
  end

  test "should not get gmap for bot" do
    get gmap_url, params: { place_id: places(:columbia).id }, headers: { "HTTP_USER_AGENT" => "msnbot" }
    assert_response :redirect
  end

  test "should get search" do
    get search_url, params: { search: "columbia" }, headers: { "HTTP_USER_AGENT" => "firefox" }
    assert_response :redirect
  end

  test "should get contribution guide" do
    get contributions_url
    assert_response :success
  end

  test "should get terms" do
    get terms_url
    assert_response :success
  end

  test "should get disclaimer" do
    get disclaimer_url
    assert_response :success
  end
end
