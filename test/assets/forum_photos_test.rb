ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "capybara/minitest"
require "selenium-webdriver"
require "base64"

class ForumPhotoPickerSmokeController < ActionController::Base
  def show
    @topic = Struct.new(:id, :messageboard_id, :place).new(nil, 7, nil)
    render inline: <<~HTML
      <meta name="csrf-token" content="browser-test-token">
      <%= form_with url: "/submit" do |form| %>
        <%= form.text_area :content, id: "picker_content" %>
        <%= render "forum_photos/picker", topic: @topic, textarea_id: "picker_content" %>
      <% end %>
    HTML
  end
end

class ForumPhotosBrowserTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  PIXEL = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=".freeze

  def setup
    @previous_app = Capybara.app
    @previous_driver = Capybara.current_driver
    Capybara.register_driver :forum_photos_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_option("goog:loggingPrefs", browser: "ALL")
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.current_driver = :forum_photos_chrome
    @requests = []
    requests = @requests
    endpoint = lambda do |env|
      request = Rack::Request.new(env)
      requests << { method: request.request_method, params: request.params, csrf: env["HTTP_X_CSRF_TOKEN"] }
      if request.path.end_with?("/places")
        data = [ { id: 70, name: "Mountain" } ]
      elsif request.post?
        data = { id: 101, title: "Uploaded mountain" }
      else
        data = { photos: [ { id: 100, title: "Existing mountain", thumbnail: "data:image/png;base64,#{PIXEL}" } ], more: false }
      end
      [ 200, { "content-type" => "application/json" }, [ JSON.generate(data) ] ]
    end
    assets = Rails.application.assets.server
    Capybara.app = Rack::Builder.new do
      map("/assets") { run assets }
      map("/forum_photos") { run endpoint }
      map("/") { run ForumPhotoPickerSmokeController.action(:show) }
    end
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.app = @previous_app
    Capybara.current_driver = @previous_driver
    @upload&.close!
  end

  def test_selecting_and_uploading_photos_inserts_tokens_and_submission_ids
    visit "/"
    find("summary", text: "Add photos").click
    find("[data-photo-search]").set("mountain")
    find("[data-photo-search]").send_keys(:enter)
    click_button "Existing mountain"
    assert_includes find("#picker_content").value, "[[photo=100]]"
    assert_selector 'input[name="forum_photo_ids[]"][value="100"]', visible: :all
    assert_equal "7", @requests.first[:params]["messageboard_id"]

    find("[data-place-search]").set("Moun")
    click_button "Find places"
    find("[data-photo-place]").select("Mountain")
    @upload = Tempfile.new([ "forum-browser-photo", ".png" ])
    @upload.binmode
    @upload.write(Base64.decode64(PIXEL))
    @upload.flush
    find("[data-photo-files]").attach_file(@upload.path)
    click_button "Upload and add photos"
    assert_selector "[data-photo-status]", text: "Added Uploaded mountain."
    assert_includes find("#picker_content").value, "[[photo=101]]"
    assert_selector 'input[name="forum_photo_ids[]"][value="101"]', visible: :all
    upload = @requests.find { |request| request[:method] == "POST" }
    assert_equal "70", upload[:params]["place_id"]
    assert_equal "7", upload[:params]["messageboard_id"]
    assert upload[:params]["file"]
    assert upload[:csrf].present?
    errors = page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    assert_empty errors, errors.map(&:message).join("\n")
  end
end
