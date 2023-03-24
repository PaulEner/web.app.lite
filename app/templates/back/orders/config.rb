module Admin
  module Orders; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/orders/controllers"]