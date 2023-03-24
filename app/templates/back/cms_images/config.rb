module Admin
  module CmsImages; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/cms_images/controllers"]