namespace :thredded do
  namespace :users do
    desc "Audit legacy usernames without changing users or constraints"
    task audit: :environment do
      puts JSON.pretty_generate(ForumUserAudit.report)
    end
  end
end
