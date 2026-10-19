require "test_helper"

class PlacesControllerTest < ActionDispatch::IntegrationTest
  fixtures :places, :mountain_details, :users

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @place = Mountain.new(
      name: "Mount Forbes",
      name_status: "Official",
      latitude: 51.86000,
      longitude: -116.93166,
      height: 3617,
      ref_place_id: places(:columbia).id,
      partial_name_match: true,
      insert_id: @admin.id
    )

    @dup_place = Mountain.new(
      name: "North Twin",
      name_status: "Official",
      latitude: 52.22500,
      longitude: -117.43584,
      height: 3731,
      ref_place_id: places(:columbia).id,
      partial_name_match: true,
      insert_id: @admin.id
    )
  end

  test "should get index" do
    get places_url
    assert_response :success
  end

  test "should get new icefield" do
    sign_in @admin
    get new_place_url, params: { type: "Icefield", ref_place_id: places(:one).id }
    assert_response :success
  end

  test "should not create icefield" do
    sign_in @admin
    assert_no_difference("Place.count") do
      post places_url, params: { place: @dup_place.attributes }
    end
    assert_response :unprocessable_entity
  end

  test "should show icefield" do
    get place_url(places(:one))
    assert_response :success
  end

  test "should get new" do
    sign_in @admin
    get new_place_url, params: { type: "Mountain", ref_place_id: places(:castleguard).id }
    assert_response :success
  end

  test "should create place" do
    sign_in @admin
    assert_difference("Place.count") do
      post places_url, params: { place: @place.attributes }
    end

    assert_redirected_to place_path(Place.last)
  end

  test "should show place" do
    get place_url(places(:castleguard))
    assert_response :success
  end

  test "should get edit" do
    sign_in @editor
    get edit_place_url(places(:castleguard))
    assert_response :success
  end

  test "should get edit for mountain with ascents" do
    sign_in @editor
    person = Person.create!(name: "Conrad Kain", insert_id: @admin.id)
    mountain = places(:castleguard)
    ascent = mountain.ascents.build(year: 1923, description: "First ascent test")
    ascent.ascent_people.build(person_id: person.id)
    mountain.save(validate: false)

    get edit_place_url(mountain)
    assert_response :success
  end

  test "should update place" do
    sign_in @editor
    put place_url(places(:castleguard)), params: { place: places(:castleguard).attributes }
    assert_redirected_to place_path(places(:castleguard))
  end
  test "should persist border points added on the edit form" do
    sign_in @editor
    place = places(:castleguard)
    index = place.border_points.count
    attributes = place.border_points.each_with_index.to_h { |point, i| [i.to_s, point.attributes] }
    3.times do |offset|
      attributes[(index + offset).to_s] = {
        latitude: place.latitude + 0.001 * (offset + 1),
        longitude: place.longitude + 0.001 * (offset % 2),
        local_index: index + offset
      }
    end

    assert_difference("place.border_points.reload.count", 3) do
      put place_url(place), params: { place: { type: place.type, border_points_attributes: attributes } }
      assert_redirected_to place_path(place)
    end
    added = place.border_points.last
    assert_equal index + 2, added.local_index
    assert_in_delta place.latitude + 0.003, added.latitude
  end

end
