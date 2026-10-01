require 'test_helper'

class TripReportsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  fixtures :trip_reports
  fixtures :routes
  fixtures :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @trip_report = trip_reports(:columbia)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get new" do
    sign_in @author
    get :new, :route_id => routes(:columbia).id
    assert_response :success
    sign_out @author
  end

  test "should create trip_report" do
    sign_in @author
    assert_difference('TripReport.count') do
      post :create, :trip_report => @trip_report.attributes
    end

    assert_redirected_to trip_report_path(assigns(:trip_report))
    sign_out @author
  end

  test "should show trip_report" do
    sign_in @admin
    get :show, :id => @trip_report.to_param
    assert_response :success
    sign_out @admin
  end

  test "should get edit" do
    sign_in @admin
    get :edit, :id => @trip_report.to_param
    assert_response :success
    sign_out @admin
  end

  test "should update trip_report" do
    sign_in @admin
    put :update, :id => @trip_report.to_param, :trip_report => @trip_report.attributes
    assert_redirected_to trip_report_path(assigns(:trip_report))
    sign_out @admin
  end

#  test "should destroy trip_report" do
#    sign_in @admin
#    assert_difference('TripReport.count', -1) do
#      delete :destroy, :id => @trip_report.to_param
#    end
#
#    assert_redirected_to trip_reports_path
#    sign_out @admin
#  end

end
