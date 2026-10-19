require "test_helper"

class PlaceTest < ActiveSupport::TestCase
  fixtures :places
  fixtures :mountain_details

  test "saving a mountain border refreshes subpeaks even when its area stays the same" do
    attributes = { name_status: "Official", insert_id: users(:vador).id }
    old_peak = Mountain.create!(attributes.merge(name: "Old Subpeak", latitude: 10.5, longitude: 20.5))
    new_peak = Mountain.create!(attributes.merge(name: "New Subpeak", latitude: 10.5, longitude: 22.5))
    mountain = Mountain.create!(attributes.merge(
      name: "Border Mountain", latitude: 10.6, longitude: 20.6,
      border_points_attributes: [[10, 20.5], [10.5, 21], [11, 20.5], [10.5, 20]].each_with_index.map do |(lat, lon), index|
        { latitude: lat, longitude: lon, local_index: index }
      end
    ))

    assert_includes mountain.mountains.reload, old_peak
    assert_not_includes mountain.mountains, new_peak
    original_area = mountain.area

    mountain.update!(border_points_attributes: mountain.border_points.map { |point|
      { id: point.id, latitude: point.latitude, longitude: point.longitude + 2 }
    })

    assert_in_delta original_area, mountain.reload.area, 0.000001
    assert_includes mountain.mountains.reload, new_peak
    assert_not_includes mountain.mountains, old_peak

    mountain.update!(border_points_attributes: mountain.border_points.map { |point|
      { id: point.id, _destroy: true }
    })
    assert_empty mountain.mountains.reload
  end

  test "place attributes must not be empty" do
    place = Place.new
    assert place.invalid?
    assert place.errors[:name].any?
    assert place.errors[:latitude].any?
  end

  test "place height must be within bounds" do
    place = Place.new(
      name: "Little Mountain",
      name_status: "Official",
      latitude: 10.1,
      longitude: 20.1,
      insert_id: 1
    )
    place.height = -1
    assert place.invalid?
    assert_equal "must be greater than or equal to 0", place.errors[:height].join("; ")
    place.height = 9000
    assert place.invalid?
    assert_equal "must be less than 9000", place.errors[:height].join("; ")
    place.height = 1
    assert place.valid?
  end

  test "place is not valid without unique coordinates" do
    place = Place.new(
      name: "Mount Columbia",
      name_status: "Official",
      latitude: places(:columbia).latitude,
      longitude: places(:columbia).longitude,
      insert_id: 1
    )
    assert_not place.save
    assert_equal "Must be at least 20 meters from other places", place.errors[:latitude].join("; ")
  end

  test "place is not valid if too close to other places" do
    place = Place.new(
      name: "Mount Not A Mountain",
      name_status: "Unofficial",
      latitude: places(:columbia).latitude - 0.0001,
      longitude: places(:columbia).longitude + 0.0001,
      insert_id: 1
    )
    assert_not place.save 
    assert_equal "Must be at least 20 meters from other places", place.errors[:latitude].join("; ")
  end

  test "set_partial_name_match is false when a nearby place contains the trimmed name of this peak" do
    place = Place.new(
      name: "Edward Peak",
      alternate_names: "Lyell 2",
      name_status: "Official",
      latitude: 51.95944,
      longitude: -117.09500,
      insert_id: 1
    )
    place.set_partial_name_match
    assert_not place.partial_name_match, "Shouldn't have set partial name match"

    place = places(:king_edward) 
    place.set_partial_name_match
    assert place.partial_name_match, "Should have set partial name match"
  end

  test "Parent Mountain is set to correct mountain for columbia icefield peaks" do
    places(:king_edward).height = 3491
    places(:king_edward).save
    places(:north_twin).height = 3732
    places(:north_twin).save
    places(:south_twin).height = 3581
    places(:south_twin).save
    places(:stutfield).height = 3451
    places(:stutfield).save
    places(:kitchener).height = 3481
    places(:kitchener).save
    places(:snowdome).height = 3452
    places(:snowdome).save
    places(:andromeda).height = 3451
    places(:andromeda).save
    places(:athabasca).height = 3443
    places(:athabasca).save
    places(:castleguard).height = 3084
    places(:castleguard).save

    assert_equal places(:columbia).name, places(:king_edward).parent_mountain&.name
    assert_equal places(:columbia).name, places(:north_twin).parent_mountain&.name
    assert_equal places(:north_twin).name, places(:south_twin).parent_mountain&.name
    assert_equal places(:north_twin).name, places(:stutfield).parent_mountain&.name
    assert_equal places(:north_twin).name, places(:kitchener).parent_mountain&.name
    assert_equal places(:kitchener).name, places(:snowdome).parent_mountain&.name
    assert_equal places(:snowdome).name, places(:andromeda).parent_mountain&.name
    assert_equal places(:andromeda).name, places(:athabasca).parent_mountain&.name
    assert_equal places(:andromeda).name, places(:castleguard).parent_mountain&.name
  end
end
