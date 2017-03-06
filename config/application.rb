require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Summitsearch
  class Application < Rails::Application
   # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]


    #config.middleware.use ExceptionNotification::Rack,
    #    :email => {
    #        :email_prefix => "SummitSearch-Errors: ",
    #        :sender_address => %{ENV['NOTIFIER_EMAIL']},
    #        :exception_recipients => %w{me@me.com}
    #    }

    #This line was added due to a depreciation warning.
    #DEPRECATION WARNING: Currently, Active Record suppresses errors raised within `after_rollback`/`after_commit` callbacks and only print them to the logs. In the next version, these errors will no longer be suppressed. Instead, the errors will propagate normally just like in other Active Record callbacks.
    #You can opt into the new behavior and remove this warning by setting:
    #config.active_record.raise_in_transactional_callbacks = true

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure generators values. Many other options are available, be sure to check the documentation.
    # config.generators do |g|
    #   g.orm             :active_record
    #   g.template_engine :erb
    #   g.test_framework  :test_unit, :fixture => true
    # end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Here is where I put inheritance subdirectories for models
    inherited_models = %w(routes places join_models places/details)
    inherited_models.each do |dir|
      config.autoload_paths << "#{::Rails.root.to_s}/app/models/#{dir}"
    end

    #We needed to increase this value from 65536 because it wouldn't accept routes with
    #over 140 waypoints.
    Rack::Utils.key_space_limit = 1048576 #2^20

  end
end
