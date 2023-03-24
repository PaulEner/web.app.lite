module Admin
  module Notifications; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/notifications/controllers"]