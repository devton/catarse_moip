begin
  PaymentEngines.register({name: 'moip', review_path: ->(backer){ CatarseMoip::Engine.routes.url_helpers.review_moip_path(backer) }, locale: 'pt'})
rescue Exception => e
  puts "Error while registering payment engine: #{e}"
end
