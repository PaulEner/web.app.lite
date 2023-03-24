module Admin
  module Supports; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/supports/controllers"]