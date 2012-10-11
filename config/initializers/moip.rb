::MoIP.setup do |config|
  if ::Configuration[:moip_uri]
    config.uri = ::Configuration[:moip_uri]
  end

  config.token = ::Configuration[:moip_token] or ''
  config.key = ::Configuration[:moip_key] or ''
end
