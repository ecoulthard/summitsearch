# This smoke test deliberately avoids test_helper and fixtures: step 1 must
# work before any Thredded tables exist. Run with bundle exec ruby this_file.
ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/application"
if ENV["FORUM_ASSETS_OUTPUT_PATH"]
  Rails.application.config.assets.output_path = Pathname.new(ENV.fetch("FORUM_ASSETS_OUTPUT_PATH"))
end
Rails.application.initialize! unless Rails.application.initialized?

require "minitest/autorun"
require "capybara/minitest"
require "selenium-webdriver"

class ForumAssetsSmokeController < ActionController::Base
  # This isolated asset server deliberately has no authentication middleware.
  helper_method :user_signed_in?

  def user_signed_in?
    false
  end

  def show
    render inline: <<~HTML, layout: "thredded/application"
      <main class="thredded--main-container">
        <h1>Forum asset smoke test</h1>
        <p id="post_42">An existing post anchor</p>
        <form data-thredded-post-form data-autocomplete-min-length="2">
          <label for="content">Comment</label>
          <textarea id="content" name="post[content]"></textarea>
        </form>
        <div class="thredded--post--content--spoiler" aria-expanded="false">
          <span>Show spoiler</span><span aria-hidden="true">Hidden content</span>
        </div>
      </main>
    HTML
  end
end

class ForumAssetsTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    ForumAssets.build if Rails.env.test?
    @previous_app = Capybara.app
    @previous_driver = Capybara.current_driver
    Capybara.register_driver :forum_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--window-size=1200,900")
      options.add_option("goog:loggingPrefs", browser: "ALL")
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.current_driver = :forum_chrome
    assets = Rails.env.production? ? Rack::Files.new(Rails.application.config.assets.output_path) : Rails.application.assets.server
    Capybara.app = Rack::Builder.new do
      map "/assets" do
        run assets
      end
      map "/" do
        run ForumAssetsSmokeController.action(:show)
      end
    end
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.app = @previous_app
    Capybara.current_driver = @previous_driver
  end

  def test_legacy_post_fragments_resolve_through_permalink_only_when_off_page
    visit "/#post_42"
    assert_selector "#post_42"
    assert_equal "/", page.current_path
    visit "/#post_43"
    assert_current_path "/fanaticsforum/posts/43", ignore_query: true
    assert_selector "h1", text: "Forum asset smoke test"
  end

  def test_forum_layout_loads_styles_and_initializes_javascript
    visit "/"
    assert_selector "h1", text: "Forum asset smoke test"
    assert_selector 'body[data-turbo="false"]'
    assert_selector 'meta[name="turbo-visit-control"][content="reload"]', visible: :all
    refute page.evaluate_script("typeof window.Turbo !== 'undefined'")
    assert_equal "function", page.evaluate_script("typeof window.Thredded?.onPageLoad")
    assert_equal "function", page.evaluate_script("typeof window.Rails?.start")
    assert_equal "content-box", page.evaluate_script("getComputedStyle(document.querySelector('main')).boxSizing")

    assert_selector '.forum-banner img[alt*="Rocky Mountain Fanatics"]'
    assert page.evaluate_script("document.querySelector('.forum-banner img').naturalWidth > 0")
    assert_equal "rgb(46, 102, 182)", page.evaluate_script("getComputedStyle(document.querySelector('.forum-navigation')).backgroundColor")
    assert_includes page.evaluate_script("getComputedStyle(document.querySelector('main')).fontFamily"), "Verdana"
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "Forum layout overflows mobile viewport"
    assert_selector 'nav[aria-label="Forum navigation"] input[type="search"]'
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")

    # The autosize style and spoiler interaction prove DOMContentLoaded
    # handlers actually ran, beyond merely downloading the JS bundle.
    assert_selector 'textarea[style*="overflow"]'
    find(".thredded--post--content--spoiler").click
    assert_selector '.thredded--post--content--spoiler[aria-expanded="true"]'

    css_url = find('link[rel="stylesheet"][href*="/thredded-"]', visible: :all)[:href]
    css_response = page.driver.browser.execute_async_script(<<~JS, css_url)
      const done = arguments[arguments.length - 1];
      fetch(arguments[0]).then(async response => done({status: response.status, css: await response.text()}));
    JS
    assert_equal 200, css_response.fetch("status")
    refute_match(/image-url\(|asset-data-url\(|@import/, css_response.fetch("css"))
    assert_includes css_response.fetch("css"), "data:image/svg+xml;base64,"

    # Catch missing favicons/images, not just the bundles themselves.
    css_response.fetch("css").scan(/url\(["']?([^\)"']+)["']?\)/).flatten.uniq.each do |url|
      next if url.start_with?("data:")
      assert_match(%r{\A/assets/}, url)
      status = page.driver.browser.execute_async_script(<<~JS, url)
        const done = arguments[arguments.length - 1];
        fetch(arguments[0]).then(response => done(response.status));
      JS
      assert_equal 200, status, "Missing CSS image: #{url}"
    end
    errors = page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    assert_empty errors, errors.map(&:message).join("\n")
  end
end
