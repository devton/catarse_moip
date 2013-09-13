# encoding: utf-8
require 'spec_helper'

describe CatarseMoip::MoipController do
  subject{ response }

  let(:get_token_response){{:status=>:fail, :code=>"171", :message=>"TelefoneFixo do endereço deverá ser enviado obrigatorio", :id=>"201210192052439150000024698931"}}
  let(:backer){ double('backer', {
    id: 1,
    key: 'backer key',
    payment_id: 'payment id',
    project: project,
    pending?: false,
    value: 10,
    user: user,
    payer_name: 'foo',
    payer_email: 'foo@bar.com',
    address_street: 'test',
    address_number: '123',
    address_complement: '123',
    address_neighbourhood: '123',
    address_city: '123',
    address_state: '123',
    address_zip_code: '123',
    address_phone_number: '123',
    confirmed?: true,
    confirm!: true,
    canceled?: true,
    cancel!: true,
    refunded?: true,
    refund!: true
  }) }

  let(:user){ double('user', id: 1) }
  let(:project){ double('project', id: 1, name: 'test project') }
  let(:extra_data){ {"id_transacao"=>backer.key, "valor"=>"2190", "cod_moip"=>"12345123", "forma_pagamento"=>"1", "tipo_pagamento"=>"CartaoDeCredito", "email_consumidor"=>"some@email.com", "controller"=>"catarse_moip/payment/notifications", "action"=>"create"} }

  before do
    controller.stub(:current_user).and_return(user)
    ::MoipTransparente::Checkout.any_instance.stub(:get_token).and_return(get_token_response)
    ::MoipTransparente::Checkout.any_instance.stub(:moip_widget_tag).and_return('<div>')
    ::MoipTransparente::Checkout.any_instance.stub(:moip_javascript_tag).and_return('<script>')
    ::MoipTransparente::Checkout.any_instance.stub(:as_json).and_return('{}')
    PaymentEngines.stub(:find_payment).and_return(backer)
    PaymentEngines.stub(:create_payment_notification)
    backer.stub(:with_lock).and_yield
  end

  describe "POST create_notification" do
    context "when we search for a non-existant backer" do
      before do
        PaymentEngines.should_receive(:find_payment).with(key: "non-existant backer key").and_raise('error')
        post :create_notification, {:id_transacao => "non-existant backer key", :use_route => 'catarse_moip'}
      end

      its(:status){ should == 422 }
      its(:body){ should == "#<RuntimeError: error>: error recebemos: {\"id_transacao\"=>\"non-existant backer key\", \"controller\"=>\"catarse_moip/moip\", \"action\"=>\"create_notification\"}" }
    end

    context "when we seach for an existing backer" do
      before do
        controller.stub(:params).and_return({:id_transacao =>backer.key, :controller => "catarse_moip/moip", :action => "create_notification"})
        PaymentEngines.should_receive(:find_payment).with(key: backer.key).and_return(backer)
        controller.should_receive(:process_moip_message)
        post :create_notification, {:id_transacao => backer.key, :use_route => 'catarse_moip'}
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
      it("should assign backer"){ assigns(:backer).should == backer }
    end

    context "when receive ordered notification for backer" do
      before do
        controller.stub(:params).and_return({:cod_moip => 125, :id_transacao =>backer.key, :controller => "catarse_moip/moip", :action => "create_notification", :status_pagamento => 5})
        backer.stub(:payment_id).and_return('123')

        controller.should_receive(:process_moip_message).and_call_original
        backer.should_receive(:update_attributes).with(payment_id: 125)
        post :create_notification, {:id_transacao => backer.key, :use_route => 'catarse_moip'}
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
      it("should assign backer"){ assigns(:backer).should == backer }
    end

    context "when we receive a notification with the same payment id but with another status" do
      before do
        controller.stub(:params).and_return({:cod_moip => 123, :id_transacao =>backer.key, :controller => "catarse_moip/moip", :action => "create_notification", :status_pagamento => 1})
        backer.stub(:payment_id).and_return('123')

        controller.should_receive(:process_moip_message).and_call_original
        backer.should_receive(:update_attributes).with(payment_id: 123)
        post :create_notification, {:id_transacao => backer.key, :use_route => 'catarse_moip'}
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
      it("should assign backer"){ assigns(:backer).should == backer }
    end

    context "when receive a unordered notification for backer" do
      before do
        controller.stub(:params).and_return({:cod_moip => 122, :id_transacao =>backer.key, :controller => "catarse_moip/moip", :action => "create_notification", :status_pagamento => 5})
        backer.stub(:payment_id).and_return('123')

        controller.should_receive(:process_moip_message).and_call_original
        backer.should_not_receive(:update_attributes).with(payment_id: 122)
        post :create_notification, {:id_transacao => backer.key, :use_route => 'catarse_moip'}
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
      it("should assign backer"){ assigns(:backer).should == backer }
    end

    context "when backer payment_id is null" do
      before do
        controller.stub(:params).and_return({:cod_moip => 122, :id_transacao =>backer.key, :controller => "catarse_moip/moip", :action => "create_notification", :status_pagamento => 5})
        backer.stub(:payment_id).and_return(nil)

        controller.should_receive(:process_moip_message).and_call_original
        backer.should_receive(:update_attributes).with(payment_id: 122)
        post :create_notification, {:id_transacao => backer.key, :use_route => 'catarse_moip'}
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
      it("should assign backer"){ assigns(:backer).should == backer }
    end
  end

  describe "GET js" do
    let(:file){ double('js_file') }

    context "when the content of get_javascript_url raises an error" do
      before do
        controller.should_receive(:open).at_least(3).times.and_raise('error')
        ->{
          get :js, locale: :pt, use_route: 'catarse_moip'
        }.should raise_error('error')
      end
      its(:status){ should == 200 }
    end

    context "when the content of get_javascript_url is read without errors" do
      before do
        controller.should_receive(:open).and_return(file)
        file.should_receive(:set_encoding).and_return(file)
        file.should_receive(:read).and_return(file)
        file.should_receive(:encode).and_return('js content')
        get :js, locale: :pt, use_route: 'catarse_moip'
      end
      its(:status){ should == 200 }
      its(:body){ should == 'js content' }
    end
  end

  describe "POST moip_response" do
    let(:processor){ double('moip processor') }
    before do
      controller.should_receive(:first_update_backer)
      post :moip_response, id: backer.id, response: {StatusPagamento: 'Sucesso'}, use_route: 'catarse_moip'
    end

    its(:status){ should == 200 }
  end

  describe "POST get_moip_token" do
    before do
      post :get_moip_token, :id => backer.id, :use_route => 'catarse_moip'
    end

    its(:status){ should == 200 }
    its(:body){ should == "{\"get_token_response\":{\"status\":\"fail\",\"code\":\"171\",\"message\":\"TelefoneFixo do endereço deverá ser enviado obrigatorio\",\"id\":\"201210192052439150000024698931\"},\"moip\":\"{}\",\"widget_tag\":\"<div id='MoipWidget'\\n          data-token=''\\n          callback-method-success='checkoutSuccessful' \\n          callback-method-error='checkoutFailure'>\\n    </div>\",\"javascript_tag\":\"<script type='text/javascript' src='https://www.moip.com.br/transparente/MoipWidget-v2.js' charset='ISO-8859-1'></script>\"}" }
  end

  describe "#first_update_backer" do
    before do
      controller.stub(:backer).and_return(backer)
      backer.stub(:payment_token).and_return('token')
    end

    context "with no response from moip" do
      let(:moip_query_response) { nil }
      before do
        MoIP.should_receive(:query).with(backer.payment_token).and_return(moip_query_response)
        backer.should_not_receive(:update_attributes)
      end
      it("should never call update attributes"){ controller.first_update_backer }
    end

    context "with an incomplete transaction" do
      let(:moip_query_response) do
        {"ID"=>"201210191926185570000024694351", "Status"=>"Sucesso"}
      end
      before do
        MoIP.should_receive(:query).with(backer.payment_token).and_return(moip_query_response)
        backer.should_not_receive(:update_attributes)
      end
      it("should never call update attributes"){ controller.first_update_backer }
    end

    context "with a real data set that works for some cases" do
      let(:moip_query_response) do
        {"ID"=>"201210191926185570000024694351", "Status"=>"Sucesso", "Autorizacao"=>{"Pagador"=>{"Nome"=>"juliana.giopato@hotmail.com", "Email"=>"juliana.giopato@hotmail.com"}, "EnderecoCobranca"=>{"Logradouro"=>"Rua sócrates abraão ", "Numero"=>"16.0", "Complemento"=>"casa 19", "Bairro"=>"Campo Limpo", "CEP"=>"05782-470", "Cidade"=>"São Paulo", "Estado"=>"SP", "Pais"=>"BRA", "TelefoneFixo"=>"1184719963"}, "Recebedor"=>{"Nome"=>"Catarse", "Email"=>"financeiro@catarse.me"}, "Pagamento"=>[{"Data"=>"2012-10-17T13:06:07.000-03:00", "DataCredito"=>"2012-10-19T00:00:00.000-03:00", "TotalPago"=>"50.00", "TaxaParaPagador"=>"0.00", "TaxaMoIP"=>"1.34", "ValorLiquido"=>"48.66", "FormaPagamento"=>"BoletoBancario", "InstituicaoPagamento"=>"Bradesco", "Status"=>"Autorizado", "Parcela"=>{"TotalParcelas"=>"1"}, "CodigoMoIP"=>"0000.1325.5258"}, {"Data"=>"2012-10-17T13:05:49.000-03:00", "TotalPago"=>"50.00", "TaxaParaPagador"=>"0.00", "TaxaMoIP"=>"3.09", "ValorLiquido"=>"46.91", "FormaPagamento"=>"CartaoDebito", "InstituicaoPagamento"=>"Visa", "Status"=>"Iniciado", "Parcela"=>{"TotalParcelas"=>"1"}, "CodigoMoIP"=>"0000.1325.5248"}]}}
      end
      before do
        MoIP.should_receive(:query).with(backer.payment_token).and_return(moip_query_response)
        payment = moip_query_response["Autorizacao"]["Pagamento"].first
        backer.should_receive(:confirm!)
        backer.should_receive(:update_attributes).with({
          payment_id: payment["CodigoMoIP"],
          payment_choice: payment["FormaPagamento"],
          payment_service_fee: payment["TaxaMoIP"]
        })
      end
      it("should call update attributes"){ controller.first_update_backer }
    end
  end

  describe "#process_moip_message" do
    before do
      controller.stub(:backer).and_return(backer)
      backer.stub(:confirmed?).and_return(false)
      backer.stub(:confirm!)
      controller.stub(:update_backer)
    end

    context "when there is a written back request and backer is not refunded" do
      before do
        controller.stub(:params).and_return(post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::MoipController::TransactionStatus::WRITTEN_BACK}))
        backer.stub(:refunded?).and_return(false)
        backer.should_receive(:refund!)
        backer.should_receive(:update_attributes)
      end

      it 'should call refund!' do
        controller.process_moip_message
      end
    end

    context "when there is an authorized request" do
      before do
        controller.stub(:params).and_return(post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::MoipController::TransactionStatus::AUTHORIZED}))
        backer.should_receive(:confirm!)
        backer.should_receive(:update_attributes)
      end

      it 'should call confirm!' do
        controller.process_moip_message
      end
    end

    context "when there is a refund request" do
      before do
        controller.stub(:params).and_return(post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::MoipController::TransactionStatus::REFUNDED}))
        backer.stub(:refunded?).and_return(false)
        backer.should_receive(:refund!)
        backer.should_receive(:update_attributes)
      end

      it 'should mark refunded to true' do
        controller.process_moip_message
      end
    end
  end
end
