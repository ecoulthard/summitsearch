module PlacesHelper

  #Renders nested model fields and returns escaped for javascript
  def border_point_fields(f)  
    new_object = f.object.class.reflect_on_association(:border_points).klass.new  
    fields = f.fields_for(:border_points, new_object, :child_index => "new_border_points") do |builder|  
      render("border_point_fields", :f => builder)  
    end
    escape_javascript(fields)
  end

end
