Tracksys::Application.routes.draw do
  root :to => 'requests#index'
  get "request" => 'requests#index'

  resources :requests do
    collection do
      get 'agree_to_copyright'
      get 'details'
      get 'thank_you'
      get 'uva'
    end
  end
  ActiveAdmin.routes(self)

  namespace :api do
     get "sirsi/:id" => "sirsi#show"
     get "metadata/:pid" => "metadata#show"
     get "fulltext/:pid" => "fulltext#show"
     get "pid/:pid" => "pid#show"
     get "solr/:pid" => "solr#show"
     get "solr" => "solr#index"
     get "published" => "solr#published"
     post "xml/validate" => "xml#validate"
     post "xml/generate" => "xml#generate"
     get "stylesheet/:id" => "stylesheet#show"
  end
end
