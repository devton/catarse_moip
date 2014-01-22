begin
  PaymentEngines.register({name: 'moip', review_path: ->(contribution){ CatarseMoip::Engine.routes.url_helpers.review_moip_path(contribution) }, locale: 'pt'})
rescue Exception => e
  puts "Error while registering payment engine: #{e}"
end
