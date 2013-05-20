CatarseMoip::Engine.routes.draw do
  resources :moip, only: [], path: 'payment/moip' do
    collection do
      post 'notifications' => "moip#create_notification"
      get 'js'
    end
    member do
      match :moip_response
      match :review
      match :get_moip_token
    end
  end
end
