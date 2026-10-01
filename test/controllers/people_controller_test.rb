require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  fixtures :people, :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @person = Person.new(
      name: "John Oberlin",
      birthdate: Date.today,
      description: "",
      references: ""
    )
  end

  test "should get index" do
    get people_url
    assert_response :success
  end

  test "should get new" do
    sign_in @editor
    get new_person_url
    assert_response :success
  end

  test "should create person" do
    sign_in @admin
    assert_difference("Person.count") do
      post people_url, params: { person: @person.attributes }
    end
    assert_redirected_to person_path(Person.last)
  end

  test "should show person" do
    get person_url(people(:one))
    assert_response :success
  end

  test "should get edit" do
    sign_in @editor
    get edit_person_url(people(:one))
    assert_response :success
  end

  test "should update person" do
    sign_in @admin
    person = people(:one)
    put person_url(person), params: { person: person.attributes }
    assert_redirected_to person_path(person.reload)
  end
end
