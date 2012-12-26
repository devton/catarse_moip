PaymentEngines.register({name: 'moip', review_path: ->(backer){ CatarseMoip::Engine.routes.url_helpers.review_payment_moip_path(backer) }, locale: 'pt'})
