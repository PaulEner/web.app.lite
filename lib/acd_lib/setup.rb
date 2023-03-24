# -*- encoding : UTF-8 -*-
module AcdLib
  class Setup
    def initialize(params)
      @organization = params[:organization]
      @customer     = params[:customer]
      @params       = params[:columns]
    end

    def execute
      @acd = @customer.nil? ? @organization.acd.presence : @customer.acd.presence

      @acd = Software::Acd.new if @acd.nil?

      @owner      = nil

      unless @customer
        @owner = @organization

        update_and_save
      else
        @owner    = @customer

        if @params[:action] == "update"
          return false if !@params[:is_used] && @acd.nil?

          return true if !@params[:is_used] && @acd.present? && @acd.destroy

          update_and_save
        else
          if @params[:remove_customer]
            @acd.code = nil
            @acd.auto_deliver  = -1

            return true if @acd.save
          elsif @code.present?
            @acd.code = @code if @code.present?

            update_and_save
          end
        end
      end

      true
    end

    private

    def update_and_save
      @acd.owner           = @owner
      @acd.auto_deliver    = @params[:auto_deliver]  if @params[:auto_deliver].present?
      @acd.is_used         = @params[:is_used]       if @params[:is_used].to_s.present?
      @acd.code            = @params[:code] if @params[:code].present?
      @acd.username        = @params[:username] if @params[:username].present?
      @acd.password        = @params[:password] if @params[:password].present?
      @acd.url              = @params[:url] if @params[:url].present?

      @acd.save!
    end
  end

end