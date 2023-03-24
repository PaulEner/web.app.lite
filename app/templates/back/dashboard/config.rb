module Admin
  module Dashboard; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/dashboard/controllers"]