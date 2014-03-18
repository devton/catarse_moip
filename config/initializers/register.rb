begin
  PaymentEngines.register(CatarseMoip::PaymentEngine.new)
rescue Exception => e
  puts "Error while registering payment engine: #{e}"
end
