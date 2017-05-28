#Update one gem only
#bundle update --source rake

source 'http://rubygems.org'
ruby "2.2.4"

gem 'rails', '< 4.2'
gem 'rdoc'
gem 'rake', '=10.3.2'

gem 'mysql2' #Active support gets bitchy if we don't include this. Also thinking sphinx wants it as well.
gem 'pg'
gem 'devise', '> 3.2.4' #Rails defacto user management gem.
gem 'paperclip', '4.3.5' #For uploading photos. >4.3.5 does not support rails <4.2
gem 'exifr' #Provides access to image meta data.
#gem "exception_notification" #Sends error emails for uncaught exceptions
gem 'forem', :github => "radar/forem", :branch => "rails4" #Adds the forum engine.
gem 'friendly_id' #Included by forem. But we need it here anyway since we use for our own models for some reason.
gem 'actionpack-action_caching' #Required for us to use action caching
gem 'rails-observers' #Required for us to use cache_sweepers

#Todo *** Install a better versioning gem than vestal_versions.
gem 'vestal_versions', :git => 'git://github.com/jodosha/vestal_versions.git'

#Search gem
gem 'thinking-sphinx'
gem 'flying-sphinx'

#Amazon web services gem. Need version < 2 because of an issue that makes the app crash.
#This issue was introduced with new version of aws-sdk (2.0+). You can read more here: http://ruby.awsblog.com/post/TxFKSK2QJE6RPZ/Upcoming-Stable-Release-of-AWS-SDK-for-Ruby-Version-2
gem 'aws-sdk', '< 2.0'

#Cron job gems

#View/css/javascript gems
gem "sprockets", "<= 2.9" #This line didn't used to be needed. rails server and other commands stoped working and this line fixed it. Try to remove in the future when updating.
gem "nested_form" # Allows nested forms. We use this for names and first ascents
gem "coffeebeans" #Allows you to use coffeescript_tag to use coffeescript in html.erb files.
gem "asset_pipeline_routes" #Gives javascript routes.
gem 'will_paginate' , '>= 3.0.0' #The defacto standard pagination gem for rails 3.
gem 'jquery-ui-themes' #So we don't have to keep our own jquery css theme.

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', "< 5.0"
gem 'jquery-turbolinks'

#Sidekiq gems
gem 'sidekiq', '> 3.2.1'
gem 'sinatra', require: false
gem 'slim'

# Gems used only in the development environment.  
group :development do
  gem 'therubyracer' #js runtime
  gem 'web-console' #Adds a console on error pages.
  gem 'bullet' # Detects N+1 Queries and unused eager loading.

  gem 'rails_best_practices'#Adds a rake task rake rails_best_practices. Currently errors when run.
  gem 'brakeman'#Adds a rake task "rake brakeman". Checks for security issues.
  gem 'rails-dev-tweaks', '>= 0.5.0' #Asset requests will not reload app code. xhr requests will.
  
  #Capistrano gems
  #gem 'capistrano', "2.15.0" # Deploy with Capistrano. v3 is a nightmare. 
  #gem 'capistrano-sidekiq' #Add sidekiq deployment to capistrano.
  #gem 'capistrano-rbenv' #Needed for cap 3
  #gem 'capistrano-bundler' #Needed for cap 3
  #gem 'capistrano-rails' #Needed for cap 3
end

# Gems used only for assets and not required in production environments by default.  
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'  
gem 'jquery-rails'
gem 'jquery-ui-rails' 
gem 'modernizr-rails' #Adds modernizer to asset pipeline
gem 'fancybox2-rails' #Adds jquery fancybox2 to asset pipeline
gem "markitup-rails" #Adds markitup to the asset pipeline
gem "respond-rails" #Adds respond.js to asset pipeline. This adds support for min-max width in IE6-8. 

# Gems used only for test environments.  
group :test do
  gem 'capybara' #Provides all the helper functions used by the integration test.
  gem 'launchy' #Need this for capybara according to Railscast 257. Not sure why.
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc'
end

group :production do
  gem 'rails_12factor' #This gem is only needed for heroku.
  gem 'puma'
end

gem 'tzinfo-data' # Need only to run on windows.

# Gems we no longer need? Uncomment and move them into the correct place above if they become needed.

# Gems used only in production.  
#group :production do
#  gem 'therubyracer' #Embed the V8 JavaScript interpreter into Ruby
#end
