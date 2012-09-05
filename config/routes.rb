CatarseMoip::Engine.routes.draw do
  namespace :payment do

    resources :moip, only: [] do
      collection do
        post 'notifications' => "history#create"
      end
      member do
        match :pay
      end
    end
  end
end
