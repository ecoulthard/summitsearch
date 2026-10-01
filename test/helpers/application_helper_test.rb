require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "nth returns proper ordinal string" do
    assert_equal "1st", nth(1)
    assert_equal "2nd", nth(2)
    assert_equal "3rd", nth(3)
    assert_equal "4th", nth(4)
    assert_equal "11th", nth(11)
    assert_equal "12th", nth(12)
    assert_equal "13th", nth(13)
    assert_equal "21st", nth(21)
    assert_equal "22nd", nth(22)
    assert_equal "23rd", nth(23)
  end

  test "partial_date_string formats date accurately" do
    assert_equal "on January, 15 of 2026", partial_date_string(2026, 1, 15)
    assert_equal "in January of 2026", partial_date_string(2026, 1, nil)
    assert_equal "in 2026", partial_date_string(2026, nil, nil)
  end

  test "distance calculates geodesic distance between coordinates" do
    # Distance between Banff (51.1784, -115.5708) and Canmore (51.0890, -115.3597) ~ 17.8 km
    dist = distance(51.1784, -115.5708, 51.0890, -115.3597)
    assert dist > 15 && dist < 20
  end
end
