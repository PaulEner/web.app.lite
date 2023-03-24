module Admin
  module CounterErrorScriptMailer; end
end

Idocus::Application.config.autoload_paths += Dir["#{Rails.root}/templates/back/counter_error_script_mailer/controllers"]