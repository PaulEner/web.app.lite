module AcdLib
  module Api
    class Util
      def self.configure
        yield config
      end

      def self.config
        @config ||= AcdLib::Api::GetConfiguration.new
      end

      def self.config=(new_config)
        config.base_url       = new_config['base_url']       if new_config['base_url']
      end
    end
  end
end