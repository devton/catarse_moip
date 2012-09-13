require 'spec_helper'

describe CatarseMoip::Payment::MoipController do
  describe 'POST pay' do
    let(:current_user) { Factory(:user, :full_name => 'Lorem Ipsum',
          :email => 'lorem@lorem.com',
          :address_zip_code => '33600-999',
          :address_street => 'R. Ipsum',
          :address_number => '666',
          :address_complement => 'House',
          :address_city => 'Some City',
          :address_state => 'LP',
          :phone_number => '(90) 9999-9999') }

    context 'when we find some error' do
      it 'should raise a error when current_user is not present' do
        lambda {
          post :pay, { id: 10, locale: 'en', use_route: 'catarse_moip' }
        }.should raise_exception
      end

      it 'when backer already confirmed, should raise a not found' do
        sign_in(current_user)
        backer = Factory(:backer, confirmed: true, user: current_user)

        lambda {
          post :pay, { id: backer.id, locale: 'en', use_route: 'catarse_moip' }
        }.should raise_exception ActiveRecord::RecordNotFound
      end

      it 'when backer not belongs to current_user, should raise a not found' do
        sign_in(current_user)
        backer = Factory(:backer)

        lambda {
          post :pay, { id: backer.id, locale: 'en', use_route: 'catarse_moip' }
        }.should raise_exception ActiveRecord::RecordNotFound
      end
    end

    context 'throught moip' do
      context 'when raise something' do
        before do
          MoIP::Client.stub(:checkout).and_raise(StandardError)
        end

        it 'should handle the error and redirect' do
          sign_in(current_user)
          backer = Factory(:backer, confirmed: false, user: current_user)

          post :pay, { id: backer.id, locale: 'en', use_route: 'catarse_moip' }
          backer.reload

          backer.payment_token.should be_nil
          flash[:failure].should == I18n.t('projects.backers.checkout.moip_error')
          response.should be_redirect
        end
      end

      context 'when we do not have any errors' do
        before do
          MoIP::Client.stub(:checkout).and_return({'Token' => 'ABCD'})
        end

        it 'should redirect to moip, setup session payment_token and update backer with token' do
          sign_in(current_user)
          backer = Factory(:backer, confirmed: false, user: current_user)

          post :pay, { id: backer.id, locale: 'en', use_route: 'catarse_moip' }
          backer.reload

          backer.payment_token.should == 'ABCD'
          session[:_payment_token].should == 'ABCD'

          response.should redirect_to("https://www.moip.com.br/Instrucao.do?token=ABCD")
        end
      end
    end

  end
end
