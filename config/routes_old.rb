require 'sidekiq/web'
Summitsearch::Application.routes.draw do 
  
  resources :ascents

  get "/albums(_sort_by_:sort)" => "albums#index", :as => "albums"
  resources :albums, except: :index do
    get :expire, :on => :member
    get :expire, :on => :collection
    get :thumbs_up, :on => :member
    get :two_thumbs_up, :on => :member
    post :social_update, :on => :member
    post :create_comment, :on => :member
    get :photos, :on => :member
  end

  get "/places(_sort_by_:sort)" => "places#index", :as => "places"
  resources :places, except: :index do
    get :expire, :on => :member
    get :expire, :on => :collection
    get :expire_desc, :on => :member
    get :place_search, :on => :collection
    get :infowindow, :on => :member
    get :photos, :on => :member
  end

  #Add a route for each Place subclass
  Place.subclasses.each do |subclass|
    get "#{subclass.to_s.tableize}(_sort_by_:sort)" => "places#index", :as => subclass.to_s.tableize, :type => subclass.to_s.camelize
  end

  #Add a place list for each area for each place subclass
  Place.subclasses.each do |subclass|
    get "/places/:place_id/#{subclass.to_s.tableize}(_sort_by_:sort)" => "places#index", :as => "place_#{subclass.to_s.tableize}", :type => subclass.to_s.camelize
  end

  #Redirect old feature and area urls to the new places urls.
  get '/areas', to: redirect('/places') 
  get '/areas/:name', to: redirect('/places/%{name}')
  get '/features', to: redirect('/places') 
  get '/features/:name', to: redirect('/places/%{name}')

  post 'comments/:article_type/:id' => 'articles#create_comment', :as => 'comments'
 

  get "/ip_addresses(_sort_by_:sort)" => "ip_addresses#index", :as => "ip_addresses"
  resources :ip_addresses, except: :index

  get "main/index"
  get "/expire" => "main#expire_index"
  get "/updated" => "main#updated"
  get "/listing" => "main#listing"
  get "/terms" => "main#terms"
  get "/disclaimer" => "main#disclaimer"
  get "/contributions" => "main#contributions"
  get "/gmap" => "main#gmap"
  get "/expire_gmap" => "main#expire_gmap"
  get "/search" => "main#search"


  post "markitup/preview" => "markitup#preview"

  get "/people(_sort_by_:sort)" => "people#index", :as => "people"
  resources :people, except: :index do
    get :expire, :on => :member
    get :expire, :on => :collection
  end

  get "/photos(_sort_by_:sort)" => "photos#index", :as => "photos"
  resources :photos, except: :index do
    get :expire, :on => :member
    get :expire, :on => :collection
    get :show_full, :on => :collection
    get :slideshow, :on => :collection
    get :nearby_list, :on => :collection
    post :xhr_create, :on => :collection #Need to define this on collection otherwise forem wont let us call it.
    get :edit, :on => :collection #Need to define this on collection otherwise forem wont let us call it.
    get :editable_list, :on => :collection
    get :thumb_edit_kill, :on => :collection #Need to define this on collection otherwise forem wont let us call it.
    post :thumb_update, :on => :collection #Need to define this on collection otherwise forem wont let us call it.
    get :thumbs_up, :on => :member
    get :two_thumbs_up, :on => :member
    post :social_update, :on => :member
    post :create_comment, :on => :member
  end

  get "/routes(_sort_by_:sort)" => "routes#index", :as => "routes"
  resources :routes, except: :index do
    get :dup, :on => :member
    get :expire, :on => :member
    get :expire, :on => :collection
    get :expire_desc, :on => :member
    get :photos, :on => :member
  end

  #Add a route list for each area for each route subclass
  Route.subclasses.each do |subclass|
    get "/places/:place_id/#{subclass.to_s.tableize}(_sort_by_:sort)" => "routes#index", :as => "place_#{subclass.to_s.tableize}", :type => subclass.to_s.camelize
  end

  #Add a route for each Route subclass
  Route.subclasses.each do |subclass|
    get "#{subclass.to_s.tableize}(_sort_by_:sort)" => "routes#index", :as => subclass.to_s.tableize, :type => subclass.to_s.camelize
  end

  #Sidekiq monitor
  authenticate :user do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  get "/transfer/login_new"
  post "/transfer/login_create"
  get "/transfer/photos_index"

  get "/trip_reports(_sort_by_:sort)" => "trip_reports#index", :as => "trip_reports"
  resources :trip_reports, except: :index do
    get :expire, :on => :member
    get :expire, :on => :collection
    get :expire_desc, :on => :member
    get :multi_photos, :on => :member
    get :thumbs_up, :on => :member
    get :two_thumbs_up, :on => :member
    post :social_update, :on => :member
    post :create_comment, :on => :member
    get :photos, :on => :member
  end

  devise_for :users, :controllers => { :sessions => "users/sessions",
	  :registrations => "users/registrations",:confirmations => "users/confirmations",
	  :passwords => "users/passwords", :unlocks => "users/unlocks"}
  get '/users/sign_out' => 'devise/sessions#destroy'
	  
  #Add a route list for each user for each subclass
  Route.subclasses.each do |subclass|
    get "/users/:user_id/#{subclass.to_s.tableize}(_sort_by_:sort)" => "routes#index", :as => "user_#{subclass.to_s.tableize}", :type => subclass.to_s.camelize
  end

  get "/users(_sort_by_:sort)" => "users#index", :as => "users"
  resources :users, except: :index do
    get :expire, :on => :member
    get :expire, :on => :collection
    get :statistics, :on => :member
    get :photos, :on => :member
    get :admin_index, :on => :collection
    get :make_editor, :on => :member
    get :make_admin, :on => :member
    get :demote, :on => :member
  end

  mount Markitup::Rails::Engine, at: "markitup", as: "markitup"

  get "fanaticsforum/search" => "forem/forums#search", :as => "forem_search"
  get "fanaticsforum/unanswered" => "forem/forums#unanswered", :as => "forem_unanswered"
  get "fanaticsforum/active_topics" => "forem/forums#active_topics", :as => "forem_active_topics"
  get "fanaticsforum/list_topics" => "forem/forums#list_topics", :as => "forem_list_topics"
  get "fanaticsforum/forums/:forum_id/topics/:id/set_place_id" => "forem/topics#set_place_id", :as => "forem_topics_set_place_id"

  mount Forem::Engine, :at => "/fanaticsforum"

  #These shortcuts are low priority so they must come last.
  get "/:id" => "places#show", :as => "places_show"
  put "/:id" => "places#update", :as => "places_update"
  get "/:id/expire" => "places#expire", :as => "places_expire"
  get "/:id/expire_desc" => "places#expire_desc", :as => "places_expire_desc"

  root :to => 'main#index'
end
