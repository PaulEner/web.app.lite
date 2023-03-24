module MyUnisoftLib
  module Api
    class Client
      attr_accessor :request, :settings

      def initialize(firm_id)
        @settings = {
                      base_api_url:           MyUnisoftLib::Api::Util.config.base_api_url,
                      base_user_url:          MyUnisoftLib::Api::Util.config.base_user_url,
                      member_group_id:        MyUnisoftLib::Api::Util.config.member_group_id,
                      granted_for:            MyUnisoftLib::Api::Util.config.granted_for,
                      target:                 MyUnisoftLib::Api::Util.config.target,
                      x_third_party_secret:   MyUnisoftLib::Api::Util.config.x_third_party_secret,
                      user_token:             MyUnisoftLib::Api::Util.config.user_token,
                      username:               MyUnisoftLib::Api::Util.config.username,
                      password:               MyUnisoftLib::Api::Util.config.password
                    }

        @access_token = get_token_for_firm(firm_id)[:body]['api_token']
      end

      def get_token_for_firm(firm_id)

        body = { mail: @settings[:username], password: @settings[:password], firm: firm_id }.to_json

        @response = connection.post do |request|
          request.url 'api/authenticate/firm'
          request.headers = { "Content-Type" => "application/json" }
          request.body = body
        end

        json_parse
      end


      def get_account(id)
        @response = connection.get do |request|
          request.url "api/v1/account"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}", "society-id" => "#{id}" }
          request.params = { "mode" => "2" }
        end

        json_parse
      end

      def get_societies_list
        @response = connection.get do |request|
          request.url "api/v1/society"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}", "Content-Type" => "application/json" }
        end

        json_parse
      end

      def get_diary(id)
        @response = connection.get do |request|
          request.url "api/v1/diary"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}", "Content-Type" => "application/json", "society-id" => "#{id}" }
        end

        JSON.parse @response.body
      end

      def send_pre_assignment(data_path="")
        data = JSON.parse(File.read(data_path).to_json)

        @response = connection.post do |request|
          request.url "api/v1/entry/temp"
          request.headers = { "Authorization" => "Bearer #{@access_token}", "X-Third-Party-Secret" => "#{@settings[:x_third_party_secret]}", "Content-Type" => "application/json" }
          request.body = data
        end

        JSON.parse @response.body
      end

      private

      def connection
        Faraday.new(:url => @settings[:base_api_url], :ssl => {:verify => false}) do |f|
          f.response :logger
          f.adapter Faraday.default_adapter
        end
      end

      def json_parse
        if @response.status == 200
          { status: "success", body: JSON.parse(@response.body) }
        else
          { status: "error", body: JSON.parse(@response.body) }
        end
      end
    end
  end
end