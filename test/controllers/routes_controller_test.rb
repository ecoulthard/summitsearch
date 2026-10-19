require "test_helper"

class RoutesControllerTest < ActionDispatch::IntegrationTest
  fixtures :routes, :users, :places

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @route = routes(:columbia)
    @route.name = "North Twin Ascent"
  end

  test "should get index" do
    get routes_url
    assert_response :success
  end

  test "should get new" do
    sign_in @admin
    get new_route_url, params: { type: "Scramble", place_id: places(:columbia).id }
    assert_response :success
  end

  test "should create route" do
    sign_in @admin
    route = Route.new(name: "North Twin", name_status: "Official", travel_time: "Unknown", insert_id: users(:vador).id)

    waypoints_data = [
      [52.2197420249697, -117.22538315185545, -1, 1982],
      [52.20217587589444, -117.24546753295897, 0, 2156],
      [52.16670686505061, -117.28632294067381, 1, 2787],
      [52.17049718923302, -117.32185684570311, 2, 3081],
      [52.223107200708014, -117.40803085693358, 3, 3230],
      [52.21742831872597, -117.4313768041992, 4, 3537],
      [52.22542831872597, -117.43498169311522, 5, 3644],
      [52.2337268641058, -117.405284274902, 4, 3358],
      [52.2427673475595, -117.411292423096, 7, 3346],
      [52.246235881402, -117.402366031494, 8, 3263],
      [52.2555890604279, -117.395671237793, 9, 3162]
    ]

    waypoints_attributes = {}
    waypoints_data.each_with_index do |(lat, lng, p_idx, h), idx|
      waypoints_attributes[idx.to_s] = {
        latitude: lat,
        longitude: lng,
        local_index: idx,
        parent_index: p_idx,
        height: h
      }
    end

    assert_difference("Route.count") do
      post routes_url, params: {
        route: {
          name: "North Twin Ascent",
          type: "Route",
          name_status: "Official",
          travel_time: "Unknown",
          insert_id: users(:vador).id,
          place_id: places(:north_twin).id,
          distance: 26.47,
          height_gain: 1942,
          height_loss: 238,
          waypoints_attributes: waypoints_attributes
        }
      }
    end

    created_route = Route.last
    assert_redirected_to route_path(created_route)
    assert_equal places(:north_twin).height.to_f, created_route.waypoints[6].height.to_f
    assert_equal 2, created_route.places.count
  end

  test "should show route" do
    sign_in @admin
    get route_url(routes(:columbia))
    assert_response :success
  end

  test "should get edit" do
    sign_in @editor
    get edit_route_url(routes(:columbia))
    assert_response :success
  end

  test "should update route" do
    sign_in @admin
    route = routes(:columbia)
    wp_attrs = {}
    route.waypoints.each_with_index do |wp, idx|
      wp_attrs[idx.to_s] = wp.attributes
    end

    put route_url(route), params: {
      route: {
        name: route.name,
        type: "Scramble",
        name_status: "Official",
        travel_time: "Unknown",
        insert_id: users(:vador).id,
        place_id: places(:columbia).id,
        waypoints_attributes: wp_attrs
      }
    }
    assert_redirected_to route_path(route)
  end
  test "should persist a waypoint appended on the edit form" do
    sign_in @admin
    route = routes(:columbia)
    existing = route.waypoints.to_a
    last = existing.last
    index = existing.length
    attributes = existing.each_with_index.to_h { |point, i| [i.to_s, point.attributes] }
    attributes[index.to_s] = {
      latitude: last.latitude + 0.001,
      longitude: last.longitude,
      local_index: index,
      parent_index: last.local_index,
      height: last.height
    }

    assert_difference("route.waypoints.reload.count", 1) do
      put route_url(route), params: {
        route: { name: route.name, type: route.type, waypoints_attributes: attributes }
      }
      assert_redirected_to route_path(route)
    end
    added = route.waypoints.last
    assert_equal index, added.local_index
    assert_equal last.local_index, added.parent_index
    assert_in_delta last.latitude + 0.001, added.latitude
  end

end
