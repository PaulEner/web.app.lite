module Admin
  module MobileReporting; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/mobile_reporting/controllers"]