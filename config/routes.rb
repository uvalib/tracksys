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

     post "messages/:id/read" => "messages#read_meassge"
     delete "messages/:id" => "messages#destroy"
     post "messages" => "messages#create"

     # archivesSpace
     post "archivesspace/convert" => "archivesspace#convert"
     get "archivesspace" => "archivesspace#lookup"

     # Weird. The file /admin/equipment is made with register_page so it
     # has none of the basic CRUD actions defined automatically. Add them
     # here manually
     resources :equipment, only: [:destroy, :create, :update]
  end

  namespace :api do
     get "archivesspace/report" => "as#report"
     get "aries/:id" => "aries#show", :constraints => { :id => /[0-9A-Za-z:_\-\.\/]+/ }
     get "aries" => "aries#index"
     get "metadata/search" => "metadata#search"
     get "metadata/:pid" => "metadata#show"
     get "fulltext/:pid" => "fulltext#show"
     post "fulltext/:pid/ocr" => "fulltext#post_ocr"
     get "pid/:pid" => "pid#show"
     get "pid/:pid/type" => "pid#identify"
     get "pid/:pid/rights" => "pid#rights"
     post "xml/validate" => "xml#validate"
     post "xml/generate" => "xml#generate"
     get "stylesheet/:id" => "stylesheet#show"
     get "reports" => "reports#generate"
     put "aptrust/:id" => "ap_trust#resubmit"
     get "manifest/:pid" => "manifest#show"
     post "callbacks/:jid/ocr" => "callbacks#ocr"
     post "callbacks/:jid/synchronous_ocr" => "callbacks#synchronous_ocr"

     # Get a list of PIDs that have been flagged for DPLA publication
     get "dpla" => "dpla#published"

     # used by V4 tracksys-enrich
     get "sirsi/published" => "sirsi#published"
     get "other/published" => "other#published"
     get "other/:id" => "other#show"

     # Used by V3 and V4
     get "sirsi/:id" => "sirsi#show"
  end
end
