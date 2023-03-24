# -*- encoding : UTF-8 -*-
module MyUnisoftLib
  class Setup
    def initialize(params)
      @organization = params[:organization]
      @customer     = params[:customer]
      @params       = params[:columns]
    end

    def execute
      @my_unisoft = @customer.nil? ? @organization.my_unisoft.presence : @customer.my_unisoft.presence

      @my_unisoft = Software::MyUnisoft.new if @my_unisoft.nil?

      @owner      = nil

      unless @customer
        @owner = @organization
        update_and_save
      else
        @owner    = @customer

        if @params[:action] == "update"
          return false if !@params[:is_used] && @my_unisoft.nil?

          return true if !@params[:is_used] && @my_unisoft.present? && @my_unisoft.destroy

          update_and_save
        else
          if @params[:remove_customer]
            @my_unisoft.api_token     = nil
            @my_unisoft.society_id    = nil
            @my_unisoft.access_routes = ""
            @my_unisoft.auto_deliver  = -1

            return true if @my_unisoft.save
          elsif @society_id.present?
            @my_unisoft.society_id = @society_id

            update_and_save
          end
        end
      end

      true
    end

    private


    def update_and_save
      @my_unisoft.owner           = @owner
      @my_unisoft.auto_deliver    = @params[:auto_deliver]  if @params[:auto_deliver].present?
      @my_unisoft.is_used         = @params[:is_used]       if @params[:is_used].to_s.present?
      @my_unisoft.firm_id         = @params[:firm_id] if @params[:firm_id].present?

      @my_unisoft.save
    end


    def client
      @client ||= MyUnisoftLib::Api::Client.new(@customer.organization.my_unisoft.firm_id)
    end
  end

end