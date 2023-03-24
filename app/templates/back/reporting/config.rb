module Admin
  module Reporting; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/reporting/controllers"]