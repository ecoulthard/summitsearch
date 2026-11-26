require "builder"


class SitemapsController < ActionController::Base
  NAMESPACE = "http://www.sitemaps.org/schemas/sitemap/0.9"
  BATCH_SIZE = 10_000
  COLLECTIONS = {
    "places" => [Place, :place_path],
    "routes" => [Route, :route_path],
    "trip_reports" => [TripReport, :trip_report_path],
    "albums" => [Album, :album_path],
    "photos" => [Photo, :photo_path],
    "people" => [Person, :person_path],
    "users" => [User, :user_path]
  }.freeze

  def index
    render_sitemap(:sitemapindex) do |xml|
      xml.sitemap { xml.loc absolute_url(sitemap_pages_path) }
      COLLECTIONS.each_key do |collection|
        # PostgreSQL integer division groups IDs into stable, bounded ranges.
        records_for(collection).distinct.pluck(Arel.sql("id / #{BATCH_SIZE}")).sort.each do |batch|
          xml.sitemap { xml.loc absolute_url(sitemap_batch_path(collection, batch)) }
        end
      end
    end
  end

  def pages
    render_sitemap(:urlset) do |xml|
      [root_path, places_path, routes_path, trip_reports_path, albums_path, photos_path].each do |path|
        xml.url { xml.loc absolute_url(path) }
      end
    end
  end

  def show
    collection = params[:collection]
    return head :not_found unless COLLECTIONS.key?(collection)

    first_id = params[:batch].to_i * BATCH_SIZE
    records = records_for(collection).where(id: first_id...(first_id + BATCH_SIZE))
    return head :not_found unless records.exists?

    render_sitemap(:urlset) do |xml|
      path_helper = COLLECTIONS.fetch(collection).last
      records.find_each do |record|
        xml.url do
          xml.loc absolute_url(public_send(path_helper, record))
          xml.lastmod record.updated_at.utc.iso8601 if record.updated_at
        end
      end
    end
  end

  private

  def records_for(collection)
    model = COLLECTIONS.fetch(collection).first
    records = model.reorder(nil)
    collection == "albums" ? records.where(deleted: [nil, false]) : records
  end

  def absolute_url(path)
    "#{Rails.configuration.x.site_origin}#{path}"
  end

  def render_sitemap(root)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!(root, xmlns: NAMESPACE) { yield xml }
    expires_in 1.hour, public: true
    render xml: xml.target!
  end
end
