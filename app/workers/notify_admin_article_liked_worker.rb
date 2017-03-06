class NotifyAdminArticleLikedWorker
  include Sidekiq::Worker

  def perform(article_type, article_id, article_title, liked, facebook, google, summitsearch)
      UserMailer.notify_admins_that_article_is_liked(article_type, article_id, article_title, liked, facebook, google, summitsearch).deliver
  end
end
