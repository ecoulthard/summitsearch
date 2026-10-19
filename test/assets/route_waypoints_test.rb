ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "capybara/minitest"
require "selenium-webdriver"

class RouteWaypointSmokeController < ActionController::Base
  helper RoutesHelper
  def show
    lookup_context.prefixes.unshift("routes")
    @route = Route.new
    render inline: <<~HTML
      <script src="/jquery.js"></script>
      <%= javascript_include_tag "application" %>
      <%= form_with model: @route do |f| %>
        <input id="Latitude"><input id="Longitude">
        <button type="button" id="btnAddWaypoint">Add Waypoint</button>
        <script>
          // Maps rendering is external; exercise the real click and form field code.
          window.Waypoint = class {
            constructor(id, parent, title, latitude, longitude) {
              Object.assign(this, {id, parent_index: parent, latitude, longitude});
            }
          };
          window.Route.computeDistances = function() {};
          window.Route.coordinatesTooFarAway = function() { return false; };
          window.map = {getZoom: () => 12};
          $('#btnAddWaypoint').click(function() {
            window.Route.addNewWaypoint(this, 'waypoints', '<%= waypoint_fields(f) %>', '');
          });
        </script>
      <% end %>
    HTML
  end
end

class RouteWaypointsBrowserTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    @previous_app = Capybara.app
    @previous_driver = Capybara.current_driver
    Capybara.register_driver :route_waypoints_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.current_driver = :route_waypoints_chrome
    assets = Rails.application.assets.server
    Capybara.app = lambda do |env|
      next assets.call(env.merge("PATH_INFO" => env["PATH_INFO"].delete_prefix("/assets"))) if env["PATH_INFO"].start_with?("/assets/")
      path = case env["PATH_INFO"]
             when "/jquery.js" then File.join(Gem.loaded_specs.fetch("capybara").full_gem_path, "lib/capybara/spec/public/jquery.js")
             end
      if path
        [200, { "content-type" => "text/javascript" }, [File.read(path)]]
      else
        RouteWaypointSmokeController.action(:show).call(env)
      end
    end
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.app = @previous_app
    Capybara.current_driver = @previous_driver
  end

  def test_map_clicks_include_coordinates_and_indices_in_submitted_form
    visit "/"
    3.times do |index|
      page.execute_script(<<~JS)
        window.Route.mapClicked({latLng: {
          lat: () => #{52.0 + index * 0.01}, lng: () => -117.0
        }});
      JS
    end
    data = page.evaluate_script("Object.fromEntries(new FormData(document.querySelector('form')))")
    3.times do |index|
      prefix = "route[waypoints_attributes][#{index}]"
      assert_equal (52.0 + index * 0.01), data.fetch("#{prefix}[latitude]").to_f
      assert_equal "-117", data.fetch("#{prefix}[longitude]")
      assert_equal index.to_s, data.fetch("#{prefix}[local_index]")
      assert_equal (index - 1).to_s, data.fetch("#{prefix}[parent_index]")
    end
  end
end
