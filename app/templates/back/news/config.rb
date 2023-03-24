module Admin
  module News; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/news/controllers"]