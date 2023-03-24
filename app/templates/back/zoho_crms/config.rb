module Admin
  module ZohoCrms; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/zoho_crms/controllers"]