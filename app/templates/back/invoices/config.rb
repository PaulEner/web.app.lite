module Admin
  module Invoices; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/invoices/controllers"]