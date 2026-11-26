require "test_helper"

class SearchIndexingTest < ActionDispatch::IntegrationTest
  test "robots advertises a sitemap with canonical public URLs" do
    origin = Rails.configuration.x.site_origin
    get "/robots.txt"
    assert_response :success
    assert_includes response.body, "Sitemap: #{origin}/sitemap.xml"

    get "/sitemap.xml.gz"
    assert_redirected_to "/sitemap.xml"

    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    index = Nokogiri::XML(response.body).remove_namespaces!
    assert_includes index.xpath("/sitemapindex/sitemap/loc").map(&:text), "#{origin}/sitemap-pages.xml"

    get "/sitemap-pages.xml"
    assert_response :success
    pages = Nokogiri::XML(response.body).remove_namespaces!
    assert_includes pages.xpath("/urlset/url/loc").map(&:text), "#{origin}/"

    place = Place.first!
    get sitemap_batch_path("places", place.id / SitemapsController::BATCH_SIZE)
    assert_response :success
    places = Nokogiri::XML(response.body).remove_namespaces!
    assert_includes places.xpath("/urlset/url/loc").map(&:text), "#{origin}#{place_path(place)}"
  end

  test "the homepage and main directories can be indexed" do
    origin = Rails.configuration.x.site_origin
    [root_path, "/main/index", places_path, routes_path, trip_reports_path, albums_path, photos_path].each do |path|
      get path
      assert_response :success
      canonical_path = path == "/main/index" ? root_path : path
      assert_select 'link[rel="canonical"][href=?]', "#{origin}#{canonical_path}", count: 1
      assert_select 'meta[name="robots"][content*="noindex"]', count: 0
    end

    get places_path(page: 2)
    assert_response :success
    assert_select 'meta[name="robots"][content*="noindex"]', count: 1
  end
end
