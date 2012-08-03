module CatarseMoip::Payment
  class MoipController < ApplicationController
    before_filter :setup_moip

    def checkout
      @backer = current_user.backs.not_confirmed.find params[:id]
      #begin
        response = MoIP::Client.checkout(payment_info)
        @backer.update_attribute :payment_token, response["Token"]
        session[:_payment_token] = response["Token"]

        redirect_to MoIP::Client.moip_page(response["Token"])
      #rescue Exception => e
        #Airbrake.notify({ :error_class => "Checkout MOIP Error", :error_message => "MOIP Error: #{e.inspect}", :parameters => params}) rescue nil
        #Rails.logger.info "-----> #{e.inspect}"
        #flash[:failure] = t('projects.backers.checkout.moip_error')
        #return redirect_to main_app.new_project_backer_path(@backer.project)        #
      #end
    end

    protected

    def setup_moip
      MoIP.setup do |config|
        config.uri = (::Configuration[:moip_uri] || 'https://moip.com.br/')
        config.token = ::Configuration[:moip_token]
        config.key = ::Configuration[:moip_key]
      end
    end

    def payer_info
      {
        nome: current_user.full_name,
        email: current_user.email,
        logradouro: current_user.address_street,
        numero: current_user.address_number,
        complemento: current_user.address_complement,
        bairro: current_user.address_neighbourhood,
        cidade: current_user.address_city,
        estado: current_user.address_state,
        pais: 'BRA',
        cep: current_user.address_zip_code,
        tel_fixo: current_user.phone_number
      }
    end

    def payment_info
      {
        valor: "%0.0f" % (@backer.value),
        id_proprio: @backer.key,
        razao: "Apoio para o projeto '#{@backer.project.name}'",
        forma: "BoletoBancario",
        dias_expiracao: 2,
        pagador: payer_info,
        url_retorno: main_app.thank_you_url
      }
    end
  end
end
