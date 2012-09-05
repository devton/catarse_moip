module CatarseMoip::Payment
  class NotificationsController < ApplicationController
    def create
      @backer = Backer.find_by_key! params[:id_transacao]
      @backer.payment_notifications.create! extra_data: params
      case params[:status_pagamento].to_i
      when TransactionStatus::AUTHORIZED
        @backer.confirm! if not @backer.confirmed
      when TransactionStatus::WRITTEN_BACK, TransactionStatus::REFUNDED
        @backer.refund! unless @backer.refunded?
      end
      return render :nothing => true, :status => 200
    rescue
      return render :nothing => true, :status => 422
    end

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
  end
end

