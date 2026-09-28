require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.first
  end

  test "should get index in json" do
    get people_url(format: :json)
    assert_response :success
  end

  test "should get show in json" do
    get person_url(@person, format: :json)
    assert_response :success
  end

  test "should get show in xml" do
    get person_url(@person, format: :xml)
    # XML response for person show
    assert_response :success
  end
end
