module CatarseMoip
  class Engine < ::Rails::Engine
    isolate_namespace CatarseMoip
    initializer "pandemic.asset_addition", :group => :all do |app|
      # Enabling assets precompiling under rails 3.1
      if Rails.version >= '3.1'
        app.config.assets.precompile += %w( catarse_moip.js )
      end
    end
  
  end
end
