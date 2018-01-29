# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://www.summitsearch.org"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  Place.find_each do |place|
    add place_path(place), :lastmod => place.updated_at, :changefreq => 'monthly', :priority => place.sitemap_priority
  end

  Route.find_each do |route|
    add route_path(route), :lastmod => route.updated_at, :changefreq => 'monthly'
  end

  TripReport.find_each do |trip|
    add trip_report_path(trip), :lastmod => trip.updated_at, :changefreq => 'monthly', :priority => 0.7
  end

  User.find_each do |user|
    add user_path(user), :lastmod => user.updated_at, :changefreq => 'monthly'
  end

  Photo.find_each do |photo|
    add photo_path(photo), :lastmod => photo.updated_at, :changefreq => 'monthly'
  end

  Person.find_each do |person|
    add person_path(person), :lastmod => person.updated_at, :changefreq => 'yearly'
  end

end
