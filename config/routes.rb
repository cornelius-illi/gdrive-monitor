GdriveFeed::Application.routes.draw do
  get "monitored_resources", to: "monitored_resources#list", as: :monitored_resources
  get "monitored_resources/new"
  get "monitored_resources/:gid/create", to: "monitored_resources#create", as: :mr_create
  get "monitored_resources/:id", to: "monitored_resources#show", as: :monitored_resource
  get "monitored_resources/:id/index_structure", to: "monitored_resources#index_structure", as: :mr_index_structure
  get "monitored_resources/:id/index_changehistory", to: "monitored_resources#index_changehistory", as: :mr_index_changehistory
  get "monitored_resources/:id/permissions", to: "monitored_resources#permissions", as: :mr_permissions
  get "monitored_resources/:id/permissions/refresh", to: "monitored_resources#refresh_permissions", as: :mr_refresh_permissions
  get "monitored_resources/:id/reports", to: "monitored_resources#reports",as: :mr_reports
  
  get "welcome/index"
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  
  resources :permission_groups
  resources :monitored_periods
  
  root :to => "welcome#index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

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
