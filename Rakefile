# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
#This require is only needed if we are using sunspot_rails 2.0.0
#It should be commented out for deployment.
#require 'sunspot/solr/tasks'

Summitsearch::Application.load_tasks
