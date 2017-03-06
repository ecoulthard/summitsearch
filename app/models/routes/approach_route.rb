class ApproachRoute < Route
  validates :place_id, :presence => true
  validate :must_be_close_to_place

  #Used to be false but sometimes we do need to branch from approach routes. EG: To go to a campground
  ALLOW_BRANCHES = true
  MIN_DISTANCE_TO_PLACE_REQUIRED = 5#km 
       
  private

  #Must be within 5km of place to qualify as an approach route.
  def must_be_close_to_place
    return unless waypoints_changed?
    if place_id.nil?
      errors.add(:place_id, "This approach route doesn't have a place id.")
      return
    end
    found = false
    self.waypoints_minus_removed.each do |waypoint|
      found = true if waypoint.dist(place.latitude, place.longitude) <= MIN_DISTANCE_TO_PLACE_REQUIRED
    end
    errors.add(:waypoints, "This approach route must have a waypoint within #{MIN_DISTANCE_TO_PLACE_REQUIRED}km of #{place.name}") if !found
  end
end
