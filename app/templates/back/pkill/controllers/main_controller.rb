# frozen_string_literal: true
class Admin::Pkill::MainController < BackController
  prepend_view_path('app/templates/back/pkill/views')

  # GET /admin/pkill
  def index; end
end