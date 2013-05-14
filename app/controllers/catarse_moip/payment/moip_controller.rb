require 'moip_transparente'
require 'catarse_moip/processors/moip'

module CatarseMoip::Payment
  class MoipController < ApplicationController
    skip_before_filter :force_http
    layout :false

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
      @backer = current_user.backs.find params[:id]

      # This lock tries to solve the deadlock we are having on backer updates
      @backer.with_lock do

        @backer.payment_notifications.create(extra_data: params[:response])
        
        @backer.waiting if @backer.pending?

        unless params[:response]['StatusPagamento'] == 'Falha'
          @processor = CatarseMoip::Processors::Moip.new @backer
          @processor.process!(params)
        end

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
