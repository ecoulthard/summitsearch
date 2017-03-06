Forem.user_class = "User"
Forem.user_profile_links = true
Forem.email_from_address = "SummitSearch Notifier <" + ENV['NOTIFIER_EMAIL'] + ">"
Rails.application.config.to_prepare do
  Forem::ForumsController.layout "forem"
  Forem::CategoriesController.layout "forem"
  Forem::TopicsController.layout "forem"
  Forem::PostsController.layout "forem"
  Forem::Admin::BaseController.layout "forem"
  Forem::Admin::CategoriesController.layout "forem"
  Forem::Admin::ForumsController.layout "forem"
  Forem::Admin::TopicsController.layout "forem"
end
