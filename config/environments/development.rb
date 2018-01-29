Summitsearch::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Show full error reports
  config.consider_all_requests_local       = true
  #We enable caching for testing purposes. Use /expire to expire caches on pages.
  config.action_controller.perform_caching = true

  # Print deprecation reports to stderr
  config.active_support.deprecation = :stderr

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # I care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.smtp_settings = {
	  :address => "smtp.gmail.com" ,
	  :port => 587,
	  :domain => "summitsearch.org",
	  :user_name => ENV['NOTIFIER_EMAIL'],
	  :password => ENV['NOTIFIER_EMAIL_PASSWORD'],
	  :authentication => :plain,
	  :enable_starttls_auto => true
  }

  config.action_mailer.default :content_type => "text/html"

  # Do not compress assets  
  config.assets.compress = false  
         
  # Expands the lines which load the assets which makes it so that you need to look at log files to see what broke when something breaks. Way to verbose so I turned it off.
  config.assets.debug = true  

  config.log_level = :debug #debug, info, warn, error, fatal

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.paperclip_defaults = {
    :storage => :s3,
    :bucket => ENV['S3_BUCKET_NAME'],
    :s3_credentials => {
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
      :region => 'us-standard',
      :s3_host_name => 's3.amazonaws.com'
    }
  }

  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
#Bullet.add_footer = true
#Bullet.raise = true
#Bullet.unused_eager_loading_enable = false
  end
end
