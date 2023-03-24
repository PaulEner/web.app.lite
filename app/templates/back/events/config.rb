module Admin
  module Events; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/events/controllers"]