require 'test_helper'

class WaypointTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "waypoint can be saved" do
	  waypoint = Waypoint.new(:location => 'point of no return',
				:latitude => 10.1,
				:longitude => 20.1,
				:local_index => 3,
				:parent_index => 0,
				:route_id => 1)
	  assert waypoint.save
  end

  test "waypoint attributes must not be empty" do
	  waypoint = Waypoint.new
	  assert waypoint.invalid?
	  assert waypoint.errors[:local_index].any?
	  assert waypoint.errors[:parent_index].any?
	  assert waypoint.errors[:latitude].any?
	  assert waypoint.errors[:longitude].any?
  end

  test "waypoint height must be within bounds" do
	  waypoint = Waypoint.new(:location => 'point of no return',
				:latitude => 10.1,
				:longitude => 20.1,
				:local_index => 3,
				:parent_index => 0,
				:route_id => 1)
	  waypoint.height = -1
	  assert waypoint.invalid?
	  assert_equal "must be greater than or equal to 0" ,
	    waypoint.errors[:height].join('; ' )
	  waypoint.height = 9000
	  assert waypoint.invalid?
	  assert_equal "must be less than 9000" ,
	    waypoint.errors[:height].join('; ' )
	  waypoint.height = 1
	  assert waypoint.valid?
  end

end
