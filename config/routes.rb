Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :photos do
    collection do
      get :nearby_list
      get :slideshow
      get :show_full
      get :editable_list
      post :xhr_create
    end
    member do
      get :expire
      post :thumb_update
    end
  end

  resources :people do
    member do
      get :expire
    end
  end

  resources :places
  resources :mountains
  resources :routes

  resources :trip_reports do
    collection do
      get :multi_photos
    end
    member do
      get :expire
      get :expire_desc
      get :photos
    end
  end
end
