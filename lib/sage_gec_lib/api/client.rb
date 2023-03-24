module SageGecLib
  module Api
    class Client
      attr_accessor :request, :settings

      def initialize
        @settings = {
                      base_url:       SageGecLib::Api::Util.config.base_url,
                      auth_base_url:  SageGecLib::Api::Util.config.auth_base_url,
                      audience:       SageGecLib::Api::Util.config.audience,
                      client_id:      SageGecLib::Api::Util.config.client_id,
                      client_secret:  SageGecLib::Api::Util.config.client_secret,
                      application_id: SageGecLib::Api::Util.config.application_id
                    }

        @token = access_token
      end

      def get_accountancy_practices_list
        path = "#{base_path}/accountancypractices"

        @response = connection_bearer.get do |request|
          request.url path
        end

        json_parse
      end

      def get_companies_list(accountancy_practice_uuid)
        path = "#{base_path}/accountancypractices/#{accountancy_practice_uuid}/companies"

        @response = connection_bearer.get do |request|
          request.url path
        end

        json_parse
      end

      def get_periods_list(accountancy_practice_uuid, company_uuid)
        path = "#{base_path}/accountancypractices/#{accountancy_practice_uuid}/companies/#{company_uuid}/accounting/periods"

        @response = connection_bearer.get do |request|
          request.url path
        end

        json_parse
      end

      def get_ledgers_list(accountancy_practice_uuid, company_uuid, period_uuid)
        path = "#{base_path}/accountancypractices/#{accountancy_practice_uuid}/companies/#{company_uuid}/accounting/periods/#{period_uuid}/journals"

        @response = connection_bearer.get do |request|
          request.url path
        end

        json_parse
      end

      def get_entries_list(accountancy_practice_uuid, company_uuid, period_uuid)
        path = "#{base_path}/accountancypractices/#{accountancy_practice_uuid}/companies/#{company_uuid}/accounting/periods/#{period_uuid}/entries"

        @response = connection_bearer.get do |request|
          request.url path
        end

        json_parse
      end

      def get_trading_accounts_list(accountancy_practice_uuid, company_uuid, period_uuid)
        path = "#{base_path}/accountancypractices/#{accountancy_practice_uuid}/companies/#{company_uuid}/accounting/periods/#{period_uuid}/accounts/trading"

        @response = connection_bearer.get do |request|
          request.url path
        end

        json_parse
      end

      def send_pre_assignment(accountancy_practice_uuid, company_uuid, period_uuid, data)
        path = "#{base_path}/accountancypractices/#{accountancy_practice_uuid}/companies/#{company_uuid}/accounting/periods/#{period_uuid}/entries"

        body = data

        Rails.logger.debug("#{body.inspect}")


        connection = Faraday.new(@settings[:base_url]) do |faraday|
          faraday.request :multipart
          faraday.response :logger
          faraday.adapter Faraday.default_adapter
          faraday.headers['Authorization'] = "Bearer #{@token}"
        end

        @response = connection.post do |request|
          request.url path
          request.headers["Content-Type"] = "multipart/form-data"
          request.body = body
        end

        json_parse
      end

      private

      def access_token
        if cached_token = Rails.cache.fetch(:sage_gec_private_token)
          cached_token
        else
          connection = Faraday.new(@settings[:auth_base_url]) do |faraday|
            faraday.response :logger
            faraday.adapter Faraday.default_adapter
            faraday.headers['Accept'] = "*/*"
            faraday.headers['Content-Type'] = "application/x-www-form-urlencoded"
          end

          data = {
            grant_type: 'client_credentials',
            client_id: @settings[:client_id],
            client_secret: @settings[:client_secret],
            audience: @settings[:audience]
          }

          result = connection.post do |request|
            request.body = URI.encode_www_form(data)
            request.url "/oauth/token"
          end

        
          if result.status == 200
            token_data = JSON.parse(result.body)

            token = token_data["access_token"]
            expires_in = token_data["expires_in"] - 600

            Rails.cache.write(:sage_gec_private_token, token, expires_in: expires_in.seconds)

            token
          else
            raise 'Unable to authenticate to Sage API'
          end
        end
      end

      def connection_bearer
        @connection = Faraday.new(@settings[:base_url]) do |faraday|
          faraday.response :logger
          faraday.adapter Faraday.default_adapter
          faraday.headers['Authorization'] = "Bearer #{@token}"
        end
      end

      def base_path
        "/v1/applications/#{@settings[:application_id]}"
      end

      def json_parse
        if @response.status.in?([200, 201])
          { status: "success", body: JSON.parse(@response.body) }
        else
          { status: "error", body: JSON.parse(@response.body) }
        end
      end
    end
  end
end