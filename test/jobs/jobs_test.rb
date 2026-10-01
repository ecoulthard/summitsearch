require "test_helper"

class JobsTest < ActiveJob::TestCase
  test "log visit job handles execution without crashing" do
    assert_nothing_raised do
      # Test with mock / safe inputs
      LogVisitJob.new.perform("Mozilla/5.0", "127.0.0.1", nil, Time.current, "TripReport", nil, false)
    end
  end

  test "log forem visit job handles execution without crashing" do
    assert_nothing_raised do
      LogForemVisitJob.new.perform("Mozilla/5.0", "127.0.0.1", nil, Time.current, nil, nil)
    end
  end

  test "update article total likes job handles missing article gracefully" do
    assert_nothing_raised do
      UpdateArticleTotalLikesJob.perform_now("TripReport", 999999999, Time.current, true)
    end
  end

  test "update article total comments job handles missing article gracefully" do
    assert_nothing_raised do
      UpdateArticleTotalCommentsJob.perform_now("TripReport", 999999999, Time.current)
    end
  end
end
