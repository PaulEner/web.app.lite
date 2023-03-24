module Admin
  module Retrievers; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/retrievers/controllers"]