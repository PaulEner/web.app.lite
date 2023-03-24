module Admin
  module ProcessReporting; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/process_reporting/controllers"]