Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check


  get "/albums(_sort_by_:sort)", to: "albums#index", as: :albums
  resources :albums, except: :index do
    member do
      get :expire
      get :thumbs_up
      get :two_thumbs_up
      post :social_update
      post :create_comment
      get :photos
    end

    collection do
      get :expire
    end
  end

  get "/places(_sort_by_:sort)", to: "places#index", as: :places
  resources :places, except: :index do
    member do
      get :expire
      get :expire_desc
      get :infowindow
      get :photos
    end

    collection do
      get :expire
      get :place_search
    end
  end

  # Routes for each Place subclass
  place_subclasses = %w[
    Beach Campground Cave Glacier Hut Icefield Island Lake
    Meadow Mine Mountain MountainRange Park Pass RangerStation
    Region Springs Town Valley Waterfall
  ]

  place_subclasses.each do |subclass|
    table_name = subclass.tableize
    get "#{table_name}(_sort_by_:sort)", to: "places#index", as: table_name, defaults: { type: subclass }
    get "/places/:place_id/#{table_name}(_sort_by_:sort)", to: "places#index", as: "place_#{table_name}", defaults: { type: subclass }
  end

  # Redirect old feature and area urls to the new places urls.
  get "/areas", to: redirect("/places")
  get "/areas/:name", to: redirect("/places/%{name}")
  get "/features", to: redirect("/places")
  get "/features/:name", to: redirect("/places/%{name}")

  post "comments/:article_type/:id", to: "articles#create_comment", as: :comments

  get "/ip_addresses(_sort_by_:sort)", to: "ip_addresses#index", as: :ip_addresses
  resources :ip_addresses, except: :index

  get "main/index", to: "main#index"
  get "/expire", to: "main#expire_index"
  get "/updated", to: "main#updated"
  get "/listing", to: "main#listing"
  get "/terms", to: "main#terms"
  get "/disclaimer", to: "main#disclaimer"
  get "/contributions", to: "main#contributions"
  get "/gmap", to: "main#gmap"
  get "/expire_gmap", to: "main#expire_gmap"
  get "/search", to: "main#search"

  post "markitup/preview", to: "markitup#preview"

  get "/people(_sort_by_:sort)", to: "people#index", as: :people
  resources :people, except: :index do
    member do
      get :expire
    end

    collection do
      get :expire
    end
  end

  get "/photos(_sort_by_:sort)", to: "photos#index", as: :photos
  resources :photos, except: :index do
    member do
      get :expire
      get :thumbs_up
      get :two_thumbs_up
      post :social_update
      post :create_comment
    end

    collection do
      get :expire
      get :show_full
      get :slideshow
      get :nearby_list
      post :xhr_create
      get :edit
      get :editable_list
      get :thumb_edit_kill
      post :thumb_update
    end
  end

  get "/routes(_sort_by_:sort)", to: "routes#index", as: :routes
  resources :routes, except: :index do
    member do
      get :dup
      get :expire
      get :expire_desc
      get :photos
    end

    collection do
      get :expire
    end
  end

  # Routes for each Route subclass
  route_subclasses = %w[
    ApproachRoute HikingRoute IceRoute MountaineeringRoute
    River Road RockRoute Scramble Trail
  ]

  route_subclasses.each do |subclass|
    table_name = subclass.tableize
    get "/places/:place_id/#{table_name}(_sort_by_:sort)", to: "routes#index", as: "place_#{table_name}", defaults: { type: subclass }
    get "#{table_name}(_sort_by_:sort)", to: "routes#index", as: table_name, defaults: { type: subclass }
  end

  # Sidekiq monitor
  if defined?(Sidekiq::Web)
    authenticate :user do
      mount Sidekiq::Web, at: "/sidekiq"
    end
  end


  get "/trip_reports(_sort_by_:sort)", to: "trip_reports#index", as: :trip_reports
  resources :trip_reports, except: :index do
    member do
      get :expire
      get :expire_desc
      get :multi_photos
      get :thumbs_up
      get :two_thumbs_up
      post :social_update
      post :create_comment
      get :photos
    end

    collection do
      get :expire
    end
  end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    passwords: "users/passwords",
    unlocks: "users/unlocks"
  }
  get "/users/sign_out", to: "devise/sessions#destroy"

  # Route list for each user for each subclass
  route_subclasses.each do |subclass|
    table_name = subclass.tableize
    get "/users/:user_id/#{table_name}(_sort_by_:sort)", to: "routes#index", as: "user_#{table_name}", defaults: { type: subclass }
  end

  get "/users(_sort_by_:sort)", to: "users#index", as: :users
  resources :users, except: :index do
    member do
      get :expire
      get :statistics
      get :photos
      get :make_editor
      get :make_admin
      get :demote
    end

    collection do
      get :expire
      get :admin_index
    end
  end

  mount Markitup::Rails::Engine, at: "/markitup", as: "markitup" if defined?(Markitup::Rails::Engine)

  if defined?(Forem::Engine)
    get "fanaticsforum/search", to: "forem/forums#search", as: :forem_search
    get "fanaticsforum/unanswered", to: "forem/forums#unanswered", as: :forem_unanswered
    get "fanaticsforum/active_topics", to: "forem/forums#active_topics", as: :forem_active_topics
    get "fanaticsforum/list_topics", to: "forem/forums#list_topics", as: :forem_list_topics
    get "fanaticsforum/forums/:forum_id/topics/:id/set_place_id", to: "forem/topics#set_place_id", as: :forem_topics_set_place_id

    mount Forem::Engine, at: "/fanaticsforum"
  end

  # These shortcuts are low priority so they must come last.
  get "/:id", to: "places#show", as: :places_show
  put "/:id", to: "places#update", as: :places_update
  get "/:id/expire", to: "places#expire", as: :places_expire
  get "/:id/expire_desc", to: "places#expire_desc", as: :places_expire_desc

  root to: "main#index"
end
