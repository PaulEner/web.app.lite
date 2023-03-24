module AcdLib
  module Api
    class Client
      attr_accessor :request

      def initialize(username, password, url)
        @url      = url
        @username = username
        @password = password
        @token = access_token
      end

      def get_companies_list
        path = "#{base_path}/dossiers"

        @response = connection.get do |request|
          request.url path
        end

        json_parse
      end

      def select_company(code)
        path = "#{base_path}/sessions/dossier/#{code}"

        @response = connection.post do |request|
          request.url path
        end

        json_parse
      end

      def store_file(code, payload)
        company_path = "#{base_path}/sessions/dossier/#{code}"

        @company_response = connection.post do |request|
          request.url company_path
        end

        Rails.logger.debug(@company_response.body)

        path = "#{base_path}/ged/documents"

        connection = Faraday.new(@url) do |faraday|
          faraday.request :multipart
          faraday.response :logger
          faraday.adapter Faraday.default_adapter
          faraday.headers['UUID'] = @token
          faraday.headers['CNX'] = 'CNX'
        end

        @response = connection.post do |request|
          request.url path
          request.headers["Content-Type"] = "multipart/form-data"
          request.body = payload
        end

        Rails.logger.debug(@response.body)

        json_parse
      end

      def send_pre_assignment(payload)
        path = "#{base_path}/compta/ecriture"

        @response = connection.post do |request|
          request.url path
          request.body = payload.to_json
        end

        Rails.logger.debug(@response.body)

        json_parse
      end

      private

      def access_token
        connection = Faraday.new(@url) do |faraday|
          faraday.response :logger
          faraday.adapter Faraday.default_adapter
          faraday.headers['Accept'] = "application/json"
          faraday.headers['Content-Type'] = "application/json"
        end

        data = {
          CNX: 'CNX',
          Identifiant: @username,
          MotDePasse: @password
        }.to_json

        Rails.logger.debug(data.inspect)

        result = connection.post do |request|
          request.body = data
          request.url "#{base_path}/authentification"
        end

        Rails.logger.debug(result.body)
      
        if result.status == 200
          token_data = JSON.parse(result.body)

          token = token_data["UUID"]

          token
        else
          raise 'Unable to authenticate to ACD API'
        end
      end

      def connection
        @connection = Faraday.new(@url) do |faraday|
          faraday.response :logger
          faraday.adapter Faraday.default_adapter
          faraday.headers['UUID'] = @token
          faraday.headers['CNX'] = 'CNX'
        end
      end

      def base_path
        "/iSuiteExpert/api/v1"
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