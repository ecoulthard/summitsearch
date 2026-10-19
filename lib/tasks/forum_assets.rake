namespace :thredded do
  namespace :assets do
    desc "Compile Thredded's Sass and JavaScript for Propshaft"
    task build: :environment do
      ForumAssets.build
    end
  end
end

# Runs inside the existing Docker/Kamal assets:precompile command as well.
Rake::Task["assets:precompile"].enhance([ "thredded:assets:build" ])
