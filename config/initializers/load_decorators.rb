Rails.application.config.to_prepare do
  Dir.glob(Rails.root.join("app/**/*_decorator*.rb")) do |c|
    next if c.include?("/forem/") && !defined?(Forem)
    load(c)
  end
end
