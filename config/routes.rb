GdriveFeed::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  resources :monitored_resources do
    get 'create'

    member do
      get 'index_structure'
      get 'index_changehistory'
      get 'missing_revisions'
    end

    resources :permissions do
      collection do
        get 'refresh'
      end
    end

    resources :permission_groups
    resources :resources do
      member do
        get 'refresh_revisions'
        get 'download_revisions'
        get 'calculate_diffs'
      end
    end
    resources :reports
  end

  resources :monitored_periods

  get "welcome/index"
  get "meta/mime_types", to: "welcome#mime_types"

  root :to => "welcome#index"

  match "/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
