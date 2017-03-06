class SendArticleFirstCommentEmailWorker
  include Sidekiq::Worker

  def perform(article_type, article_class, article_id)
      article = article_class.constantize.find(article_id)
      UserMailer.article_first_comment(article_type, article).deliver
  end
end
