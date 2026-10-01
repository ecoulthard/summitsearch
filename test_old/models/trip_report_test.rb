require 'test_helper'

class TripReportTest < ActiveSupport::TestCase
  fixtures :trip_reports
  fixtures :photos
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "Trip Report attributes must not be empty" do
    trip_report = TripReport.new
    assert trip_report.invalid?
    assert trip_report.errors[:title].any?
    assert trip_report.errors[:user_id].any?
    assert trip_report.errors[:description].any?
  end

  #sqlite doesn't like hours with leading 0's
  test "Find by time returns trips at the given time" do
    assert_equal [trip_reports(:columbia)], TripReport.find_by_time(Time.utc(2009,'may',10,12,0,0))
    assert_equal [], TripReport.find_by_time(Time.utc(2009,'may',12,20,0,0))
    assert_equal [trip_reports(:columbia)], TripReport.find_by_time(Time.utc(2009,'may',11,17,30,0))
  end

  test "Photos are attached" do
    trip = trip_reports(:columbia)
    trip.attach_photos
    assert_equal 2, trip.photos.length
    assert !trip.photos.find_by_title("Mount Columbia").nil?
    assert !trip.photos.find_by_title("View North West of Mount Columbia").nil?
  end

end
