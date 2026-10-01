require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  fixtures :users, :places

  test "article_first_comment creates email" do
    place = places(:columbia)
    mail = UserMailer.article_first_comment("mountain", place)
    assert_equal "Someone has commented on your Mountain", mail.subject
    assert_equal [place.user.email], mail.to
  end

  test "notify_admins creates email" do
    mail = UserMailer.notify_admins("Important admin alert")
    assert_equal "Summit Search Admin Notification", mail.subject
    assert_includes mail.body.encoded, "Important admin alert"
  end

  test "notify_admins_critical creates email" do
    mail = UserMailer.notify_admins_critical("System error occurred")
    assert_equal "Summit Search Critical Admin Notification", mail.subject
    assert_includes mail.body.encoded, "System error occurred"
  end

  test "notify_admins_that_article_is_liked creates email" do
    mail = UserMailer.notify_admins_that_article_is_liked("mountain", 1, "Mount Columbia", true, false, false, true)
    assert_equal "Summit Search Article Liked", mail.subject
  end
end
