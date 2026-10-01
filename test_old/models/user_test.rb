require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "Cannot delete last admin" do
    admin = users(:vador)
    assert admin.valid?
    begin
      admin.destroy
      assert false, "Last admin was destroyed without exception being thrown."
    rescue Exception => e
	assert_equal e.message, "Can't delete last admin"
    end
  end

end
