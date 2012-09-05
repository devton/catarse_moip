require 'spec_helper'

describe CatarseMoip::Payment::NotificationsController do
  let(:post_moip_params) do
    {
      :id_transacao => 'ABCD',
      :valor => 2190, #=> R$ 21,90
      :status_pagamento => 3,
      :cod_moip => 12345123,
      :forma_pagamento => 1,
      :tipo_pagamento => 'CartaoDeCredito',
      :email_consumidor => 'some@email.com'
    }
  end

  let(:moip_query_response) do
    {
      "ID"=>"201109300946542390000012428473", "Status"=>"Sucesso",
      "Autorizacao"=>{
        "Pagador"=>{
          "Nome"=>"Lorem Ipsum", "Email"=>"some@email.com"
        },
        "EnderecoCobranca"=>{
          "Logradouro"=>"Some Address ,999", "Numero"=>"999",
          "Complemento"=>"Address A", "Bairro"=>"Hello World", "CEP"=>"99999-000",
          "Cidade"=>"Some City", "Estado"=>"MG", "Pais"=>"BRA",
          "TelefoneFixo"=>"(31)3666-6666"
        },
        "Recebedor"=>{
          "Nome"=>"Happy Guy", "Email"=>"happy@email.com"
        },
        "Pagamento"=>{
          "Data"=>"2011-09-30T09:33:37.000-03:00", "TotalPago"=>"999.00", "TaxaParaPagador"=>"0.00",
          "TaxaMoIP"=>"19.37", "ValorLiquido"=>"979.63", "FormaPagamento"=>"BoletoBancario",
          "InstituicaoPagamento"=>"Itau", "Status"=>"BoletoImpresso", "CodigoMoIP"=>"0000.0728.5285"
        }
      }
    }
  end

  let(:backer){ create(:backer, :value => 21.90, :confirmed => true, :refunded => false) }
  let(:extra_data){ {"id_transacao"=>backer.key, "valor"=>"2190", "cod_moip"=>"12345123", "forma_pagamento"=>"1", "tipo_pagamento"=>"CartaoDeCredito", "email_consumidor"=>"some@email.com", "controller"=>"catarse_moip/payment/notifications", "action"=>"create"} }
  subject{ response }

  describe "POST create" do
    context "when we search for a non-existant backer" do
      before do
        post :create, post_moip_params.merge!({:id_transacao => "non-existant backer key", :status_pagamento => CatarseMoip::Payment::NotificationsController::TransactionStatus::WRITTEN_BACK, :use_route => 'catarse_moip'})
      end

      its(:body){ should == ' ' }
      its(:status){ should == 422 }
    end

    context "when there is a written back request" do
      before do
        post :create, post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Payment::NotificationsController::TransactionStatus::WRITTEN_BACK, :use_route => 'catarse_moip'})
      end

      it 'should mark refunded to true' do
        backer.reload.refunded.should be_true
      end

      it 'should create a proper payment_notification' do
        backer.reload.payment_notifications.size.should == 1
        backer.reload.payment_notifications.first.extra_data.should == extra_data.merge("status_pagamento" => CatarseMoip::Payment::NotificationsController::TransactionStatus::WRITTEN_BACK.to_s)
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
    end

    context "when there is an authorized request" do
      before do
        post :create, post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Payment::NotificationsController::TransactionStatus::AUTHORIZED, :use_route => 'catarse_moip'})
      end

      it 'should mark refunded to true' do
        backer.reload.refunded.should be_false
      end

      it 'should create a proper payment_notification' do
        backer.reload.payment_notifications.size.should == 1
        backer.reload.payment_notifications.first.extra_data.should == extra_data.merge("status_pagamento" => CatarseMoip::Payment::NotificationsController::TransactionStatus::AUTHORIZED.to_s)
      end

      it 'should confirm the backer' do
        backer.reload.confirmed.should be_true
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
    end

    context "when there is a refund request" do
      before do
        post :create, post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Payment::NotificationsController::TransactionStatus::REFUNDED, :use_route => 'catarse_moip'})
      end

      it 'should mark refunded to true' do
        backer.reload.refunded.should be_true
      end

      it 'should create a proper payment_notification' do
        backer.reload.payment_notifications.size.should == 1
        backer.reload.payment_notifications.first.extra_data.should == extra_data.merge("status_pagamento" => CatarseMoip::Payment::NotificationsController::TransactionStatus::REFUNDED.to_s)
      end

      its(:body){ should == ' ' }
      its(:status){ should == 200 }
    end
  end
end
