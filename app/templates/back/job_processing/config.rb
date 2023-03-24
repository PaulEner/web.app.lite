module Admin
  module JobProcessing; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/job_processing/controllers"]