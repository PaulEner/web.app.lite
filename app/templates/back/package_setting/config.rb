module Admin
  module PackageSetting; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/package_setting/controllers"]