class UserMailer < ActionMailer::Base
  default :from => "SummitSearch Notifier <" + ENV['NOTIFIER_EMAIL'] + ">"

  def article_first_comment(article_type, article)
    @article_type = article_type
    @article = article
    mail(:to => article.user.email, :subject => "Someone has commented on your #{article_type.humanize}")
  end

  def notify_admins_critical(message)
    @message = message
    mail(:to => User.find_admins.map(&:email).join(", "), :subject => "Summit Search Critical Admin Notification")
  end  

  def notify_admins(message)
    @message = message
    mail(:to => User.find_admins.map(&:email).join(", "), :subject => "Summit Search Admin Notification")
  end

  #Notifies admin users that an article was liked or unliked.
  def notify_admins_that_article_is_liked(article_type, article_id, article_title, liked, facebook, google, summitsearch)
    @article_type = article_type
    @article_id = article_id
    @article_title = article_title
    @liked_phrase = case
                 when summitsearch then "given a thumbs up"
                 when facebook then "liked"
                 when google then "+1'ed"
                 else "voted up"
                 end
    @liked_phrase  = "un" + @liked_phrase unless liked
    mail(:to => User.find_admins.map(&:email).join(", "), :subject => "Summit Search Article Liked")
  end
end
