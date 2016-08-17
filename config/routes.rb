Tracksys::Application.routes.draw do
  root :to => 'requests#index'
  get "request" => 'requests#index'

  resources :requests do
    collection do
      get 'agree_to_copyright'
      get 'details'
      get 'public'
      get 'thank_you'
      get 'uva'
    end
  end
  ActiveAdmin.routes(self)

  namespace :api do
     get "metadata/:pid" => "metadata#show"
     get "pid/:pid" => "pid#show"
     get "solr/:pid" => "solr#show"
     get "style/:id" => "style#show"
     get "solr" => "solr#index"
  end
end
