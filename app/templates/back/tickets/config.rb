module Admin
  module Tickets; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/tickets/controllers"]