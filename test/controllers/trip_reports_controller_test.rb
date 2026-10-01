require "test_helper"

class TripReportsControllerTest < ActionDispatch::IntegrationTest
  fixtures :trip_reports, :routes, :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @trip_report = trip_reports(:columbia)
  end

  test "should get index" do
    get trip_reports_url
    assert_response :success
  end

  test "should get new" do
    sign_in @author
    get new_trip_report_url, params: { route_id: routes(:columbia).id }
    assert_response :success
  end

  test "should create trip_report" do
    sign_in @author
    assert_difference("TripReport.count") do
      post trip_reports_url, params: { trip_report: @trip_report.attributes }
    end

    assert_redirected_to trip_report_path(TripReport.last)
  end

  test "should show trip_report" do
    sign_in @admin
    get trip_report_url(@trip_report)
    assert_response :success
  end

  test "should get edit" do
    sign_in @admin
    get edit_trip_report_url(@trip_report)
    assert_response :success
  end

  test "should update trip_report" do
    sign_in @admin
    put trip_report_url(@trip_report), params: { trip_report: @trip_report.attributes }
    assert_redirected_to trip_report_path(@trip_report)
  end
end
