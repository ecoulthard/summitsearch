Province.transaction do
  Province.create(:name => "Alberta", :country => "Canada", :province_or_state => "Province")
  Province.create(:name => "British Columbia", :country => "Canada", :province_or_state => "Province")
  Province.create(:name => "Yukon", :country => "Canada", :province_or_state => "Province")
  Province.create(:name => "Nunavut", :country => "Canada", :province_or_state => "Territory")
  Province.create(:name => "Alaska", :country => "United States", :province_or_state => "Territory")
  Province.create(:name => "British Columbia/Alberta", :country => "Canada", :province_or_state => "Borders")
end
