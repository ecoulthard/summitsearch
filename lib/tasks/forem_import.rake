namespace :thredded do
  namespace :forem do
    desc "Read-only checks for a one-shot Forem import"
    task preflight: :environment do
      report = ForemImport.new.preflight
      puts JSON.pretty_generate(report)
      abort "Preflight failed; no data was changed" if report[:errors].any?
    end

    desc "Import Forem into empty Thredded tables (transactional; refuses reruns)"
    task import: :environment do
      puts JSON.pretty_generate(ForemImport.new.run!)
    rescue ForemImport::UnsafeImport => error
      abort error.message
    end
  end
end
