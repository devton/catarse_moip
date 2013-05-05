module CatarseMoip
  module Processors
    class Moip
      #MoIP API table:
      class PaymentMethods < EnumerateIt::Base
        associate_values(
          :DebitoBancario         => 1,
          :FinanciamentoBancario  => 2,
          :BoletoBancario         => 3,
          :CartaoDeCredito        => 4,
          :CartaoDeDebito         => 5,
          :CarteiraMoIP           => 6,
          :NaoDefinida            => 7
        )
      end

      class TransactionStatus < EnumerateIt::Base
        associate_values(
          :authorized =>      1,
          :started =>         2,
          :printed_boleto =>  3,
          :finished =>        4,
          :canceled =>        5,
          :process =>         6,
          :written_back =>    7,
          :refunded => 9
        )
      end

      def initialize(backer)
        @backer = backer
      end

      def update_backer
        response = ::MoIP.query(@backer.payment_token)
        if response && response["Autorizacao"]
          pagamento = response["Autorizacao"]["Pagamento"]
          pagamento = pagamento.first unless pagamento.respond_to?(:key)
          @backer.update_attributes({
            :payment_id => pagamento["CodigoMoIP"],
            :payment_choice => pagamento["FormaPagamento"],
            :payment_service_fee => pagamento["TaxaMoIP"]
          })
        end
      end

      def process!(params)
        update_backer if @backer.payment_id.nil?
        @backer.payment_notifications.create! extra_data: JSON.parse(params.to_json.force_encoding('iso-8859-1').encode('utf-8'))
        case params[:status_pagamento].to_i
        when TransactionStatus::AUTHORIZED
          @backer.confirm! unless @backer.confirmed?
        when TransactionStatus::WRITTEN_BACK, TransactionStatus::REFUNDED
          @backer.refund! unless @backer.refunded?
        when TransactionStatus::CANCELED
          @backer.cancel! unless @backer.canceled?
        end
      end
    end
  end
end
