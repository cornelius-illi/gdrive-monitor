GdriveFeed::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  # @todo: use :only => [:show, :...] in resources to be able to override create method
  get 'monitored_resources/create_with/:gid', :to => 'monitored_resources#create_with', :as => 'create_with'

  get 'calculate_threshold', :to => 'resources#calculate_threshold', :as => 'calculate_threshold'
  get 'calculate_optimal_threshold', :to => 'resources#calculate_optimal_threshold', :as => 'calculate_optimal_threshold'
  get 'show_threshold', :to => 'resources#show_threshold', :as => 'show_threshold'

  resources :monitored_resources do
    member do
      get 'index_structure'
      get 'combine_revisions'
      get 'index_changehistory'
      get 'missing_revisions'
      get 'download_revisions'
      #get 'reports'
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
        get 'merge_revisions'
        get 'find_collaborations'
        get 'merged_revisions/:rev_id', :action => :merged_revisions, :as => 'merged_revisions'
      end
    end
    resources :reports do
      collection do
        get 'generate'
        get 'remove'
      end
    end
  end

  get 'reports/metareport', to: 'reports#metareport', :as => 'reports_metareport'
  get 'reports/generate_metareport', to: 'reports#generate_metareport', :as => 'reports_generate_metareport'

  resources :monitored_periods
  resources :period_groups

  root :to => "application#welcome"

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
