# -*- encoding : UTF-8 -*-
module SageGecLib
  class Setup
    def initialize(params)
      @organization = params[:organization]
      @customer     = params[:customer]
      @params       = params[:columns]
    end

    def execute
      @sage_gec = @customer.nil? ? @organization.sage_gec.presence : @customer.sage_gec.presence

      @sage_gec = Software::SageGec.new if @sage_gec.nil?

      @owner      = nil

      unless @customer
        @owner = @organization

        update_and_save
      else
        @owner    = @customer

        if @params[:action] == "update"
          return false if !@params[:is_used] && @sage_gec.nil?

          return true if !@params[:is_used] && @sage_gec.present? && @sage_gec.destroy

          update_and_save
        else
          if @params[:remove_customer]
            @sage_gec.sage_private_api_uuid = nil
            @sage_gec.auto_deliver  = -1

            return true if @sage_gec.save
          elsif @sage_private_api_uuid.present?
            @sage_gec.sage_private_api_uuid = @sage_private_api_uuid if @sage_private_api_uuid.present?

            update_and_save
          end
        end
      end

      true
    end

    private

    def update_and_save
      @sage_gec.owner           = @owner
      @sage_gec.auto_deliver    = @params[:auto_deliver]  if @params[:auto_deliver].present?
      @sage_gec.is_used         = @params[:is_used]       if @params[:is_used].to_s.present?
      @sage_gec.sage_private_api_uuid = @params[:sage_private_api_uuid] if @params[:sage_private_api_uuid].present?

      @sage_gec.save!
    end


    def client
      @client ||= SageGecLib::Api::Client.new(@api_token)
    end
  end

end