module Admin
  module Pkill; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/pkill/controllers"]