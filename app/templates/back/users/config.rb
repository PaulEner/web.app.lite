module Admin
  module Users; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/users/controllers"]