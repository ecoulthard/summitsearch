Summitsearch::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  #config.force_ssl = true 

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # Compress JavaScript and CSS  
  config.assets.compress = true  
         
  config.assets.compile = true
  #config.assets.precompile =  ['*.js', '*.css', '*.css.erb', '*.jpg', '*.png']

  # Generate digests for assets URLs  
  config.assets.digest = true  

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  config.cache_store = :file_store, "cache"

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_files = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { :host => 'summitsearch.org' }

  # I care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.smtp_settings = {
   	  :address => "smtp.gmail.com" ,
   	  :port => 587,
   	  :domain => "summitsearch.org",
	  :user_name => ENV['NOTIFIER_EMAIL'],
	  :password => ENV['NOTIFIER_EMAIL_PASSWORD'],
   	  :authentication => :login ,
   	  :enable_starttls_auto => true
  }
  config.action_mailer.defaul :content_type => "text/html"

  # This check blocks my tablet in Rampart Creek Hostel.
  config.action_dispatch.ip_spoofing_check = false

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

end
