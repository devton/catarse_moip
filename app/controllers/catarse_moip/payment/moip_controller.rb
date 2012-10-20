require 'moip_transparente'
module CatarseMoip::Payment
  class MoipController < ApplicationController
    layout :false

    def js
      @moip = ::MoipTransparente::Checkout.new
      render :text => open(@moip.get_javascript_url).set_encoding('ISO-8859-1').read.encode('utf-8')
    end

    def review
      @moip = ::MoipTransparente::Checkout.new
    end

    def moip_response
      @backer = current_user.backs.find params[:id]

      @backer.payment_notifications.create(extra_data: params[:response])

      if not @backer.confirmed and params[:response]['Status'] == 'Autorizado'
        @backer.confirm!
      end

      unless params[:response]['StatusPagamento'] == 'Falha'
        @backer.update_attributes({
          payment_id: params[:response]['CodigoMoIP'],
          payment_service_fee: params[:response]['TaxaMoIP'].to_f
        })
      end

      render nothing: true, status: 200
    end

    def get_moip_token
      @backer = current_user.backs.not_confirmed.find params[:id]

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

      if response and response[:token]
        @backer.update_column :payment_token, response[:token]
      end

      render json: { get_token_response: response, moip: @moip, widget_tag: @moip.widget_tag('checkoutSuccessful', 'checkoutFailure'), javascript_tag: @moip.javascript_tag }
    end
  end
end
