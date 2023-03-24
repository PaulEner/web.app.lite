module Admin
  module Subscriptions; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/subscriptions/controllers"]