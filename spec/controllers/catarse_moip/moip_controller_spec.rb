# encoding: utf-8
require 'spec_helper'

describe CatarseMoip::MoipController do
  subject{ response }

  let(:get_token_response){{:status=>:fail, :code=>"171", :message=>"TelefoneFixo do endereço deverá ser enviado obrigatorio", :id=>"201210192052439150000024698931"}}
  let(:backer){ create(:backer, :value => 21.90, :confirmed => true, :refunded => false) }
  let(:extra_data){ {"id_transacao"=>backer.key, "valor"=>"2190", "cod_moip"=>"12345123", "forma_pagamento"=>"1", "tipo_pagamento"=>"CartaoDeCredito", "email_consumidor"=>"some@email.com", "controller"=>"catarse_moip/payment/notifications", "action"=>"create"} }

  before do
    @backer = FactoryGirl.create(:backer, :confirmed => false)
    controller.stub(:current_user).and_return(@backer.user)
    ::MoipTransparente::Checkout.any_instance.stub(:get_token).and_return(get_token_response)
    ::MoipTransparente::Checkout.any_instance.stub(:moip_widget_tag).and_return('<div>')
    ::MoipTransparente::Checkout.any_instance.stub(:moip_javascript_tag).and_return('<script>')
    ::MoipTransparente::Checkout.any_instance.stub(:as_json).and_return('{}')
    PaymentEngines.stub(:find_payment).and_return(backer)
  end

  describe "POST create_notification" do
    context "when we search for a non-existant backer" do
      before do
        post :create_notification, {:id_transacao => "non-existant backer key", :use_route => 'catarse_moip'}
      end

      its(:body){ should == "#<ActiveRecord::RecordNotFound: Couldn't find Backer with key = non-existant backer key>: Couldn't find Backer with key = non-existant backer key recebemos: {\"id_transacao\"=>\"non-existant backer key\", \"controller\"=>\"catarse_moip/payment/notifications\", \"action\"=>\"create\"}" }
      its(:status){ should == 422 }
    end

    context "when we seach for an existing backer" do
      before do
        controller.should_receive(:process_notification).with({"id_transacao"=>backer.key, "controller"=>"catarse_moip/payment/notifications", "action"=>"create"})
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
      controller.should_receive(:process_notification)
      post :moip_response, id: @backer.id, response: {StatusPagamento: 'Sucesso'}, use_route: 'catarse_moip'
    end

    its(:status){ should == 200 }
  end

  describe "POST get_moip_token" do
    before do
      post :get_moip_token, :id => @backer.id, :use_route => 'catarse_moip'
    end

    its(:status){ should == 200 }
    its(:body){ should == "{\"get_token_response\":{\"status\":\"fail\",\"code\":\"171\",\"message\":\"TelefoneFixo do endere\\u00e7o dever\\u00e1 ser enviado obrigatorio\",\"id\":\"201210192052439150000024698931\"},\"moip\":\"{}\",\"widget_tag\":\"<div id='MoipWidget'\\n          data-token=''\\n          callback-method-success='checkoutSuccessful' \\n          callback-method-error='checkoutFailure'>\\n    </div>\",\"javascript_tag\":\"<script type='text/javascript' src='https://www.moip.com.br/transparente/MoipWidget-v2.js' charset='ISO-8859-1'></script>\"}" }
  end
end
