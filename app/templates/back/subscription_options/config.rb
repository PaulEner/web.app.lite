module Admin
  module SubscriptionOptions; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/subscription_options/controllers"]