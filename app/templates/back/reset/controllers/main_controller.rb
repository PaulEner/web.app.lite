# frozen_string_literal: true
class Admin::Reset::MainController < BackController
  prepend_view_path('app/templates/back/reset/views')

  # GET /admin/reset
  def index; end

  def lad
  	@result = PonctualScripts::ResetAdminDashboard.new().execute("lad")

    render partial: 'lad'
  end
end