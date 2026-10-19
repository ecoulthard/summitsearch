namespace :thredded do
  namespace :articles do
    desc "Rebuild public article comment totals after the Forem import"
    task recount: :environment do
      unless ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM forum_import_runs").to_i.positive?
        abort "Import Forem before recounting article comments"
      end
      ArticleCommentTotals.refresh_all
      puts "Article comment totals and last-comment timestamps rebuilt"
    end
  end
end
