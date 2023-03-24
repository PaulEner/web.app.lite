module Admin
  module NotificationSettings; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/notification_settings/controllers"]