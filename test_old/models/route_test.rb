require 'test_helper'

class RouteTest < ActiveSupport::TestCase
  fixtures :routes
  fixtures :places
  fixtures :users

  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "route without points can't be saved" do
	  route = Scramble.new(:name => 'Skyline Trail',
  			    :travel_time => 'Unknown',
			    :insert_id => users(:vador).id)
	  assert route.invalid?
  end

  test "route with waypoints can be saved" do
  	route = Scramble.new(:name => 'North Twin via Athabasca Glacier',
  			    :travel_time => 'Unknown',
			    :insert_id => users(:vador).id,
			    :place_id => places(:north_twin).id)
	waypoint1 = route.waypoints.build
	waypoint2 = route.waypoints.build
	waypoint3 = route.waypoints.build
	waypoint4 = route.waypoints.build
	waypoint5 = route.waypoints.build
	waypoint6 = route.waypoints.build
	waypoint7 = route.waypoints.build
	waypoint8 = route.waypoints.build
	waypoint9 = route.waypoints.build
	waypoint10 = route.waypoints.build
	waypoint11 = route.waypoints.build

	waypoint1.latitude = 52.2197420249697
	waypoint1.longitude = -117.22538315185545
	waypoint2.latitude = 52.20217587589444
	waypoint2.longitude = -117.24546753295897
	waypoint3.latitude = 52.16670686505061
	waypoint3.longitude = -117.28632294067381
	waypoint4.latitude = 52.17049718923302
	waypoint4.longitude = -117.32185684570311
	waypoint5.latitude = 52.223107200708014
	waypoint5.longitude = -117.40803085693358
	waypoint6.latitude = 52.21742831872597
	waypoint6.longitude = -117.4313768041992
	waypoint7.latitude = 52.22521030605203
	waypoint7.longitude = -117.43498169311522
	waypoint8.latitude = 52.2337268641058
	waypoint8.longitude = -117.405284274902
	waypoint9.latitude = 52.2427673475595
	waypoint9.longitude = -117.411292423096
	waypoint10.latitude = 52.246235881402
	waypoint10.longitude = -117.402366031494
	waypoint11.latitude = 52.2555890604279
	waypoint11.longitude = -117.395671237793

	waypoint1.local_index = 0
	waypoint2.local_index = 1
	waypoint3.local_index = 2
	waypoint4.local_index = 3
	waypoint5.local_index = 4
	waypoint6.local_index = 5
	waypoint7.local_index = 6
	waypoint8.local_index = 7
	waypoint9.local_index = 8
	waypoint10.local_index = 9
	waypoint11.local_index = 10
	waypoint1.parent_index = -1
	waypoint2.parent_index = 0
	waypoint3.parent_index = 1
	waypoint4.parent_index = 2
	waypoint5.parent_index = 3
	waypoint6.parent_index = 4
	waypoint7.parent_index = 5
	waypoint8.parent_index = 4
	waypoint9.parent_index = 7
	waypoint10.parent_index = 8
	waypoint11.parent_index = 9
	waypoint1.height = 1982
	waypoint2.height = 2156
	waypoint3.height = 2787
	waypoint4.height = 3081
	waypoint5.height = 3230
	waypoint6.height = 3537
	waypoint7.height = 3731
	waypoint8.height = 3358
	waypoint9.height = 3346
	waypoint10.height = 3263
	waypoint11.height = 3162
	
	assert_equal route.waypoints.length, 11
	route.waypoints.each do |waypoint|
	  assert !waypoint.invalid?
	end

	assert route.save
        #These are no longer set by route.rb. They are set in javascript.
        #assert_equal 25, route.distance.round.to_f
        #assert_equal 1877, route.height_gain
        #assert_equal 196, route.height_loss
  end

  test "route attributes must not be empty" do
    route = Trail.new
    assert route.invalid?
    assert route.errors[:name].any?
    assert route.errors[:travel_time].any?
    assert route.errors[:insert_id].any?
  end

#  test "Route must have waypoints at most 20km apart" do
#	route = Scramble.new(:name => 'North Twin via Athabasca Glacier',
#  	    :travel_time => 'Unknown',
#	    :insert_id => users(:vador).id)
#	waypoint1 = route.waypoints.build
#	waypoint2 = route.waypoints.build
#	waypoint3 = route.waypoints.build
#
#	waypoint1.latitude = 52.2197420249697
#	waypoint1.longitude = -117.22538315185545
#	waypoint2.latitude = 1
#	waypoint2.longitude = -2
#	waypoint3.latitude = 52.16670686505061
#	waypoint3.longitude = -117.28632294067381
##
#	waypoint1.local_index = 0
#	waypoint2.local_index = 1
#	waypoint3.local_index = 2
#	waypoint1.parent_index = -1
#	waypoint2.parent_index = 1
#	waypoint3.parent_index = 2
#	waypoint1.height = 1982
#	waypoint2.height = 2156
#	waypoint3.height = 2787
#	assert route.invalid?
# end
end
