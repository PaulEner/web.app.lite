config_file = File.join(Rails.root, 'config', 'sage_gec_private.yml')
raise 'MyUnisoft configuration file config/sage_gec_private.yml is missing.' unless File.exist?(config_file)

SageGecLib::Api::Util.config = YAML::load_file(config_file)[Rails.env]