module Admin
  module AccountSharings; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/account_sharings/controllers"]