require 'spec_helper'

describe CatarseMoip::Payment::NotificationsController do
  let(:backer){ create(:backer, :value => 21.90, :confirmed => true, :refunded => false) }
  let(:extra_data){ {"id_transacao"=>backer.key, "valor"=>"2190", "cod_moip"=>"12345123", "forma_pagamento"=>"1", "tipo_pagamento"=>"CartaoDeCredito", "email_consumidor"=>"some@email.com", "controller"=>"catarse_moip/payment/notifications", "action"=>"create"} }
  subject{ response }

  describe "POST create" do
    context "when we search for a non-existant backer" do
      before do
        post :create, {:id_transacao => "non-existant backer key", :use_route => 'catarse_moip'}
      end

      its(:body){ should == ' ' }
      its(:status){ should == 422 }
    end

    context "when we seach for an existing backer" do
      before do
        CatarseMoip::Processors::Moip.any_instance.should_receive(:process!).with(backer, {"id_transacao"=>backer.key, "controller"=>"catarse_moip/payment/notifications", "action"=>"create"})
        post :create, {:id_transacao => backer.key, :use_route => 'catarse_moip'}
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
      it("should assign backer"){ assigns(:backer).should == backer }
      it("should assing processor"){ assigns(:processor).class.should == CatarseMoip::Processors::Moip }
    end
  end
end
