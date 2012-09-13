CatarseMoip::Engine.routes.draw do
  namespace :payment do
    resources :moip, only: [] do
      collection do
        post 'notifications' => "history#create"
      end
      member do
        match :review
        match :pay
        match :get_moip_token
      end
    end
  end
end
