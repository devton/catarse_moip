# encoding: utf-8

require 'spec_helper'

describe CatarseMoip::Processors::Moip do
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

  let(:extra_data){ {"id_transacao"=>backer.key, "valor"=>2190, "cod_moip"=>12345123, "forma_pagamento"=>1, "tipo_pagamento"=>"CartaoDeCredito", "email_consumidor"=>"some@email.com"} }
  let(:backer){ create(:backer) }
  let(:processor){ CatarseMoip::Processors::Moip.new backer }

  describe "#update_backer" do
    before do
      backer.update_attributes :payment_id => nil
      MoIP.should_receive(:query).with(backer.payment_token).and_return(moip_query_response)
      processor.update_backer
    end

    context "with no response from moip" do
      let(:moip_query_response) { nil }
      it("should not assign payment_id"){ backer.payment_id.should be_nil }
    end

    context "with an incomplete transaction" do
      let(:moip_query_response) do
        {"ID"=>"201210191926185570000024694351", "Status"=>"Sucesso"}
      end
      it("should not assign payment_id"){ backer.payment_id.should be_nil }
    end

    context "with a real data set that works for some cases" do
      let(:moip_query_response) do
        {"ID"=>"201210191926185570000024694351", "Status"=>"Sucesso", "Autorizacao"=>{"Pagador"=>{"Nome"=>"juliana.giopato@hotmail.com", "Email"=>"juliana.giopato@hotmail.com"}, "EnderecoCobranca"=>{"Logradouro"=>"Rua sócrates abraão ", "Numero"=>"16.0", "Complemento"=>"casa 19", "Bairro"=>"Campo Limpo", "CEP"=>"05782-470", "Cidade"=>"São Paulo", "Estado"=>"SP", "Pais"=>"BRA", "TelefoneFixo"=>"1184719963"}, "Recebedor"=>{"Nome"=>"Catarse", "Email"=>"financeiro@catarse.me"}, "Pagamento"=>[{"Data"=>"2012-10-17T13:06:07.000-03:00", "DataCredito"=>"2012-10-19T00:00:00.000-03:00", "TotalPago"=>"50.00", "TaxaParaPagador"=>"0.00", "TaxaMoIP"=>"1.34", "ValorLiquido"=>"48.66", "FormaPagamento"=>"BoletoBancario", "InstituicaoPagamento"=>"Bradesco", "Status"=>"Autorizado", "Parcela"=>{"TotalParcelas"=>"1"}, "CodigoMoIP"=>"0000.1325.5258"}, {"Data"=>"2012-10-17T13:05:49.000-03:00", "TotalPago"=>"50.00", "TaxaParaPagador"=>"0.00", "TaxaMoIP"=>"3.09", "ValorLiquido"=>"46.91", "FormaPagamento"=>"CartaoDebito", "InstituicaoPagamento"=>"Visa", "Status"=>"Iniciado", "Parcela"=>{"TotalParcelas"=>"1"}, "CodigoMoIP"=>"0000.1325.5248"}]}}
      end
      it("should assign payment_id"){ backer.payment_id.should == moip_query_response["Autorizacao"]["Pagamento"][0]["CodigoMoIP"] }
      it("should assign payment_choice"){ backer.payment_choice.should == moip_query_response["Autorizacao"]["Pagamento"][0]["FormaPagamento"] }
      it("should assign payment_service_fee"){ backer.payment_service_fee.to_s.should == moip_query_response["Autorizacao"]["Pagamento"][0]["TaxaMoIP"] }
    end
  end

  describe "#process!" do
    before do
      processor.stub(:update_backer)
    end

    context "when we already have the payment_id in backers table" do
      before do
        backer.update_attributes :payment_id => 'test'
        processor.should_not_receive(:update_backer)
      end

      it 'should call update_backer on the processor' do
        processor.process! post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Processors::Moip::TransactionStatus::AUTHORIZED})
      end
    end

    context "when we still do not have the payment_id in backers table" do
      before do
        backer.update_attributes :payment_id => nil
        processor.should_receive(:update_backer)
      end

      it 'should call update_backer on the processor' do
        processor.process! post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Processors::Moip::TransactionStatus::AUTHORIZED})
      end
    end

    context "when there is a written back request" do
      let(:backer){ create(:backer, state: 'confirmed') }
      before do
        processor.process! post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Processors::Moip::TransactionStatus::WRITTEN_BACK})
      end

      it 'should mark refunded to true' do
        backer.reload.refunded?.should be_true
      end

      it 'should create a proper payment_notification' do
        backer.reload.payment_notifications.size.should == 1
        backer.reload.payment_notifications.first.extra_data.should == extra_data.merge("status_pagamento" => CatarseMoip::Processors::Moip::TransactionStatus::WRITTEN_BACK)
      end
    end

    context "when there is an authorized request" do
      before do
        processor.process!(Hashie::Mash.new({"id_transacao"=>"#{backer.key}", "valor"=>"5000", "status_pagamento"=>"1", "cod_moip"=>"13255258", "forma_pagamento"=>"73", "tipo_pagamento"=>"BoletoBancario", "parcelas"=>"1", "recebedor_login"=>"softa", "email_consumidor"=>"juliana.giopato@hotmail.com", "action"=>"create", "controller"=>"catarse_moip/payment/notifications"}))
      end

      it 'should confirm the backer' do
        backer.reload.confirmed.should be_true
      end
    end

    context "when there is an authorized request" do
      before do
        processor.process! post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Processors::Moip::TransactionStatus::AUTHORIZED})
      end

      it 'should mark refunded to true' do
        backer.reload.refunded.should be_false
      end

      it 'should create a proper payment_notification' do
        backer.reload.payment_notifications.size.should == 1
        backer.reload.payment_notifications.first.extra_data.should == extra_data.merge("status_pagamento" => CatarseMoip::Processors::Moip::TransactionStatus::AUTHORIZED)
      end

      it 'should confirm the backer' do
        backer.reload.confirmed.should be_true
      end
    end

    context "when there is a refund request" do
      let(:backer){ create(:backer, state: 'confirmed') }
      before do
        processor.process! post_moip_params.merge!({:id_transacao => backer.key, :status_pagamento => CatarseMoip::Processors::Moip::TransactionStatus::REFUNDED})
      end

      it 'should mark refunded to true' do
        backer.reload.refunded?.should be_true
      end

      it 'should create a proper payment_notification' do
        backer.reload.payment_notifications.size.should == 1
        backer.reload.payment_notifications.first.extra_data.should == extra_data.merge("status_pagamento" => CatarseMoip::Processors::Moip::TransactionStatus::REFUNDED)
      end
    end
  end
end
