module SageGecLib
  module Api
    class Util
      def self.configure
        yield config
      end

      def self.config
        @config ||= SageGecLib::Api::GetConfiguration.new
      end

      def self.config=(new_config)
        config.base_url       = new_config['base_url']       if new_config['base_url']
        config.auth_base_url  = new_config['auth_base_url']  if new_config['auth_base_url']
        config.audience       = new_config['audience']       if new_config['audience']
        config.client_id      = new_config['client_id']      if new_config['client_id']
        config.client_secret  = new_config['client_secret']  if new_config['client_secret']
        config.application_id = new_config['application_id'] if new_config['application_id']
      end
    end
  end
end