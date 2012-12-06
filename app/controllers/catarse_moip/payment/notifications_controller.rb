require 'catarse_moip/processors/moip'

module CatarseMoip::Payment
  class NotificationsController < ApplicationController
    skip_before_filter :force_http
    def create
     @backer = Backer.find_by_key! params[:id_transacao]
      @processor = CatarseMoip::Processors::Moip.new @backer
      @processor.process!(params)
      return render :nothing => true, :status => 200
    rescue Exception => e
      ::Airbrake.notify({ :error_class => "MoIP notification", :error_message => "MoIP notification: #{e.inspect}", :parameters => params}) rescue nil
      return render :text => "#{e.inspect}: #{e.message} recebemos: #{params}", :status => 422
    end

  end
end

