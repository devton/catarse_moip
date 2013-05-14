# encoding: utf-8
require 'spec_helper'

describe CatarseMoip::Payment::MoipController do
  subject{ response }

  let(:get_token_response){{:status=>:fail, :code=>"171", :message=>"TelefoneFixo do endereço deverá ser enviado obrigatorio", :id=>"201210192052439150000024698931"}}

  before do
    @backer = FactoryGirl.create(:backer, :confirmed => false)
    controller.stub(:current_user).and_return(@backer.user)
    ::MoipTransparente::Checkout.any_instance.stub(:get_token).and_return(get_token_response)
    ::MoipTransparente::Checkout.any_instance.stub(:moip_widget_tag).and_return('<div>')
    ::MoipTransparente::Checkout.any_instance.stub(:moip_javascript_tag).and_return('<script>')
    ::MoipTransparente::Checkout.any_instance.stub(:as_json).and_return('{}')
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
      CatarseMoip::Processors::Moip.should_receive(:new).with(@backer).and_return(processor)
      processor.should_receive(:process!)
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
