module CatarseMoip
  class PaymentEngine

    def name
      'MoIP'
    end

    def review_path contribution
      CatarseMoip::Engine.routes.url_helpers.review_moip_path(contribution)
    end

    def locale
      'pt'
    end

    def can_do_refund?
      false
    end

    def direct_refund
      false
    end

  end
end
