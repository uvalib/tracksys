Tracksys::Application.routes.draw do
  root :to => 'requests#index'

  match '/request' => redirect('/')

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
end
