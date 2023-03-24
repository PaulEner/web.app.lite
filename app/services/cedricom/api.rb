module Cedricom
  class Api
    CONFIG = YAML.load_file('config/cedricom.yml').freeze

    def initialize(organization)
      @organization = organization

      token = get_jwt

      @connection = Faraday.new(CONFIG['cedricom']['base_url']) do |faraday|
        faraday.options.timeout = 300
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers['Content-Type'] = "application/xml"
        faraday.headers['X-Auth-Token'] = token
      end
    end

    def get_reception_list(date = nil)
      path = "/sycomore/rest/comm/v1/abonnements/STR0834600/fr/*/receptions"

      path += "?dateTelechargement=#{date}" if date

      result = @connection.get do |request|
        request.url path
      end

      result.body
    end

    def get_reception(reception_id)
      path = "/sycomore/rest/comm/v1/abonnements/STR0834600/fr/*/receptions/#{reception_id}/fqr/*/fichier"

      result = @connection.get do |request|
        request.url path
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    def get_customer(customer_code)
      path = "/sycomore/releves/api/v1/abonnements/STR0834600/entites/#{@organization.cedricom_name}/dossiersclients/#{customer_code}"

      result = @connection.get do |request|
        request.url path
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    def create_customer(payload)
      path = "/sycomore/releves/api/v1/abonnements/STR0834600/entites/#{@organization.cedricom_name}/dossiersclients"

      @connection.headers['Content-Type'] = "application/json"

      result = @connection.post do |request|
        request.url path
        request.body = payload
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    def update_customer(customer_code, payload)
      path = "/sycomore/releves/api/v1/abonnements/STR0834600/entites/#{@organization.cedricom_name}/dossiersclients/#{customer_code}"

      @connection.headers['Content-Type'] = "application/json"

      result = @connection.patch do |request|
        request.url path
        request.body = payload
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    def fetch_mandate(customer_code, payload)
      path = "/sycomore/releves/api/v1/abonnements/STR0834600/entites/#{@organization.cedricom_name}/dossiersclients/#{customer_code}/mandats/pdfNonSigne"

      @connection.headers['Content-Type'] = "application/json"

      result = @connection.post do |request|
        request.url path
        request.body = payload
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    def update_mandate(customer_code, payload)
      path = "/sycomore/releves/api/v1/abonnements/STR0834600/entites/#{@organization.cedricom_name}/dossiersclients/#{customer_code}/mandats/pdfSigne"

      @connection.headers['Content-Type'] = "application/json"

      result = @connection.post do |request|
        request.url path
        request.body = payload
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    private

    def get_jwt
      @connection = Faraday.new(CONFIG['cedricom']['base_url']) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers['Accept'] = "*/*"
        faraday.headers['Content-Type'] = "application/json"
        faraday.headers['X-Auth-Username'] = @organization.cedricom_user
        faraday.headers['X-Auth-Password'] = @organization.cedricom_password

      end

      result = @connection.post do |request|
        request.url "/sycomore/api/authent"
      end

      token = JSON.parse(result.body)["token"]
    end
  end
end