ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "capybara/minitest"
require "selenium-webdriver"

class PlaceNestedFieldsSmokeController < ActionController::Base
  helper PlacesHelper

  def show
    lookup_context.prefixes.unshift("places")
    @place = Mountain.new
    render inline: <<~HTML
      <%= javascript_include_tag "nested_forms" %>
      <%= form_with model: @place, scope: :place do |f| %>
        <%= f.link_to_add "Add additional name information", :names, partial: "all/name_fields" %>
        <%= f.link_to_add "Add specific information about an ascent", :ascents, partial: "places/ascent_fields" %>
      <% end %>
    HTML
  end
end

class PlaceNestedFieldsBrowserTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    @previous_app = Capybara.app
    @previous_driver = Capybara.current_driver
    Capybara.register_driver :place_nested_fields_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.current_driver = :place_nested_fields_chrome
    assets = Rails.application.assets.server
    Capybara.app = lambda do |env|
      next assets.call(env.merge("PATH_INFO" => env["PATH_INFO"].delete_prefix("/assets"))) if env["PATH_INFO"].start_with?("/assets/")
      PlaceNestedFieldsSmokeController.action(:show).call(env)
    end
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.app = @previous_app
    Capybara.current_driver = @previous_driver
  end

  def test_names_ascents_and_participants_can_be_added_and_removed
    visit "/place"
    2.times { click_link "Add additional name information" }
    names = all(".nested_fields", text: "Name Info")
    assert_equal 2, names.length
    names.first.find('input[name$="[name]"]').set("Historic name")
    names.last.click_link "Remove this name information"
    assert_selector ".nested_fields", text: "Name Info", count: 1

    2.times { click_link "Add specific information about an ascent" }
    ascents = all(".nested_fields", text: "Historic Ascent Info")
    assert_equal 2, ascents.length
    ascents.each { |ascent| ascent.click_link "Add participant information" }
    assert_selector "legend", text: "Participant Info", count: 2
    ascents.first.click_link "Remove this participant"
    assert_selector "legend", text: "Participant Info", count: 1
    ascents.last.click_link "Remove this ascent information"
    assert_selector "legend", text: "Historic Ascent Info", count: 1

    data = page.evaluate_script("Array.from(new FormData(document.querySelector('form')).entries())")
    name_fields = data.select { |key, _| key.end_with?("[name]") }
    assert_equal 2, name_fields.map(&:first).uniq.length
    assert_equal "Historic name", name_fields.first.last
    assert_equal 3, data.count { |key, value| key.end_with?("[_destroy]") && value == "1" }
    participants = data.select { |key, _| key.include?("[ascent_people_attributes]") && key.end_with?("[person_id]") }
    assert_equal 2, participants.map(&:first).uniq.length
  end
end
