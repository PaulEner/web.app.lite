# frozen_string_literal: true
class Suspended::MainController < FrontController
  prepend_view_path('app/templates/front/suspended/views')
  # GET /account/suspended
  def show; end
end