Mountain.transaction do
  (1..100).each do |i|
    Mountain.create(:name => "Mountain #{i}" , :height => "#{i}00",
     :latitude => "77.77", :longitude => "#{i}.77" , :insert_id => 1 )
  end
end

