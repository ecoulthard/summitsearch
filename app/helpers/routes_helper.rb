module RoutesHelper

  #Renders nested waypoint fields and returns escaped for javascript
  def waypoint_fields(f)
    new_object = f.object.class.reflect_on_association(:waypoints).klass.new  
    fields = f.fields_for(:waypoints, new_object, :child_index => "new_waypoints") do |builder|  
      render("waypoint_fields", :f => builder)  
    end
    escape_javascript(fields)
  end

  #Renders nested waypoint fields and returns escaped for javascript
  def waypoint_bubble_fields(f)  
    new_object = f.object.class.reflect_on_association(:waypoints).klass.new  
    bubble_fields = f.fields_for(:waypoints, new_object, :child_index => "new_waypoints") do |builder|  
      render("waypoint_bubble_fields", :f => builder)  
    end 
    escape_javascript(bubble_fields)
    #button_to_function(name, "Route.addNewWaypoint(this, \"#{association}\", \"#{escape_javascript(fields)}\", \"#{escape_javascript(bubble_fields)}\")", :id => "Add Waypoint")
  end

end
