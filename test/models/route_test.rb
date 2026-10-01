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

  test "route without points cannot be saved" do
    route = Scramble.new(name: "Skyline Trail", travel_time: "Unknown", insert_id: users(:vador).id)
    assert route.invalid?
  end

  test "route with waypoints can be saved" do
    route = Scramble.new(
      name: "North Twin via Athabasca Glacier",
      travel_time: "Unknown",
      insert_id: users(:vador).id,
      place_id: places(:north_twin).id
    )

    waypoints_data = [
      [52.2197420249697, -117.22538315185545, -1, 1982],
      [52.20217587589444, -117.24546753295897, 0, 2156],
      [52.16670686505061, -117.28632294067381, 1, 2787],
      [52.17049718923302, -117.32185684570311, 2, 3081],
      [52.223107200708014, -117.40803085693358, 3, 3230],
      [52.21742831872597, -117.4313768041992, 4, 3537],
      [52.22521030605203, -117.43498169311522, 5, 3731],
      [52.2337268641058, -117.405284274902, 4, 3358],
      [52.2427673475595, -117.411292423096, 7, 3346],
      [52.246235881402, -117.402366031494, 8, 3263],
      [52.2555890604279, -117.395671237793, 9, 3162]
    ]

    waypoints_data.each_with_index do |(lat, lng, p_idx, h), idx|
      route.waypoints.build(
        latitude: lat,
        longitude: lng,
        local_index: idx,
        parent_index: p_idx,
        height: h
      )
    end

    assert_equal 11, route.waypoints.length
    route.waypoints.each do |waypoint|
      assert_not waypoint.invalid?
    end

    assert route.save
  end

  test "route attributes must not be empty" do
    route = Trail.new
    assert route.invalid?
    assert route.errors[:name].any?
    assert route.errors[:travel_time].any?
    assert route.errors[:insert_id].any?
  end
end
