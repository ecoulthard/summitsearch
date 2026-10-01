require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Summitsearch
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    config.action_controller.raise_on_missing_callback_actions = false

    Rails.autoloaders.main.collapse(
      Rails.root.join("app/models/routes"),
      Rails.root.join("app/models/places"),
      Rails.root.join("app/models/places/details"),
      Rails.root.join("app/models/join_models")
    )

    Rails.autoloaders.main.ignore(
      Rails.root.join("app/models/forem"),
      Rails.root.join("app/controllers/forem"),
      Rails.root.join("app/helpers/forem")
    )
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    #Load environment variables
    config.notifier_email = ENV['NOTIFIER_EMAIL']
    config.facebook_app_id = ENV['FACEBOOK_APP_ID']
    config.google_maps_api_key = ENV['GOOGLE_MAPS_API_KEY']
    config.my_topo_partner_id = ENV['MY_TOPO_PARTNER_ID']
    config.my_topo_hex_digest = ENV['MY_TOPO_HEX_DIGEST']


  end
end
