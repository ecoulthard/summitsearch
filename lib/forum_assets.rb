# frozen_string_literal: true

# Compile only Thredded's legacy assets. Propshaft remains the Rails pipeline.
class ForumAssets
  def self.build
    require "sassc"
    require "sprockets"
    require "sprockets/es6"
    require "autoprefixer-rails"
    require "base64"
    require "fileutils"

    source = Pathname.new(Gem.loaded_specs.fetch("thredded").full_gem_path)
    destination = Rails.root.join("app/assets/builds")
    FileUtils.mkdir_p(destination)

    # Thredded embeds its breadcrumb SVG through this Sass helper. Keep the
    # helper local to this compilation rather than changing SassC globally.
    functions = Module.new do
      define_method(:image_url) do |name|
        # 1.2.1 references a calendar_48px icon but only ships calendar_128px.
        path = name.value.sub("logo_calendar_48px.png", "logo_calendar_128px.png")
        # Propshaft will fingerprint these logical URLs when serving/precompiling.
        SassC::Script::Value::String.new("url(\"#{path}\")")
      end
      define_method(:asset_data_url) do |name|
        image = source.join("app/assets/images", name.value)
        mime_type = Rack::Mime.mime_type(image.extname)
        data = Base64.strict_encode64(image.binread)
        SassC::Script::Value::String.new("url(\"data:#{mime_type};base64,#{data}\")")
      end
    end
    stylesheet = source.join("app/assets/stylesheets/thredded.scss")
    settings = Rails.root.join("lib/assets/forum_settings.scss").read
    css = SassC::Engine.new(settings + "\n" + stylesheet.read,
      filename: stylesheet.to_s,
      load_paths: [ stylesheet.dirname.to_s ],
      functions: functions,
      style: :compressed).render
    css += ".googledocs-onebox-logo.g-calendar-logo{background-size:48px 48px}" \
      ".gdocs-onebox-splash .gdocs-onebox-logo.g-calendar-logo{background-size:128px 128px}"
    css = AutoprefixerRails.process(css).css

    javascript = Sprockets::Environment.new(Rails.root)
    javascript.append_path(source.join("app/assets/javascripts"))
    javascript.append_path(source.join("vendor/assets/javascripts"))
    javascript.append_path(File.join(Gem.loaded_specs.fetch("timeago_js").full_gem_path, "assets/javascripts"))
    javascript.append_path(File.join(Gem.loaded_specs.fetch("actionview").full_gem_path, "app/assets/javascripts"))
    js = javascript.find_asset("thredded.js") || raise("Could not compile Thredded JavaScript")

    # Build both bundles before replacing the previous outputs.
    destination.join("thredded.css").write(css)
    destination.join("thredded.js").write(js.to_s)
    FileUtils.cp_r(source.join("app/assets/images/thredded"), destination)
    FileUtils.cp_r(source.join("app/assets/images/favicons"), destination)
  end
end
