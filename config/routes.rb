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
     get "metadata/search" => "metadata#search"
     get "fulltext/:pid" => "fulltext#show"
     post "fulltext/:pid/ocr" => "fulltext#post_ocr"
     post "xml/validate" => "xml#validate"
     post "xml/generate" => "xml#generate"
     get "reports" => "reports#generate"
     post "callbacks/:jid/ocr" => "callbacks#ocr"
     post "callbacks/:jid/synchronous_ocr" => "callbacks#synchronous_ocr"

  end
end
