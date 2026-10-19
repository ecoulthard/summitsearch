ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "capybara/minitest"
require "selenium-webdriver"

class PlaceBorderPointSmokeController < ActionController::Base
  helper PlacesHelper

  def show
    lookup_context.prefixes.unshift("places")
    @place = Place.new
    render inline: <<~HTML
      <script src="/jquery.js"></script>
      <%= javascript_include_tag "application" %>
      <%= form_with model: @place do |f| %>
        <input id="Latitude"><input id="Longitude">
        <button type="button" id="btnAddPoint">Add Point</button>
        <script>
          // Keep the real form and add-point code; substitute external map drawing.
          window.BorderPoint = class {
            constructor(id, latitude, longitude) {
              this.latLon = {latitude, longitude};
              this.marker = {setIcon() {}};
            }
          };
          window.google = {maps: {Polyline: class {setMap() {}}}};
          $('#btnAddPoint').click(function() {
            window.Place.addNewBorderPoint(this, 'border_points', '<%= border_point_fields(f) %>');
          });
        </script>
      <% end %>
    HTML
  end
end

class PlaceBorderPointsBrowserTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    @previous_app = Capybara.app
    @previous_driver = Capybara.current_driver
    Capybara.register_driver :place_border_points_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.current_driver = :place_border_points_chrome
    assets = Rails.application.assets.server
    Capybara.app = lambda do |env|
      next assets.call(env.merge("PATH_INFO" => env["PATH_INFO"].delete_prefix("/assets"))) if env["PATH_INFO"].start_with?("/assets/")
      path = case env["PATH_INFO"]
             when "/jquery.js" then File.join(Gem.loaded_specs.fetch("capybara").full_gem_path, "lib/capybara/spec/public/jquery.js")
             end
      if path
        [200, { "content-type" => "text/javascript" }, [File.read(path)]]
      else
        PlaceBorderPointSmokeController.action(:show).call(env)
      end
    end
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.app = @previous_app
    Capybara.current_driver = @previous_driver
  end

  def test_added_border_points_include_coordinates_and_indices_in_submitted_form
    visit "/place"
    3.times do |index|
      fill_in "Latitude", with: (52.0 + index * 0.01).to_s
      fill_in "Longitude", with: "-117"
      click_button "Add Point"
    end
    data = page.evaluate_script("Object.fromEntries(new FormData(document.querySelector('form')))")
    3.times do |index|
      prefix = "place[border_points_attributes][#{index}]"
      assert_equal (52.0 + index * 0.01), data.fetch("#{prefix}[latitude]").to_f
      assert_equal "-117", data.fetch("#{prefix}[longitude]")
      assert_equal index.to_s, data.fetch("#{prefix}[local_index]")
    end
  end
end
