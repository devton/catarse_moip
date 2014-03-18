begin
  module CatarseMoip
    class PaymentEngine < PaymentEngines::Interface

      def name
        'MoIP'
      end

      def review_path contribution
        CatarseMoip::Engine.routes.url_helpers.review_moip_path(contribution)
      end

      def locale
        'pt'
      end

    end
  end
rescue Exception => e
  puts "Error while use payment engine interface: #{e}"
end
