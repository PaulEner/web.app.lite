module Admin
  module EmailedDocuments; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/emailed_documents/controllers"]