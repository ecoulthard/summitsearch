# Propshaft serves compiled forum bundles, not the gem's Sass/ES6 sources.
thredded_root = Pathname.new(Gem.loaded_specs.fetch("thredded").full_gem_path)
Rails.application.config.assets.excluded_paths += [
  thredded_root.join("app/assets/javascripts"),
  thredded_root.join("app/assets/stylesheets"),
  thredded_root.join("app/assets/config"),
  thredded_root.join("app/assets/images"),
  thredded_root.join("vendor/assets/javascripts")
]

# Development needs no separate watcher for these versioned gem sources.
Rails.application.config.after_initialize do
  ForumAssets.build if Rails.env.development?
end
