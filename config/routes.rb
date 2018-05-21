Tracksys::Application.routes.draw do
  root :to => 'requests#index'
  get "request" => 'requests#index'

  resources :requests do
    collection do
      get 'agree_to_copyright'
      get 'details'
      get 'thank_you'
      get 'uva'
      post 'customer' => "requests#customer_update"
      get 'address' => "requests#address_step"
      post 'address' => "requests#address_update"
      get 'request' => "requests#request_step"
      post 'review' => "requests#review_step"
      post 'add_item' => "requests#add_item"
      post 'submit' => "requests#submit"
    end
  end
  ActiveAdmin.routes(self)

  # See notes inside... had to do some workarounds to get routes/controlers
  # working as needed within the ActiveAdmin bounds. A bit ugly, but oh well.
  namespace :admin do
     # There is no activeAdmin workstation resource page defined. The
     # functionality is blended into a general equipment page. The JS
     # for this page calls create, update and destroy endpoints on a
     # workstation object. Created a separate (normal) rails controller
     # to handle these requests. Routes registerd here
     resources :workstations, only: [:create, :update, :destroy]
     delete "workstations/:id/equipment" => "workstations#clear_equipment"
     delete "items/:id" => "items#destroy"
     post "items/convert" => "items#convert"
     post "items/metadata" => "items#create_metadata"

     # Weird. The file /admin/equipment is made with register_page so it
     # has none of the basic CRUD actions defined automatically. Add them
     # here manually
     resources :equipment, only: [:destroy, :create, :update]
  end

  namespace :api do
     get "sirsi/:id" => "sirsi#show"
     get "metadata/search" => "metadata#search"
     get "metadata/:pid" => "metadata#show"
     get "fulltext/:pid" => "fulltext#show"
     get "pid/:pid" => "pid#show"
     get "pid/:pid/type" => "pid#identify"
     get "solr/:pid" => "solr#show"
     get "solr" => "solr#index"
     get "published" => "solr#published"
     post "xml/validate" => "xml#validate"
     post "xml/generate" => "xml#generate"
     get "stylesheet/:id" => "stylesheet#show"
     get "reports" => "reports#generate"
     post "qdc/:id" => "qdc#generate"
     get "manifest/:pid" => "manifest#show"
  end
end
