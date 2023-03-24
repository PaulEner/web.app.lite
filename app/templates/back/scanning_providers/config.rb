module Admin
  module ScanningProviders; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/scanning_providers/controllers"]