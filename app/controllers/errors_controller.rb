# frozen_string_literal: true

class ErrorsController < ApplicationController
  def routing
    raise ActionController::RoutingError, 'Not Found'
	rescue
    render file: "#{Rails.root}/public/404", status: :not_found
  end
end
