require 'moip_transparente'

module CatarseMoip
  class MoipController < ApplicationController
    class TransactionStatus < ::EnumerateIt::Base
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

    skip_before_filter :force_http
    layout :false

    def create_notification
      @backer = PaymentEngines.find_payment key: params[:id_transacao]
      process_moip_message(params)
      return render :nothing => true, :status => 200
    #rescue Exception => e
      #::Airbrake.notify({ :error_class => "MoIP notification", :error_message => "MoIP notification: #{e.inspect}", :parameters => params}) rescue nil
      #return render :text => "#{e.inspect}: #{e.message} recebemos: #{params}", :status => 422
    end

    def js
      tries = 0
      begin
        @moip = ::MoipTransparente::Checkout.new
        render :text => open(@moip.get_javascript_url).set_encoding('ISO-8859-1').read.encode('utf-8')
      rescue Exception => e
        tries += 1
        retry unless tries > 3
        raise e
      end
    end

    def review
      @moip = ::MoipTransparente::Checkout.new
    end

    def moip_response
      @backer = PaymentEngines.find_payment id: params[:id], user_id: current_user.id
      @backer.payment_notifications.create(extra_data: params[:response])
      @backer.waiting! if @backer.pending?

      process_moip_message params unless params[:response]['StatusPagamento'] == 'Falha'

      render nothing: true, status: 200
    end

    def get_moip_token
      @backer = PaymentEngines.find_payment id: params[:id], user_id: current_user.id

      ::MoipTransparente::Config.test = (::Configuration[:moip_test] == 'true')
      ::MoipTransparente::Config.access_token = ::Configuration[:moip_token]
      ::MoipTransparente::Config.access_key = ::Configuration[:moip_key]

      @moip = ::MoipTransparente::Checkout.new

      invoice = {
        razao: "Apoio para o projeto '#{@backer.project.name}'",
        id: @backer.key,
        total: @backer.value.to_s,
        acrescimo: '0.00',
        desconto: '0.00',
        cliente: {
          id: @backer.user.id,
          nome: @backer.payer_name,
          email: @backer.payer_email,
          logradouro: "#{@backer.address_street}, #{@backer.address_number}",
          complemento: @backer.address_complement,
          bairro: @backer.address_neighbourhood,
          cidade: @backer.address_city,
          uf: @backer.address_state,
          cep: @backer.address_zip_code,
          telefone: @backer.address_phone_number
        }
      }

      response = @moip.get_token(invoice)

      session[:thank_you_id] = @backer.project.id

      @backer.update_column :payment_token, response[:token] if response and response[:token]

      render json: { get_token_response: response, moip: @moip, widget_tag: @moip.widget_tag('checkoutSuccessful', 'checkoutFailure'), javascript_tag: @moip.javascript_tag }
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

    def process_moip_message params
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
