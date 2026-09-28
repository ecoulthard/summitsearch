require "test_helper"

class TripReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trip_report = TripReport.first
  end

  test "should get index in xml" do
    get trip_reports_url(format: :xml)
    assert_response :success
  end

  test "should get show in xml" do
    get trip_report_url(@trip_report, format: :xml)
    assert_response :success
  end
end
