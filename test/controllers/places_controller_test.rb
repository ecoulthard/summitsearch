require 'test_helper'

class PlacesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  fixtures :places
  fixtures :mountain_details

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @place = Mountain.new(:name => 'Mount Forbes',
	  		    :name_status => 'Official',
	  		    :latitude => 51.86000,
	  		    :longitude => -116.93166,
			    :height => 3617,
			    :ref_place_id => places(:columbia).id,
			    :partial_name_match => true,
	  		    :insert_id => @admin.id)
 
    @dup_place = Mountain.new(:name => 'North Twin',
	  		    :name_status => 'Official',
	  		    :latitude => 52.22500,
	  		    :longitude => -117.43584,
			    :height => 3731,
			    :ref_place_id => places(:columbia).id,
			    :partial_name_match => true,
	  		    :insert_id => @admin.id)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get new icefield" do
    sign_in @admin
    get :new, :type => 'Icefield', :ref_place_id => places(:one).id
    assert_response :success
    sign_out @admin
  end

  test "should not create icefield" do
    sign_in @admin
    assert_no_difference('Place.count') do
      post :create, :place => @dup_place.attributes
    end
    assert_response :success
    sign_out @admin
  end

  test "should show icefield" do
    get :show, :id => places(:one).to_param
    assert_response :success
  end

  test "should get new" do
    sign_in @admin
    get :new, :type => 'Mountain', :ref_place_id => places(:castleguard).id
    assert_response :success
    sign_out @admin
  end

  test "should create place" do
    sign_in @admin
    assert_difference('Place.count') do
      post :create, :place => @place.attributes
    end

    assert_redirected_to place_path(assigns(:place))
    sign_out @admin
  end

  test "should show place" do
    get :show, :id => places(:castleguard).to_param
    assert_response :success
  end

  test "should get edit" do
    sign_in @editor
    get :edit, :id => places(:castleguard).to_param
    assert_response :success
    sign_out @editor
  end

  test "should update place" do
    sign_in @editor
    put :update, :id => places(:castleguard).to_param, :place => places(:castleguard).attributes
    assert_redirected_to place_path(assigns(:place))
    sign_out @editor
  end

end
