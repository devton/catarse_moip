CatarseMoip::Engine.routes.draw do
  namespace :payment do
    resources :moip, only: [] do
      member do
        match :checkout
      end
    end
  end
end
