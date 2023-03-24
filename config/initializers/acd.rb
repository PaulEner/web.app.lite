config_file = File.join(Rails.root, 'config', 'acd.yml')
raise 'ACD configuration file config/acd.yml is missing.' unless File.exist?(config_file)

AcdLib::Api::Util.config = YAML::load_file(config_file)[Rails.env]