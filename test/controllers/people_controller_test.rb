require 'test_helper'

class PeopleControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  fixtures :people
  fixtures :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @person = Person.new(:name => 'John Oberlin',
	  		 :birthdate => Date.today,
			 :description => '',
			 :references => '')
  end

  test "should get index" do
    get :index
    assert_response :success
    #assert_not_nil assigns(:people)
  end

  test "should get new" do
    sign_in @editor
    get :new
    assert_response :success
    sign_out @editor
  end

  test "should create person" do
    sign_in @admin
    assert_difference('Person.count') do
      post :create, :person => @person.attributes
    end
    assert_redirected_to person_path(assigns(:person))
    sign_out @admin
  end

  test "should show person" do
    get :show, id: people(:one)
    assert_response :success
  end

  test "should get edit" do
    sign_in @editor
    get :edit, id: people(:one)
    assert_response :success
    sign_out @editor
  end

  test "should update person" do
    sign_in @admin
    put :update, :id => people(:one), :person => people(:one).attributes
    assert_redirected_to person_path(assigns(:person))
    sign_out @admin
  end

end
