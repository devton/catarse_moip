::MoIP.setup do |config|
  config.uri = (PaymentEngines.configuration[:moip_uri] rescue nil) || ''
  config.token = (PaymentEngines.configuration[:moip_token] rescue nil) || ''
  config.key = (PaymentEngines.configuration[:moip_key] rescue nil) || ''
end
