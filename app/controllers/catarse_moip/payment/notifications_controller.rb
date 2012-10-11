require 'catarse_moip/processors/moip'

module CatarseMoip::Payment
  class NotificationsController < ApplicationController
    def create
      @backer = Backer.find_by_key! params[:id_transacao]
      @processor = CatarseMoip::Processors::Moip.new @backer
      @processor.process!(params)
      return render :nothing => true, :status => 200
    rescue Exception => e
      return render :text => "#{e.inspect}: #{e.message}", :status => 422
    end

  end
end

