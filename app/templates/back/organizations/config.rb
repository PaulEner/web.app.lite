module Admin
  module Organizations; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/organizations/controllers"]