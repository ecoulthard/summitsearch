require "test_helper"

class RouteTest < ActiveSupport::TestCase
  test "has_gps? returns false when no gps attached or file_name set" do
    route = Route.new
    assert_not route.has_gps?
  end

  test "has_gps? returns true when legacy gps_file_name is set" do
    route = Route.new(gps_file_name: "track.gpx")
    assert route.has_gps?
  end

  test "has_gps? returns true when ActiveStorage gps is attached" do
    route = Route.new
    route.gps.attach(io: StringIO.new("<gpx></gpx>"), filename: "track.gpx", content_type: "application/gpx+xml")
    assert route.has_gps?
  end

  test "validates content type on gps attachment" do
    route = Route.new(name: "Test Route", insert_id: 1, type: "Trail", name_status: "Official", travel_time: "2 hours")
    route.gps.attach(io: StringIO.new("fake binary"), filename: "bad.exe", content_type: "application/x-msdownload")
    assert_not route.valid?
    assert_includes route.errors[:gps], "must be a GPX file"
  end

  test "validates max file size on gps attachment" do
    route = Route.new(name: "Test Route", insert_id: 1, type: "Trail", name_status: "Official", travel_time: "2 hours")
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake large gpx"),
      filename: "large.gpx",
      content_type: "application/gpx+xml"
    )
    blob.update_column(:byte_size, 6.megabytes)
    route.gps.attach(blob)
    assert_not route.valid?
    assert_includes route.errors[:gps], "must be less than 5MB"
  end

  test "syncs attachment attributes on validation" do
    route = Route.new(name: "Test Route", insert_id: 1, type: "Trail", name_status: "Official", travel_time: "2 hours")
    content = "<gpx version=\"1.1\"></gpx>"
    route.gps.attach(io: StringIO.new(content), filename: "test_track.gpx", content_type: "application/gpx+xml")
    route.sync_attachment_attributes

    assert_equal "test_track.gpx", route.gps_file_name
    assert_equal "application/gpx+xml", route.gps_content_type
    assert_equal content.bytesize, route.gps_file_size
    assert_not_nil route.gps_updated_at
  end
end
